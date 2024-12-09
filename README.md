# Stacked Parametric Multiboard Tiles

This is an [OpenSCAD][] file for generating arbitrary stacked
[Multiboard][] tiles.

  [OpenSCAD]: https://openscad.org/
  [Multiboard]: https://www.multiboard.io/

![Rendering of a stack of Multiboard tiles](/assets/multiboard_base.png)


## Usage

Use the `multiboard_base.scad` file and set the following parameters:

 * `x_cells` – The number of cells (large holes) in the X direction
 * `y_cells` – The number of cells in the Y direction
 * `core_tiles` – The number of core tiles to generate; these tiles have
   teeth in both the X and Y direction
 * `side_tiles` – The number of side tiles to generate; these tiles have
   teeth only in the X direction
 * `corner_tiles` – The number of corner tiles to generate; these tiles
   have no teeth
 * `layer_thickness` – The layer thickness you will be using to print the
   tiles

If you want the side and corner tiles to have different dimensions from
the corner tiles, you can also change the advanced settings, which should
be fairly self-explanatory:

 * `side_x_cells`
 * `side_y_cells`
 * `corner_x_cells`
 * `corner_y_cells`

The default value for those advanced settings is "0", which means to use
the `x_cells` and `y_cells` values for the tile.

Render the file and save to an STL.

In your slicer, make sure you've enabled ironing of top surfaces.  In
addition to that, make sure you're using the recommended Multiboard
printing parameters (3-line thick walls, 15% infill).

After printing, it may take a little work to separate the tiles.  The
author has had the best luck by pulling apart the corner closest to the
origin (i.e. furthest from the tile teeth) and then working along the tile
from there.

Multiboard has a video about how to print stacks:
[Multiboard: What Is Stack 3D Printing](https://youtu.be/xs2urfM0MRM).


## Stack Printing Drawbacks

Stack-printed tiles will have one side that's smooth and the other side
(the one on the bottom during printing) will be a bit rough.  This
shouldn't be a problem if you're only planning on using one side of the
files (e.g. if you're mounting them on a wall).

You can print an entire set of tiles at once _as long as the tiles are
square_.  If you're tiling non-square tiles, you'll need at least two
separate stacks: one stack with the core tiles, the top (or bottom) side
tiles, and the corner tile; the other stack with the right (or left) side
tiles.  That's because this generator always puts the side tile's teeth on
the right side, and the right (or left) side tiles need the teeth on top.
For the right (or left) side tiles, swap the tile X and Y dimensions in
the file parameters and just print side tiles.

Stack-printed tiles can be difficult to separate.  Ironing the tile
surfaces is required, and you should have your printer calibrated as
precisely as possible.  If the stacks aren't working for you and you have
a multi-extruder printer, you might consider the [Multiboard Parametric
Extended][] model from Uno.

  [Multiboard Parametric Extended]: https://www.printables.com/model/882280-multiboard-parametric-extended-openscad

The author has only really tested this model with a 0.2 mm layer height.
Multiboard components in general are designed to be printed with 0.2 mm
layers.  Although other layer heights _should_ work with this model,
they're less-guaranteed.  Feedback on others' experiences of printing with
different thicknesses would be appreciated.  Note also that the model
assumes all layers have equal heights (as opposed to using a
different thickness for the first layer).


## Tile Stack Sizing

To get the width of a tile, multiply the number of cells by 25 mm and then
add 8 mm for the teeth.  Each layer is 6.6 mm high, when printed with a
0.2 mm layer thickness.

A printer with a 220×220×250 mm print area can print up to 37 stacked 8×8
tiles.


## Stacks of Arbitrary Tiles

The `arbitrary_stack.scad` file can be used to create a stack of tiles
with arbitrary shapes and dimensions.  You need to put the tile
definitions in the `tiles` array.  Tile definitions can include lists of
cells to omit from the generated model.

See the comment at the top of the file for more information.


## Tile Generating Program

There's a small program in the repository to generate STLs for the tiles
needed to cover a given area.  Run `generate-stacks.py --help` for usage
information.

You need to have `openscad` in your path for the STL generation to work.
You can also pass the `-n` or `--dry-run` parameter to just display the
tiles that could be used to cover the area.

For example, if you had an area 431 mm by 717 mm, you could run:

    generate-stacks.py -w 431 -h 717

Which would print the following before generating the tile stacks described:

    The parameters for the board are:
    
      Area dimensions: 431.00×717.00 mm
      Board dimensions: 17×28 (425×700 mm)
      Base tile size: 6×7
      Board tile dimensions: 3×4
    
    2 stacks will be printed:
    
      Stack 1 [Stack-6x6x7_core-2x6x7_top-5x7_corner.stl]:
        6 Core 6×7 tiles
        2 Top Side 6×7 tiles
        1 Corner 5×7 tile
    
      Stack 2 [Stack-3x5x7_right.stl]:
        3 Right Side 5×7 tiles


## Credits

[Multiboard][] was designed by Jonathan of [Keep Making][].

  [Keep Making]: https://www.youtube.com/@Keep-Making

These files are based on Victor Zag's [multiboard-parametric][] project.
Victor did all the really important initial work.

  [multiboard-parametric]: https://github.com/shaggyone/multiboard-parametric


## License

This model is derived from Multiboard files and is covered by the
[Multiboard License][].  A copy is available in the `LICENSE.md` file.

  [Multiboard License]: https://www.multiboard.io/license

Note in particular that the license restricts commercial use of derived
works.
