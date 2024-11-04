// Model to generate stacks of Multiboard tiles for assembly into large
// boards.

/* [Tile Size] */

// Number of cells along the X axis
x_cells = 4;
// Number of cells along the y axis
y_cells = 4;

/* [Tile Counts] */

// Number of core tiles (pegboard holes on the right and top)
core_tiles = 4;
// Number of side tiles (pegboard holes only on the right)
side_tiles = 4;
// Number of corner tiles (no pegboard holes)
corner_tiles = 1;

/* [Print Settings] */

// Your slicer's layer thickness in millimeters; 0.2 mm is strongly recommended
layer_thickness = 0.2;

/* [Per-Shape Tuning] */

// X size of the side tiles; "0" means to use the main x_cells setting
side_x_cells = 0;
// Y size of the side tiles; "0" means to use the main y_cells setting
side_y_cells = 0;
// X size of the corner tiles; "0" means to use the main x_cells setting
corner_x_cells = 0;
// Y size of the corner tiles; "0" means to use the main y_cells setting
corner_y_cells = 0;


// No user-servicable parts below this line.

// Actual tile dimensions
real_side_x_cells = side_x_cells > 0 ? side_x_cells : x_cells;
real_side_y_cells = side_y_cells > 0 ? side_y_cells : y_cells;
real_corner_x_cells = corner_x_cells > 0 ? corner_x_cells : x_cells;
real_corner_y_cells = corner_y_cells > 0 ? corner_y_cells : y_cells;

// Dimension validation
assert(layer_thickness > 0, "Layer thickness must be larger than zero");
assert(min(core_tiles, side_tiles, corner_tiles) >= 0, "Can't make negative numbers of tiles");
assert(min(x_cells, y_cells, real_side_x_cells, real_side_y_cells, real_corner_x_cells, real_corner_y_cells) >= 1,
       "Not enough cells to actually make a tile")
assert(real_side_x_cells <= x_cells, "Side tile X value larger than core tile X value");
assert(real_side_y_cells <= y_cells, "Side tile Y value larger than core tile Y value");
assert(real_corner_x_cells <= real_side_x_cells, "Corner tile X value larger than side tile X value");
assert(real_corner_y_cells <= real_side_y_cells, "Corner tile Y value larger than side tile Y value");


// All measurements are based on the Multiboard tile component remixing
// files at https://than.gs/m/994681, uploaded 2024-01-19.

// Main dimensions
cell_size = 25+0;
height = 6.4+0;

// Single tile outer dimensions
side_l = cell_size/(1+2*cos(45));
size_l_offset = (cell_size - side_l)/2;

// Single tile hole dimensions

// The "thick" part is the middle of the hole, where the sides are thicker
// than the top and bottom.
multihole_thick_height = 2.4+0;
multihole_thick_size = 21.4+0;
multihole_thin_size = 23.4+0;

// The multihole is an octagon.  We'll get OpenSCAD to generate that by
// telling it to make a circle with a radius equal to the outer corners of
// the hole, but with only eight sides.
multihole_thick_side_l = multihole_thick_size/(1+2*cos(45));
multihole_thick_bound_circle_d = multihole_thick_side_l/sin(22.5);
multihole_thin_side_l = multihole_thin_size/(1+2*cos(45));
multihole_thin_bound_circle_d = multihole_thin_side_l/sin(22.5);
multihole_base_fn = 8+0;

// The threads are formed using a spiral with a trapezoidal cross-section.
// `d1` is the outer diameter of the spiral and `d2` is the inner
// diameter.  `h1` is the height of the outer wall and `h2` is the height
// of the inner wall.  `pitch` has its usual meaning: the distance from
// one thread peak (or valley) to the next immediately above or below it.
multihole_thread_d1 = 22.6+0;
multihole_thread_d2 = multihole_thick_size+0;
multihole_thread_h1 = 0.5+0;  // Height of outer thread
multihole_thread_h2 = 1.583+0;  // Height of thread at inner cylinder
multihole_thread_pitch = 2.5+0;
multihole_thread_fn = 32+0;

