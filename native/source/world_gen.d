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
	@("ground_grass2", yOffset = 1)
	fullGrass,
	@("cliff_half_rock2")
	grassCliff,
	@("cliff_halfCorner_rock2")
	grassCliffCorner,
	@("cliff_halfCornerInner_rock2")
	grassCliffCornerInner,
	@("cliff_blockSlopeHalfWalls_rock2")
	grassSlope,
	@("ground_riverTile2", yOffset = 1)
	riverTile,
	@("grass2")
	grass1,
	@("grass_large2")
	grass2,
	@("grass_leafs2")
	grass3,
	@("grass_leafsLarge2")
	grass4,
	@("plant_bush2")
	bush1,
	@("plant_bushDetailed2")
	bush2,
	@("plant_bushLarge2")
	bush3,
	@("plant_bushLargeTriangle2")
	bush4,
	@("plant_bushTriangle2")
	bush5,
	@("plant_bushSmall2")
	bush6,
	@("plant_flatShort2")
	bush7,
	@("plant_flatTall2")
	bush8,
	@("flower_purpleA2")
	flower1,
	@("flower_purpleB2")
	flower2,
	@("flower_purpleC2")
	flower3,
	@("flower_redA2")
	flower4,
	@("flower_redB2")
	flower5,
	@("flower_redC2")
	flower6,
	@("flower_yellowA2")
	flower7,
	@("flower_yellowB2")
	flower8,
	@("flower_yellowC2")
	flower9,
	@("flowersLow2")
	flower10,
	@("mushroom_red2")
	mushrooms1,
	@("mushroom_redGroup2")
	mushrooms2,
	@("mushroom_redTall2")
	mushrooms3,
	@("mushroom_tan2")
	mushrooms4,
	@("mushroom_tanGroup2")
	mushrooms5,
	@("mushroom_tanTall2")
	mushrooms6,
	@("stone_tallA2")
	rocks1,
	@("stone_tallB2")
	rocks2,
	@("stone_tallC2")
	rocks3,
	@("stone_tallD2")
	rocks4,
	@("stone_tallE2")
	rocks5,
	@("stone_tallF2")
	rocks6,
	@("stone_tallG2")
	rocks7,
	@("stone_tallH2")
	rocks8,
	@("stone_tallI2")
	rocks9,
	@("stone_tallJ2")
	rocks10,
	@("stump_old2")
	stump1,
	@("stump_oldTall2")
	stump2,
	@("stump_round2")
	stump3,
	@("stump_roundDetailed2")
	stump4,
	@("shovel-dirt2")
	items1,
	@("tree_cone2")
	tree1,
	@("tree_cone_dark2")
	tree2,
	@("tree_default2")
	tree3,
	@("tree_default_dark2")
	tree4,
	@("tree_detailed2")
	tree5,
	@("tree_detailed_dark2")
	tree6,
	@("tree_fat2")
	tree7,
	@("tree_fat_darkh2")
	tree8,
	@("tree_oak2")
	tree9,
	@("tree_oak_dark2")
	tree10,
	@("tree_pineDefaultA2")
	tree11,
	@("tree_pineDefaultB2")
	tree12,
	@("tree_pineGroundA2")
	tree13,
	@("tree_pineGroundB2")
	tree14,
	@("tree_pineRoundA2")
	tree15,
	@("tree_pineRoundB2")
	tree16,
	@("tree_pineRoundC2")
	tree17,
	@("tree_pineRoundD2")
	tree18,
	@("tree_pineRoundE2")
	tree19,
	@("tree_pineRoundF2")
	tree20,
	@("tree_pineSmallA2")
	tree21,
	@("tree_pineSmallB2")
	tree22,
	@("tree_pineSmallC2")
	tree23,
	@("tree_pineSmallD2")
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
