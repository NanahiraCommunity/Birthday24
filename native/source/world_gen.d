module world_gen;

import godot;

import godot.api.script;
import godot.fileaccess;
import godot.engine;
import godot.node;
import godot.gridmap;

import std.conv;
import std.datetime.stopwatch;

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
	riverTile
}

class WorldGen : GodotScript!Node
{
	struct BlockInfo
	{
		int id;
		int yOffset;
	}

	@Property GridMap worldmap;

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
		auto pos = Vector3i(x - 10, y + blocks[block].yOffset, z - 25);
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

	void postprocess()
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

	@Method
	void _ready()
	{
		if (Engine.isEditorHint)
			return;

		this.callDeferred("build");
	}

	@Method
	void build()
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

		sw.stop();
		print(gs!"Built world map in ", String(sw.peek.to!string));

	}
}
