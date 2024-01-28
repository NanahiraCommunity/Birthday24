module lib;

import godot;
import heightmap;
import world_gen;

// register classes, initialize and terminate D runtime, only one per plugin
mixin GodotNativeLibrary!(
	// this is a name prefix of the plugin to be acessible inside godot
	// it must match the prefix in .gdextension file:
	//     entry_symbol = "birthday24_gdextension_entry"
	"birthday24", // here goes the list of classes you would like to expose in godot
	WorldGen,
	ImageLoader,
);