peg_hole_thick_height = 2.9+0;
peg_hole_thick_size = 6+0;
peg_hole_thin_size = 7.5+0;

peg_hole_thread_pitch = 3+0;
peg_hole_thread_d1 = 7+0;
peg_hole_thread_d2 = peg_hole_thick_size+0;
peg_hole_thread_h1 = 0.77+0;
peg_hole_thread_h2 = peg_hole_thread_pitch-0.5;
peg_hole_thread_fn = 32+0;

// Distance between stacked layers
layer_separation = abs(-height % layer_thickness) + layer_thickness;
stack_height = height + layer_separation;


// Here's the stack

multiboard_tile_stack(core_tiles, x_cells, y_cells, right_peg_holes=true, top_peg_holes=true);

translate([0, 0, stack_height * core_tiles])
  multiboard_tile_stack(side_tiles, real_side_x_cells, real_side_y_cells, right_peg_holes=true, top_peg_holes=false);

translate([0, 0, stack_height * (core_tiles + side_tiles)])
  multiboard_tile_stack(corner_tiles, real_corner_x_cells, real_corner_y_cells, right_peg_holes=false, top_peg_holes=false);


// Now, all the modules the stack uses

module multiboard_tile_stack(tile_count, x_cells, y_cells, right_peg_holes, top_peg_holes) {
  if (tile_count > 0)
    for (level = [0:tile_count-1])
      translate([0, 0, stack_height * level])
        multiboard_tile(x_cells, y_cells, right_peg_holes, top_peg_holes);
}


module multiboard_tile(x_cells, y_cells, right_peg_holes, top_peg_holes) {
  for (i=[0:x_cells-1])
    for (j=[0:y_cells-1])
      let (in_right_column = i == x_cells-1,
           in_top_row = j == y_cells-1,
           with_peg_hole =
             (!in_right_column && !in_top_row) ||
             ( in_right_column && !in_top_row && right_peg_holes) ||
             (!in_right_column &&  in_top_row && top_peg_holes) ||
             ( in_right_column &&  in_top_row && right_peg_holes && top_peg_holes))
        translate([i*cell_size, j*cell_size, 0])
          multiboard_cell(with_peg_hole=with_peg_hole);
}


module multiboard_cell(with_peg_hole) {
  difference() {
    multiboard_cell_base(with_peg_hole);
    translate([cell_size/2, cell_size/2, 0])
      multihole();
    if (with_peg_hole)
      translate([cell_size, cell_size, 0])
        peg_hole();
  }
}


module multiboard_cell_base(with_peg_hole) {
  base_points = [
    [cell_size - size_l_offset, cell_size],
    [size_l_offset,             cell_size],
    [0,                         cell_size - size_l_offset],
    [0,                         size_l_offset],
    [size_l_offset,             0],
    [cell_size - size_l_offset, 0],
    [cell_size,                 size_l_offset],
    [cell_size,                 cell_size - size_l_offset],
  ];
  points = with_peg_hole
    ? [
       each base_points,
       [cell_size + size_l_offset, cell_size],
       [cell_size,                 cell_size + size_l_offset],
      ]
    : base_points;
  linear_extrude(height)
    polygon(points);
}


module multihole() {
  multihole_base();
  // The rotation here isn't strictly necessary, but it makes the threads
  // line up with the Multiboard STEP files, which, in turn, makes
  // debugging easier.
  rotate(-170, [0, 0, 1])
    multihole_threads();
}


module multihole_base() {
  outer_offset = multihole_thin_bound_circle_d / 2;
  inner_offset = multihole_thick_bound_circle_d / 2;

