import godot;

// import godot.api.script; // for GodotScript!
// import godot.api.register; // for GodotNativeLibrary
// import godot.string; // for gs!

import godot.api.script;
import godot.fileaccess;
import godot.node;
import std.conv;
import std.datetime.stopwatch;
import std.exception;
import std.math;

static float lerp(float a, float b, float mix)
in(mix >= 0.0f && mix <= 1.0f)
{
	return a * (1.0f - mix) + b * mix;
}

// minimal class example with _ready method that will be invoked on creation
class ImageLoader : GodotScript!Node
{
	@Property String path;
	@Property int width;
	@Property int height;
	@Property float scale;
	@Property PackedFloat32Array data;

	// this method is a special godot entry point when object is added to the scene
	@Method
	void _ready()
	{
		import gamut;

		StopWatch sw;
		sw.start();

		auto fobj = (() @trusted => FileAccess.getFileAsBytes(path))();
		const(ubyte[]) f = fobj.data;
		import std.stdio;
		import std.digest.sha : sha512Of;
		import std.digest : toHexString;
		print("size: ", f.length);
		print("sha512: ", String(toHexString(sha512Of(f))));

		Image img;
		img.loadFromMemory(f, LOAD_FP32 | LOAD_GREYSCALE | LOAD_NO_ALPHA | LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT);
		if (!img.isValid)
			throw new Exception(img.errorMessage().idup);

		this.data.resize(img.width * img.height);
		this.width = img.width;
		this.height = img.height;
		auto data = this.data.data;
		assert(data.length == width * height);
		assert(img.allPixelsAtOnce.length == width * height * 4);
		data[] = cast(float[]) cast(void[]) img.allPixelsAtOnce;
		data[] *= scale;

		sw.stop();
		print(gs!"Processed heightmap data in ", String(sw.peek.to!string));

		// this.data.resize(width * height);
		// const w = img.width;
		// const h = img.height;
		// enforce(width >= w, "only upscaling supported");
		// enforce(height >= h, "only upscaling supported");

		// float get_pixel(float[] scan0, float[] scan1, double dx, double xfract, double yfract)
		// {
		// 	enum epsilon = 0.001;
		// 	int x = cast(int) trunc(dx);
		// 	if (xfract < epsilon && yfract < epsilon)
		// 		return scan0[x];
		// 	else if (xfract < epsilon)
		// 		return lerp(
		// 			scan0[x],
		// 			scan1[x],
		// 			yfract
		// 		);
		// 	else if (yfract < epsilon)
		// 		return lerp(
		// 			scan0[x],
		// 			scan0[x + 1],
		// 			xfract
		// 		);
		// 	else
		// 		return lerp(
		// 			lerp(
		// 				scan0[x],
		// 				scan1[x],
		// 				yfract
		// 			),
		// 			lerp(
		// 				scan0[x + 1],
		// 				scan1[x + 1],
		// 				yfract
		// 			),
		// 			xfract
		// 		);
		// }

		// foreach (y; 0 .. height)
		// {
		// 	float[] scan = (() @trusted => cast(float[]) img.scanline(y))();
		// 	float[] scan2 = (() @trusted => cast(float[]) img.scanline(y == height - 1 ? y : y + 1))();
		// 	double dy = cast(double) y * h / height;
		// 	double yfract = dy - trunc(dy);
		// 	foreach (x; 0 .. width)
		// 	{
		// 		double dx = cast(double) x * w / width;
		// 		double xfract = dy - trunc(dy);
		// 		data[y * width + x] = get_pixel(scan, scan2, dx, xfract, yfract) * scale;
		// 	}
		// }

		// auto dbg = Image(width, height, PixelType.lf32, LAYOUT_GAPLESS | LAYOUT_VERT_STRAIGHT);
		// dbg.allPixelsAtOnce[] = cast(ubyte[]) cast(void[]) data;
		// if (!dbg.convertTo8Bit())
		// 	throw new Exception(dbg.errorMessage().idup);
		// if (!dbg.saveToFile("/tmp/decoded.png"))
		// 	throw new Exception(dbg.errorMessage().idup);
	}
}

// register classes, initialize and terminate D runtime, only one per plugin
mixin GodotNativeLibrary!(
	// this is a name prefix of the plugin to be acessible inside godot
	// it must match the prefix in .gdextension file:
	//     entry_symbol = "birthday24_gdextension_entry"
	"birthday24", // here goes the list of classes you would like to expose in godot
	ImageLoader,
);
