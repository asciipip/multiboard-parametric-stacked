#!/usr/bin/env python3

import argparse
import collections
import json
import math
import pathlib
import shutil
import subprocess
import sys


CELL_SIZE_MM = 25
TOOTH_EXTRA_MM = 8
MAX_DEFAULT_TILE_SIZE = 8
STACK_SCAD_FILE = pathlib.Path(__file__)\
                         .resolve()\
                         .parent\
                         .joinpath('arbitrary_stack.scad')


TileGroup = collections.namedtuple('TileGroup', ['count', 'width', 'height', 'shape'])


def main():
    args = parse_args()
    show_dimensions(args)
    stacks = determine_stacks(args)
    confirm_stacks(stacks, args)
    if args.dxf:
        generate_dxf(stacks, args)
    if args.stl:
        generate_stacks(stacks, args)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generates models for a reasonable set of Multiboard tiles to cover a given 2D space.",
        epilog="""
You must give the dimensions of the space to fill, either in millimeters
(-w/--width-mm, -h/--height-mm) or in Multiboard cell counts
(--width-cells, --height-cells).

If you don't give your preferred tile size (--tile-width, --tile-height),
the program will try to pick a reasonable size that minimizes the number
of tiles needed and makes the side tiles as close as possible in size to
the core tiles.  The preferred tile size will be applied to the core
tiles; side and corner tiles might be truncated to fit in the space.""",
        formatter_class=argparse.RawTextHelpFormatter,
        add_help=False)
    parser.add_argument('--help', action='store_true', help='Show this help message and exit')
    parser.add_argument('-w', '--width-mm', metavar='MM', type=float,
                        help='Width of the board area, in mm')
    parser.add_argument('-h', '--height-mm', metavar='MM', type=float,
                        help='Height of the board area, in mm')
    parser.add_argument('--width-cells', metavar='CELLS', dest='width', type=int,
                        help='Width of the board area, in cells')
    parser.add_argument('--height-cells', metavar='CELLS', dest='height', type=int,
                        help='Height of the board area, in cells')
    parser.add_argument('--tile-width', metavar='CELLS',type=int,
                        help='Width of each tile, in cells')
    parser.add_argument('--tile-height', metavar='CELLS',
                        type=int, help='Height of each tile, in cells')
    parser.add_argument('--max-tile-size-mm', type=float, metavar='MM',
                        help='Maximum size of a tile side in mm; default {}'.format(CELL_SIZE_MM * MAX_DEFAULT_TILE_SIZE))
    parser.add_argument('--max-tile-size', type=int, metavar='CELLS',
                        help='Maximum size of a tile side in cells; default {}'.format(MAX_DEFAULT_TILE_SIZE))
    parser.add_argument('-y', '--yes', action='store_true',
                        help='Don\'t prompt before generating output files')
    parser.add_argument('--dxf', action=argparse.BooleanOptionalAction, default=False,
                        help='Generate a DXF file of the tile layout')
    parser.add_argument('--stl', action=argparse.BooleanOptionalAction, default=True,
                        help='Generate one or more STLs containing stacked tiles')
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
        args.max_tile_size = math.floor((args.max_tile_size_mm - TOOTH_EXTRA_MM) / CELL_SIZE_MM)

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

    if args.width <= args.max_tile_size and args.height <= args.max_tile_size:
        # Only one tile is needed
        args.tile_width = args.width
        args.tile_height = args.height
        return

    min_x_tiles = math.ceil(args.width / args.max_tile_size)
    min_x_size = math.ceil(args.width / min_x_tiles)
    args.tile_width = min_x_size

    min_y_tiles = math.ceil(args.height / args.max_tile_size)
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