  // Rotation needed to align the hole sides with the cell's outer sides.
  rotate(22.5, [0, 0, 1])
    rotate_extrude($fn=multihole_base_fn)
    polygon([
      [0,            -layer_separation],
      [outer_offset, -layer_separation],
      [outer_offset, 0],
      [inner_offset, (height - multihole_thick_height)/2],
      [inner_offset, (height + multihole_thick_height)/2],
      [outer_offset, height],
      [outer_offset, stack_height],
      [0,            stack_height],
    ]);
}


module multihole_threads() {
  translate([0, 0, -multihole_thread_h2/2])
    trapz_thread(multihole_thread_d1, multihole_thread_d2,
                 multihole_thread_h1, multihole_thread_h2,
                 thread_len=height+multihole_thread_h2,
                 pitch=multihole_thread_pitch,
                 $fn=multihole_thread_fn);
}


module peg_hole() {
  // The rotation here isn't strictly necessary, but it makes the threads
  // line up with the Multiboard STEP files, which, in turn, makes
  // debugging easier.
  rotate(-129, [0, 0, 1]) {
    peg_hole_base();
    peg_hole_threads();
  }
}


module peg_hole_base() {
  outer_offset = peg_hole_thin_size / 2;
  inner_offset = peg_hole_thick_size / 2;

  rotate_extrude($fn=peg_hole_thread_fn)
    polygon([
      [0,            -layer_separation],
      [outer_offset, -layer_separation],
      [outer_offset, 0],
      [inner_offset, (height - peg_hole_thick_height)/2],
      [inner_offset, (height + peg_hole_thick_height)/2],
      [outer_offset, height],
      [outer_offset, stack_height],
      [0,            stack_height],
    ]);
}


module peg_hole_threads() {
  intersection() {
    translate([0, 0, stack_height/2])
      cube([cell_size, cell_size, stack_height], center=true);
    translate([0, 0, -peg_hole_thread_h2/2])
      trapz_thread(peg_hole_thread_d1, peg_hole_thread_d2,
                   peg_hole_thread_h1, peg_hole_thread_h2,
                   thread_len=height+peg_hole_thread_h2,
                   pitch=peg_hole_thread_pitch,
                   $fn=peg_hole_thread_fn);
  }
}


module trapz_thread(d1, d2, h1, h2, thread_len, pitch) {
  thread_profile = [
    [d1/2, -h1/2],
    [d1/2, h1/2],
    [d2/2, h2/2],
    [d2/2, -h2/2],
  ];
  points = spiral_points(thread_profile, thread_len, pitch);
  faces = [
    [each [3:-1:0]],
    each spiral_paths(4, thread_len, pitch),
    [each [len(points)-4:len(points)-1]],
  ];

  polyhedron(points=points, faces=faces);
}


function spiral_points(profile_points, spiral_len, spiral_loop_pitch) =
  [for (i=[0:round($fn*spiral_len/spiral_loop_pitch)])
      each spiral_segment_points(
          profile_points,
          i * 360.0/$fn,
          i * spiral_loop_pitch/$fn)
  ];


function spiral_segment_points(profile_points, angle_offset, z_offset) =
  [for (p=profile_points)
      [
          p[0] * cos(angle_offset),
          p[0] * sin(angle_offset),
          p[1] + z_offset,
      ]
  ];


function spiral_paths(profile_points_count, spiral_len, spiral_loop_pitch) =
  [for (i=[0:round($fn*spiral_len/spiral_loop_pitch)-1])
      each spiral_segment_paths(profile_points_count, i)
  ];


function spiral_segment_paths(profile_points_count, segment_number) =
  [each [for(point=[0:profile_points_count-1])
            [
                segment_number*profile_points_count+limit_point_number(point+1, profile_points_count),
                segment_number*profile_points_count+limit_point_number(point+1, profile_points_count)+profile_points_count,
                segment_number*profile_points_count+limit_point_number(point, profile_points_count)+profile_points_count,
                segment_number*profile_points_count+limit_point_number(point, profile_points_count)
            ]
         ]];


function limit_point_number(point, profile_points_count) =
  point >= profile_points_count ? point - profile_points_count : point;
