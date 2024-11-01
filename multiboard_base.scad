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


// Main dimensions
cell_size = 25+0;
height = 6.4+0;

hole_thick = 3.6+0; // 3.280;
hole_thick_height = 2.4+0;
hole_thin = 1.6+0;

hole_rg_spiral_d=0.776+0;

hole_sm_d = 6.069+0.025; // 7.5;

// Single tile outer dimensions
side_l = cell_size/(1+2*cos(45));
bound_circle_d = side_l/sin(22.5);

size_l_offset = (cell_size - side_l)*0.5;

// Single tile hole dimensions
hole_thick_size = cell_size - hole_thick;
hole_thick_side_l = (cell_size - hole_thick)/(1+2*cos(45));
hole_thick_bound_circle_d = hole_thick_side_l/sin(22.5);

hole_thin_size = cell_size - hole_thin;
hole_thin_side_l = hole_thin_size/(1+2*cos(45));
hole_thin_bound_circle_d = hole_thin_side_l/sin(22.5);

large_thread_d1 = 22.5+0; // hole_thin_size - 0.6;
large_thread_d2 = hole_thick_size+0;
large_thread_h1 = 0.5+0;
large_thread_h2 = 1.583+0;
large_thread_fn=32+0;
large_thread_pitch = 2.5+0;

small_thread_pitch = 3+0;
small_thread_d1 = 7.025+0;
small_thread_d2 = 6.069+0;
small_thread_h1 = 0.768+0;
small_thread_h2 = small_thread_pitch-0.5;
small_thread_fn=32+0;

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
  multihole_threads();
}


module multihole_base() {
  outer_offset = hole_thin_bound_circle_d / 2;
  inner_offset = hole_thick_bound_circle_d / 2;

  rotate(22.5, [0, 0, 1])
    rotate_extrude($fn=8)
    polygon([
      [0,            -layer_separation],
      [outer_offset, -layer_separation],
      [outer_offset, 0],
      [inner_offset, (height - hole_thick_height)/2],
      [inner_offset, (height + hole_thick_height)/2],
      [outer_offset, height],
      [outer_offset, stack_height],
      [0,            stack_height],
    ]);
}


module multihole_threads() {
  translate([0, 0, -large_thread_h2/2])
    trapz_thread(large_thread_d1, large_thread_d2,
                 large_thread_h1, large_thread_h2,
                 thread_len=height+large_thread_h2,
                 pitch=large_thread_pitch,
                 $fn=large_thread_fn);
}


module peg_hole() {
  peg_hole_base();
  peg_hole_threads();
}


module peg_hole_base() {
  translate([0, 0, -layer_separation])
    cylinder(
      d=hole_sm_d,
      h=stack_height + layer_separation,
      $fn=small_thread_fn);
}


module peg_hole_threads() {
  intersection() {
    translate([0, 0, stack_height/2])
      cube([cell_size, cell_size, stack_height], center=true);
    translate([0, 0, -small_thread_h2/2])
      trapz_thread(small_thread_d1, small_thread_d2,
                   small_thread_h1, small_thread_h2,
                   thread_len=height+small_thread_h2,
                   pitch=small_thread_pitch,
                   $fn=small_thread_fn);
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