def determine_stacks(args):
    result = [[]]
    if core_tile_count(args) > 0:
        result[0].append(TileGroup(
            count=core_tile_count(args),
            width=args.tile_width,
            height=args.tile_height,
            shape='core'))
    if args.tile_width == args.tile_height \
       and top_tile_height(args) == right_tile_width(args):
        if right_tile_count(args) + top_tile_count(args) > 0:
            result[0].append(TileGroup(
                count=right_tile_count(args) + top_tile_count(args),
                width=args.tile_width,
                height=top_tile_height(args),
                shape='side'))
    else:
        if top_tile_count(args) > 0:
            result[0].append(TileGroup(
                count=top_tile_count(args),
                width=args.tile_width,
                height=top_tile_height(args),
                shape='side'))
        if right_tile_count(args) > 0:
            if top_tile_count(args) == 0:
                # Without the other side piece, this side can go on the main stack
                right_stack = result[0]
            else:
                right_stack = []
                result.append(right_stack)
            right_stack.append(TileGroup(
                count=right_tile_count(args),
                width=right_tile_width(args),
                height=args.tile_height,
                shape='rotated side'))
    result[0].append(TileGroup(
        count=1,
        width=right_tile_width(args),
        height=top_tile_height(args),
        shape='corner'))
    return result


def confirm_stacks(stacks, args):
    errors = []

    print('{} stack{} will be printed:'.format(
        len(stacks),
        '' if len(stacks) == 1 else 's'))
    for i, stack in enumerate(stacks):
        print()
        print('  Stack {} [{}]:'.format(i + 1, stack_name(stack)))
        for tile_group in stack:
            print('    {} {} {}×{} tile{}'.format(
                tile_group.count,
                tile_shape_text(tile_group.shape),
                tile_group.width,
                tile_group.height,
                '' if tile_group.count == 1 else 's'))
            if tile_group.width < 2 or tile_group.height < 2:
                errors.append('ERROR: Tiles must be at least 2×2, but {} tile is only {}×{}!'.format(
                    tile_shape_text(tile_group.shape), tile_group.width, tile_group.height))

    if len(errors) > 0:
        print();
        for error in errors:
            print(error)

    if len(errors) > 0:
        exit(1)

    if args.stl or args.dxf:
        if not args.yes:
            print()
            answer = input('Okay to proceed? [Y/n] ')
            if answer != '' and answer.lower() != 'y' and answer.lower() != 'yes':
                exit(1)


def generate_stacks(stacks, args):
    print()

    if shutil.which('openscad') is None:
        print('Cannot find openscad in PATH; exiting.', file=sys.stderr)
        print('STLs were NOT generated.', file=sys.stderr)
        exit(1)

    for stack in stacks:
        stack_path = pathlib.Path(stack_name(stack))
        if stack_path.exists() and not args.yes:
            yn = input('{} exists; overwrite? [y/N] '.format(stack_path))
            if yn.lower() != 'y' and yn.lower() != 'yes':
                print('Skipping...')
                print()
                continue
        print('Generating {}; this will take a while...'.format(stack_path))
        cmd = [
            'openscad',
            '-o', stack_path,
            '-D', 'tiles=' + json.dumps(stack),
            STACK_SCAD_FILE,
        ]
        subprocess.run(cmd, check=True)
        print()


