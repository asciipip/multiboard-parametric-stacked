# Stacked Parametric Multiboard Tiles

This is an [OpenSCAD][] file for generating arbitrary stacked
[Multiboard][] tiles.

  [OpenSCAD]: https://openscad.org/
  [Multiboard]: https://www.multiboard.io/


## Usage

Set the following parameters (at the top of the file):

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

Render the file and save to an STL.

In your slicer, make sure you've enabled ironing of top surfaces.

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
files (e.g. if you're mounting the on a wall).

You can print an entire set of tiles at once _as long as the tiles are
square_.  If you're tiling non-square tiles, you'll need at least two
separate stacks: one with the core tiles, the top (or bottom) side tiles,
and the corner tile; the other with the right (or left) side tiles.
That's because this generator always puts the side tile's teeth on the
right side, and the right (or left) side tiles need the teeth on top.  For
the right (or left) side tiles, swap the tile dimensions in the file
parameters and just print side tiles.

Stack-printed tiles can be difficult to separate.  Ironing the tile
surfaces is required, and you should have your printer calibrated as
precisely as possible.  If the stacks aren't working for you and you have
a multi-extruder printer, you might consider the [Multiboard Parametric
Extended][] model from Uno.

  [Multiboard Parametric Extended]: https://www.printables.com/model/882280-multiboard-parametric-extended-openscad

The author has only really tested this model with a 0.2 mm layer height.
Multiboard components in general are designed with that layer height in
general.  Although other layer heights _should_ work, they're
less-guaranteed.  Feedback on others' experiences of printing with other
thicknesses would be appreciated.  Note also that the model assumes that
all layers have equal heights (as opposed to using a different thickness
for the first layer).


## Tile Stack Sizing

To get the width of a tile, multiply the number of cells by 25 mm and then
add 8 mm for the teeth.  Each layer is 6.6 mm high, when printed with a
0.2 mm layer thickness.

A printer with a 220×220×250 mm print area can print up to 37 stacked 8×8
tiles.


## Credits

[Multiboard][] was designed by Jonathan of [Keep Making][].

  [Keep Making]: https://www.youtube.com/@Keep-Making

These files are based on Victor Zag's [multiboard-parametric][] project.
Victor really did all the hard work; this project's contributions are
fairly minimal in comparison.

  [multiboard-parametric]: https://github.com/shaggyone/multiboard-parametric


## License

This model is derived from Multiboard files and is covered by the
[Multiboard License][].  A copy is available in the `LICENSE.md` file.

  [Multiboard License]: https://www.multiboard.io/license

Note in particular that the license restricts commercial use of derived
works.
