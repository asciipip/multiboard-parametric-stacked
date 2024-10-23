#!/usr/bin/env python3

# TODO: Add the following to the program help text
#
# Give the program a space and it will figure out the optimal number of
# tiles to fit into that space.  You can optionally give the maximum size
# of your printer's printable area to tune the results to what your
# printer can handle.


import argparse
import math
import sys


CELL_SIZE_MM = 25
MAX_DEFAULT_TILE_SIZE = 8


def main():
    args = parse_args()
    show_dimensions(args)


def parse_args():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument('--help', action='store_true', help='Show this help message and exit')
    parser.add_argument('-w', '--width-mm', metavar='MM', type=float,
                        help='Width of the board area, in mm')
    parser.add_argument('-h', '--height-mm', metavar='MM', type=float,
                        help='Height of the board area, in mm')
    parser.add_argument('--width-cells', metavar='CELLS', dest='width', type=int,
                        help='Width of the board area, in cells')
    parser.add_argument('--height-cells', metavar='CELLS', dest='height', type=int,
                        help='Height of the board area, in cells')
    parser.add_argument('--tile-width', type=int, help='Width of each tile, in cells')
    parser.add_argument('--tile-height', type=int, help='Height of each tile, in cells')
    parser.add_argument('--max-tile-size-mm', type=float,
                        help='Maximum size of a tile side in mm; default {}'.format(CELL_SIZE_MM * MAX_DEFAULT_TILE_SIZE))
    parser.add_argument('--max-tile-size', type=int,
                        help='Maximum size of a tile side in cells; default {}'.format(MAX_DEFAULT_TILE_SIZE))
    args = parser.parse_args()

    if args.help:
        parser.print_help()
        exit(0)

    if (args.width_mm is not None and args.width is not None) \
       or (args.height_mm is not None and args.height is not None):
        print('Each dimension should be given in mm or cells, but not both.',
              file=sys.stderr)
        exit(1)

    if args.max_tile_size_mm is not None and args.max_tile_size is not None:
        print('Max tile size should be given in mm or cells, but not both.',
              file=sys.stderr)
        exit(1)

    if args.width_mm is not None:
        args.width = math.floor(args.width_mm / CELL_SIZE_MM)

    if args.height_mm is not None:
        args.height = math.floor(args.height_mm / CELL_SIZE_MM)

    if args.width is None or args.height is None:
        print('You must give a width and height.', file=sys.stderr)
        exit(1)

    if args.width_mm is None:
        args.width_mm = args.width * CELL_SIZE_MM

    if args.height_mm is None:
        args.height_mm = args.height * CELL_SIZE_MM

    if args.max_tile_size is None and args.max_tile_size_mm is not None:
        args.max_tile_size = math.floor(args.max_tile_size_mm / CELL_SIZE_MM)

    if args.max_tile_size is None:
        args.max_tile_size = MAX_DEFAULT_TILE_SIZE

    determine_tile_size(args)

    return args


def determine_tile_size(args):
    """Figures out a useful tile size, if not specified explicitly."""
    if args.tile_width is not None and args.tile_height is not None:
        return

    if args.tile_width is not None:
        args.tile_height = args.tile_width
        return

    if args.tile_height is not None:
        args.tile_width = args.tile_height
        return

    if args.width < args.max_tile_size and args.height < args.max_tile_size:
        # Only one tile is needed
        args.tile_width = args.width
        args.tile_height = args.height
        return

    min_x_tiles = math.ceil(args.width / MAX_DEFAULT_TILE_SIZE)
    min_x_size = math.ceil(args.width / min_x_tiles)
    args.tile_width = min_x_size

    min_y_tiles = math.ceil(args.height / MAX_DEFAULT_TILE_SIZE)
    min_y_size = math.ceil(args.height / min_y_tiles)
    args.tile_height = min_y_size


def show_dimensions(args):
    print('The parameters for the board are:')
    print()
    print('  Area dimensions: {:0.2f}×{:0.2f} mm'.format(args.width_mm, args.height_mm))
    print('  Board dimensions: {}×{} ({}×{} mm)'.format(
        args.width, args.height,
        args.width * CELL_SIZE_MM, args.height * CELL_SIZE_MM))
    print('  Base tile size: {}×{}'.format(args.tile_width, args.tile_height))
    print('  Board tile dimensions: {}×{}'.format(*board_tile_dimensions(args)))
    print()
    print('Tiles to be printed:')
    print()
    print('  Core:       {:3d}  {}×{}'.format(
        core_tile_count(args), args.tile_width, args.tile_height))
    if args.tile_width == args.tile_height \
       and top_tile_height(args) == right_tile_width(args):
        print('  Side:       {0:3d}  {1}×{2}'.format(
            right_tile_count(args) + top_tile_count(args),
            args.tile_width, top_tile_height(args)))
    else:
        print('  Right side: {0:3d}  {1}×{2}  (Print as {2}×{1} side tile)'.format(
            right_tile_count(args), right_tile_width(args), args.tile_height))
        print('  Top side:   {:3d}  {}×{}'.format(
            top_tile_count(args), args.tile_width, top_tile_height(args)))
    print('  Corner:       1  {}×{}'.format(right_tile_width(args), top_tile_height(args)))
        
    print()


def board_tile_dimensions(args):
    return (
        math.ceil(args.width / args.tile_width),
        math.ceil(args.height / args.tile_height)
    )


def core_tile_count(args):
    x_tiles, y_tiles = board_tile_dimensions(args)
    return (x_tiles - 1) * (y_tiles - 1)


def top_tile_count(args):
    x_tiles, y_tiles = board_tile_dimensions(args)
    return (x_tiles - 1)


def right_tile_count(args):
    x_tiles, y_tiles = board_tile_dimensions(args)
    return (y_tiles - 1)


def top_tile_height(args):
    if args.height % args.tile_height == 0:
        return args.tile_height
    else:
        return args.height % args.tile_height


def right_tile_width(args):
    if args.width % args.tile_width == 0:
        return args.tile_width
    else:
        return args.width % args.tile_width


if __name__ == '__main__':
    main()
