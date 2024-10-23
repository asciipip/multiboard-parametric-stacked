/* [Tile Definitions] */

// Array of tile shapes.
//
// Each array element should be:
//   [count, x_cells, y_cells, shape]
//
// Valid shapes are:
//  * "core"
//  * "side" (for a top or bottom side with the teeth on the right)
//  * "rotated side" (for a left or right side with the teeth on the top)
//  * "corner"
//
// Warning: This model will create whatever you tell it to.  It's up to
// you to make sure your tiles are all supported.

tiles = [
  [4, 4, 4, "core"],
  [3, 4, 4, "side"],
  [2, 4, 3, "rotated side"],
  [1, 3, 3, "corner"]
];

/* [Print Settings] */

// Your slicer's layer thickness in millimeters; 0.2 mm is strongly recommended
layer_thickness = 0.2;


// No user-servicable parts below this line.

use <multiboard_base.scad>

// `use` doesn't pull in variables, so we need to redefine the ones we
// need.
cell_size = 25+0;
height = 6.4+0;
stack_height = height + abs(-height % layer_thickness) + layer_thickness;

module tile_group(offset, tile_params) {
  count = tile_params[0];
  x_cells = tile_params[1];
  y_cells = tile_params[2];
  shape = tile_params[3];
  assert(x_cells >= 2, "X dimension must be at least 2");
  assert(y_cells >= 2, "Y dimension must be at least 2");
  translate([0, 0, offset * stack_height])
    for (level = [0:1:count-1])
      translate([0, 0, level * stack_height])
        generic_tile(x_cells, y_cells, shape);
}

module generic_tile(x_cells, y_cells, shape) {
       if (shape == "core")   {multiboard_core(x_cells, y_cells);}
  else if (shape == "side")   {multiboard_side(x_cells, y_cells);}
  else if (shape == "corner") {multiboard_corner(x_cells, y_cells);}
  else if (shape == "rotated side") {
    translate([x_cells * cell_size, 0, 0])
      rotate(90)
      multiboard_side(y_cells, x_cells);
  } else {
    assert(false, "Unknown tile shape");
  }
}


offsets = [ for (o = 0, i = 0; i < len(tiles); o = o + tiles[i][0], i = i + 1) o ];

for ( i = [0:1:len(tiles)-1] )
  tile_group(offsets[i], tiles[i]);