def generate_dxf(stacks, args):
    import ezdxf

    dxf_file = ezdxf.new()
    msp = dxf_file.modelspace()

    core_block_name   = dxf_add_tile(dxf_file, 'core',   args.tile_width,        args.tile_height)
    side_block_name   = dxf_add_tile(dxf_file, 'side',   right_tile_width(args), args.tile_height)
    top_block_name    = dxf_add_tile(dxf_file, 'top',    args.tile_width,        top_tile_height(args))
    corner_block_name = dxf_add_tile(dxf_file, 'corner', right_tile_width(args), top_tile_height(args))

    x_tiles, y_tiles = board_tile_dimensions(args)
    for x in range(0, x_tiles - 1):
        for y in range(0, y_tiles - 1):
            msp.add_blockref(core_block_name, (x * args.tile_width * CELL_SIZE_MM, y * args.tile_height * CELL_SIZE_MM))
    for y in range(0, y_tiles - 1):
        msp.add_blockref(side_block_name, ((x_tiles - 1) * args.tile_width * CELL_SIZE_MM, y * args.tile_height * CELL_SIZE_MM))
    for x in range(0, x_tiles - 1):
        msp.add_blockref(top_block_name, (x * args.tile_width * CELL_SIZE_MM, (y_tiles - 1) * args.tile_height * CELL_SIZE_MM))
    msp.add_blockref(corner_block_name, ((x_tiles - 1) * args.tile_width * CELL_SIZE_MM, (y_tiles - 1) * args.tile_height * CELL_SIZE_MM))

    area_origin = (-(args.width_mm % CELL_SIZE_MM) / 2, -(args.height_mm % CELL_SIZE_MM) / 2)
    msp.add_lwpolyline([
        area_origin,
        (area_origin[0] + args.width_mm, area_origin[1]),
        (area_origin[0] + args.width_mm, area_origin[1] + args.height_mm),
        (area_origin[0], area_origin[1] + args.height_mm),
    ],
                       close=True)

    dxf_file.set_modelspace_vport(args.height_mm, (args.width_mm / 2, args.height_mm / 2))
    dxf_file.saveas('Stack.dxf')


def dxf_add_tile(dxf_file, tile_type, tile_width, tile_height):
    octagon_side = CELL_SIZE_MM / (1 + 2 * math.cos(math.pi / 4))
    side_offset = (CELL_SIZE_MM - octagon_side) / 2

    block_name = 'tile-{}-{}x{}'.format(tile_type, tile_width, tile_height)
    block = dxf_file.blocks.new(block_name)
    points = []
    for x in range(0, tile_width):
        cell_x = x * CELL_SIZE_MM
        cell_y = 0
        y_offset = side_offset
        points.append((cell_x + side_offset, cell_y))
        points.append((cell_x + CELL_SIZE_MM - side_offset, cell_y))
        points.append((cell_x + CELL_SIZE_MM, cell_y + y_offset))
    for y in range(0, tile_height):
        cell_x = tile_width * CELL_SIZE_MM
        cell_y = y * CELL_SIZE_MM
        if tile_type in set(['core', 'top']):
            x_offset = side_offset
        else:
            x_offset = -side_offset
        points.append((cell_x, cell_y + side_offset))
        points.append((cell_x, cell_y + CELL_SIZE_MM - side_offset))
        points.append((cell_x + x_offset, cell_y + CELL_SIZE_MM))
    for x in range(tile_width, 0, -1):
        cell_x = (x - 1) * CELL_SIZE_MM
        cell_y = tile_height * CELL_SIZE_MM
        if tile_type in set(['core', 'side']):
            y_offset = side_offset
        else:
            y_offset = -side_offset
        points.append((cell_x + CELL_SIZE_MM, cell_y + y_offset))
        points.append((cell_x + CELL_SIZE_MM - side_offset, cell_y))
        points.append((cell_x + side_offset, cell_y))
    for y in range(tile_height, 0, -1):
        cell_x = 0
        cell_y = (y - 1) * CELL_SIZE_MM
        x_offset = side_offset
        points.append((cell_x, cell_y + CELL_SIZE_MM - side_offset))
        points.append((cell_x, cell_y + side_offset))
        points.append((cell_x + x_offset, cell_y))
    block.add_lwpolyline(points, close=True)
    return block_name

    
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


def stack_name(stack):
    result = 'Stack'
    for group in stack:
        if group.shape == 'side':
            shape_name = 'top'
        elif group.shape == 'rotated side':
            shape_name = 'right'
        else:
            shape_name = group.shape
        if group.count == 1:
            result += '-{}x{}_{}'.format(
                group.width,
                group.height,
                shape_name)
        else:
            result += '-{}x{}x{}_{}'.format(
                group.count,
                group.width,
                group.height,
                shape_name)
    result += '.stl'
    return result


def tile_shape_text(shape):
    return {
        'core': 'Core',
        'side': 'Top Side',
        'rotated side': 'Right Side',
        'corner': 'Corner'
    }[shape]


if __name__ == '__main__':
    main()
