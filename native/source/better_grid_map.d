module better_grid_map;

version(none):

import godot;
import godot.arraymesh;

class BetterGridMap : GodotScript!GridMap
{
	ArrayMesh mesh;
	bool dirty;

	@Method _ready()
	{
		if (Engine.isEditorHint)
			return;

		dirty = true;
	}

	@Method _process()
	{
		if (!dirty)
			return;

		remesh();
		dirty = false;
	}

	@Method remesh()
	{
	}
}
