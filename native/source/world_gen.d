module world_gen;

import godot;

import godot.api.script;
import godot.fileaccess;
import godot.engine;
import godot.node;
import godot.gridmap;

import std.conv;
import std.datetime.stopwatch;
import std.random;
import std.typecons;

//dfmt off
// UDA
struct YOffset { int y; }
YOffset yOffset(int y) { return YOffset(y); }
//dfmt on

enum Blocks : uint
{
	air,
	@("ground_grass", yOffset = 1)
	fullGrass,
	@("cliff_half_rock")
	grassCliff,
	@("cliff_halfCorner_rock")
	grassCliffCorner,
	@("cliff_halfCornerInner_rock")
	grassCliffCornerInner,
	@("cliff_blockSlopeHalfWalls_rock")
	grassSlope,
	@("ground_riverTile", yOffset = 1)
	riverTile,
	@("grass")
	grass1,
	@("grass_large")
	grass2,
	@("grass_leafs")
	grass3,
	@("grass_leafsLarge")
	grass4,
	@("plant_bush")
	bush1,
	@("plant_bushDetailed")
	bush2,
	@("plant_bushLarge")
	bush3,
	@("plant_bushLargeTriangle")
	bush4,
	@("plant_bushTriangle")
	bush5,
	@("plant_bushSmall")
	bush6,
	@("plant_flatShort")
	bush7,
	@("plant_flatTall")
	bush8,
	@("flower_purpleA")
	flower1,
	@("flower_purpleB")
	flower2,
	@("flower_purpleC")
	flower3,
	@("flower_redA")
	flower4,
	@("flower_redB")
	flower5,
	@("flower_redC")
	flower6,
	@("flower_yellowA")
	flower7,
	@("flower_yellowB")
	flower8,
	@("flower_yellowC")
	flower9,
	@("flowersLow")
	flower10,
	@("mushroom_red")
	mushrooms1,
	@("mushroom_redGroup")
	mushrooms2,
	@("mushroom_redTall")
	mushrooms3,
	@("mushroom_tan")
	mushrooms4,
	@("mushroom_tanGroup")
	mushrooms5,
	@("mushroom_tanTall")
	mushrooms6,
	@("stone_tallA")
	rocks1,
	@("stone_tallB")
	rocks2,
	@("stone_tallC")
	rocks3,
	@("stone_tallD")
	rocks4,
	@("stone_tallE")
	rocks5,
	@("stone_tallF")
	rocks6,
	@("stone_tallG")
	rocks7,
	@("stone_tallH")
	rocks8,
	@("stone_tallI")
	rocks9,
	@("stone_tallJ")
	rocks10,
	@("stump_old")
	stump1,
	@("stump_oldTall")
	stump2,
	@("stump_round")
	stump3,
	@("stump_roundDetailed")
	stump4,
	@("shovel-dirt")
	items1,
	@("tree_cone")
	tree1,
	@("tree_cone_dark")
	tree2,
	@("tree_default")
	tree3,
	@("tree_default_dark")
	tree4,
	@("tree_detailed")
	tree5,
	@("tree_detailed_dark")
	tree6,
	@("tree_fat")
	tree7,
	@("tree_fat_darkh")
	tree8,
	@("tree_oak")
	tree9,
	@("tree_oak_dark")
	tree10,
	@("tree_pineDefaultA")
	tree11,
	@("tree_pineDefaultB")
	tree12,
	@("tree_pineGroundA")
	tree13,
	@("tree_pineGroundB")
	tree14,
	@("tree_pineRoundA")
	tree15,
	@("tree_pineRoundB")
	tree16,
	@("tree_pineRoundC")
	tree17,
	@("tree_pineRoundD")
	tree18,
	@("tree_pineRoundE")
	tree19,
	@("tree_pineRoundF")
	tree20,
	@("tree_pineSmallA")
	tree21,
	@("tree_pineSmallB")
	tree22,
	@("tree_pineSmallC")
	tree23,
	@("tree_pineSmallD")
	tree24,
}

private Blocks[] blockList(string prefix)()
{
	import std.algorithm;
	import std.ascii;

	Blocks[] ret;
	foreach (b; __traits(allMembers, Blocks))
		static if (b.startsWith(prefix) && b[prefix.length .. $].all!isDigit)
			ret ~= __traits(getMember, Blocks, b);
	return ret;
}

static struct BlockLists
{
	static struct UniformDistribution
	{
		immutable(Blocks[]) blocks;
		double probability;
	}

	static struct SimplexDistribution
	{
		immutable(Blocks[]) blocks;
		Vector3 scale;
		double threshold;
		double probability;
	}

