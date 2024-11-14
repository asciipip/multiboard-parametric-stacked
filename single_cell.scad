/* Generates a single tile cell, with multihole and peg hole.
 *
 * This is mostly for debugging.
 */

use <multiboard_base.scad>

// This should be the same alignment as the .STEP remixing files.
translate([-12.5, -12.5, 0])
multiboard_cell(true);