	static immutable Blocks[] grasses = blockList!"grass";
	static immutable Blocks[] bushes = blockList!"bush";
	static immutable Blocks[] flowers = blockList!"flower";
	static immutable Blocks[] mushrooms = blockList!"mushrooms";
	static immutable Blocks[] rocks = blockList!"rocks";
	static immutable Blocks[] stumps = blockList!"stump";
	static immutable Blocks[] items = blockList!"items";
	static immutable Blocks[] trees = blockList!"tree";

	enum distributions = AliasSeq!(
		UniformDistribution(grasses, 0.5),
		SimplexDistribution(flowers, Vector3(7, 1, 7), 0.3, 0.7),
		SimplexDistribution(trees, Vector3(5, 1, 5), 0.2, 0.2),
	);
}

class WorldGen : GodotScript!Node
{
	struct BlockInfo
	{
		int id;
		int yOffset;
	}

	enum globalOffset = Vector3i(-10, 0, -25);

	@Property GridMap worldmap;
	@Property GridMap interactables;

	GridMap[4] overlaps;

	enum width = 32;
	enum height = 32;
	enum layers = 6;
	Blocks[width * height * layers] vmap;

	BlockInfo[Blocks.max + 1] blocks;

	static size_t index(int x, int y, int z) {
		assert(x >= 0 && x < width);
		assert(z >= 0 && z < height);
		assert(y >= 0 && y < layers);

		return y * (width * height) + z * width + x;
	}

	static int rotZ(int r)
	{
		switch (r % 4)
		{
		case 0: return 0;
		case 1: return 22;
		case 2: return 10;
		case 3: return 16;
		default: assert(false);
		}
	}

	void place(int x, int y, int z, Blocks block, int rot)
	{
		auto pos = Vector3i(x, y + blocks[block].yOffset, z) + globalOffset;
		foreach (ref map; overlaps) {
			if (block == Blocks.air) {
				map.setCellItem(pos, -1, 0);
			} else {
				auto existing = map.getCellItem(pos);
				auto existingRot = map.getCellItemOrientation(pos);
				if (existing == blocks[block].id && existingRot == rot)
					break; // already set
				else if (existing == -1)
				{
					map.setCellItem(pos, blocks[block].id, rot);
					break;
				}
			}
		}

		vmap[index(x, y, z)] = block;
	}

	@Method postprocess()
	{
		foreach (y; 0 .. layers)
			foreach (z; 1 .. height - 1)
				foreach (x; 1 .. width - 1)
				{
					if (vmap[index(x, y, z)] != Blocks.air)
						continue;

					bool cliffLeft = vmap[index(x - 1, y, z)] == Blocks.fullGrass;
					bool cliffUp = vmap[index(x, y, z - 1)] == Blocks.fullGrass;
					bool cliffRight = vmap[index(x + 1, y, z)] == Blocks.fullGrass;
					bool cliffDown = vmap[index(x, y, z + 1)] == Blocks.fullGrass;

					bool diagonalLeftUp = vmap[index(x - 1, y, z - 1)] == Blocks.fullGrass && !cliffLeft && !cliffUp;
					bool diagonalUpRight = vmap[index(x + 1, y, z - 1)] == Blocks.fullGrass && !cliffRight && !cliffUp;
					bool diagonalRightDown = vmap[index(x + 1, y, z + 1)] == Blocks.fullGrass && !cliffRight && !cliffDown;
					bool diagonalDownLeft = vmap[index(x - 1, y, z + 1)] == Blocks.fullGrass && !cliffLeft && !cliffDown;

					switch (cliffLeft + cliffUp + cliffRight + cliffDown)
					{
						case 4:
							place(x, y, z, Blocks.riverTile, 0);
							break;
						case 3:
							// U
							int rot = !cliffDown ? 1
									: !cliffLeft ? 2
									: !cliffUp ? 3
									: !cliffRight ? 0
									: assert(false);

							place(x, y, z, Blocks.grassCliffCornerInner, rotZ(rot));
							place(x, y, z, Blocks.grassCliff, rotZ(rot + 2));
							break;
						case 2:
							if (cliffLeft == cliffRight || cliffUp == cliffDown) {
								// relies on overlaps
								// || or =
								int rot = (cliffLeft && cliffRight) ? 1 : 0;
								place(x, y, z, Blocks.grassCliff, rotZ(rot));
								place(x, y, z, Blocks.grassCliff, rotZ(rot + 2));
							} else {
								// L corner
								int rot = (cliffDown && cliffLeft) ? 0
										: (cliffLeft && cliffUp) ? 1
										: (cliffUp && cliffRight) ? 2
										: (cliffRight && cliffDown) ? 3
										: assert(false);

								place(x, y, z, Blocks.grassCliffCornerInner, rotZ(rot));
							}
							break;
						case 1:
							// single cliff
							int rot = cliffDown ? 0
									: cliffLeft ? 1
									: cliffUp ? 2
									: cliffRight ? 3
									: assert(false);

							place(x, y, z, Blocks.grassCliff, rotZ(rot));
							break;
						default:
							break;
					}

					// corner checks, relies on overlaps
					foreach (int rot, isDiag; [diagonalDownLeft, diagonalLeftUp, diagonalUpRight, diagonalRightDown])
						if (isDiag)
							place(x, y, z, Blocks.grassCliffCorner, rotZ(rot));
				}
	}

	@Method addVegetation(uint seed)
	{
		import fast_noise;

		Random rng;
		rng.seed(seed);

		FNLState simplex = fnlCreateState(rng.uniform!uint);
		simplex.noise_type = FNLNoiseType.FNL_NOISE_OPENSIMPLEX2;

		foreach (y; 0 .. layers - 1)
		foreach (z; 1 .. height - 1)
		foreach (x; 1 .. width - 1)
		{
			if (vmap[index(x, y, z)] != Blocks.fullGrass || vmap[index(x, y + 1, z)] != Blocks.air)
				continue;

			auto pos = Vector3i(x, y + 1, z) + globalOffset;
			static foreach (distribution; BlockLists.distributions)
			{{
				static if (is(typeof(distribution) == BlockLists.UniformDistribution))
				{
					if (rng.uniform01!double < distribution.probability)
					{
						interactables.setCellItem(pos,
							blocks[distribution.blocks[uniform(0, $, rng)]].id,
							rotZ(uniform(0, 4, rng)));
					}
				}
				else static if (is(typeof(distribution) == BlockLists.SimplexDistribution))
				{
					auto noise = fnlGetNoise3D(&simplex, x * distribution.scale.x, y * distribution.scale.y, z * distribution.scale.z);
					print(String("noise: " ~ noise.to!string));
					if (noise >= distribution.threshold && rng.uniform01!double < distribution.probability)
					{
						interactables.setCellItem(pos,
							blocks[distribution.blocks[uniform(0, $, rng)]].id,
							rotZ(uniform(0, 4, rng)));
					}
				}
			}}
		}
	}

	@Method _ready()
	{
		if (Engine.isEditorHint)
			return;

		this.callDeferred("build");
	}

	@Method build()
	{
		import gamut;

		StopWatch sw;
		sw.start();

		overlaps[0] = worldmap;
		foreach (i; 1 .. overlaps.length)
		{
			overlaps[i] = worldmap.duplicate().as!GridMap;
			overlaps[i - 1].addSibling(overlaps[i]);
		}

		blocks[0].id = -1;
		static foreach (i, member; __traits(allMembers, Blocks))
		{{
			static if (i != 0)
			{
				enum UDAs = __traits(getAttributes, __traits(getMember, Blocks, member));
				enum name = UDAs[0];
				static assert(is(typeof(name) == string));
				auto info = BlockInfo(worldmap.meshLibrary.findItemByName(gs!name));
				static foreach (UDA; UDAs[1 .. $])
				{
					static if (is(typeof(UDA) == YOffset))
						info.yOffset = UDA.y;
					else
						static assert(false, "unsupported UDA ", UDA.stringof);
				}
				blocks[i] = info;
			}
		}}

		auto testmap = cast(ubyte[]) import("test_map.png");
		print(gs!"building!!");

		Image img;
		img.loadFromMemory(testmap, LOAD_GREYSCALE | LOAD_8BIT | LOAD_NO_ALPHA);
		if (!img.isValid)
			throw new Exception(img.errorMessage().idup);

		foreach (z; 0 .. img.height)
		{
			auto line = cast(ubyte[]) img.scanline(z);
			foreach (x; 0 .. img.width)
			{
				Blocks b;
				int y;
				switch (line[x])
				{
				case 19:
					b = Blocks.fullGrass;
					y = 2;
					break;
				case 39:
					b = Blocks.fullGrass;
					y = 1;
					break;
				case 83:
					b = Blocks.fullGrass;
					break;
				case 255:
					continue;
				default:
					assert(false, "unknown color " ~ line[x].to!string);
				}

				place(x, y, z, b, 0);
			}
		}

		postprocess();
		addVegetation(unpredictableSeed);

		sw.stop();
		print(gs!"Built world map in ", String(sw.peek.to!string));

	}
}
