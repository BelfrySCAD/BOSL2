# Utility to convert GeoTIFF data to OpenSCAD or JSON formats.
# Written with a lot of back-and-forth collaboration with ChatGPT
# May 2025

# Sources of Planetary/Moon GeoTIFF Data (information below may be out of date)
#
# 1. USGS Astrogeology Science Center - https://astrogeology.usgs.gov/search
# Elevation/bathymetry GeoTIFFs for:
#   Mars (MOLA)
#   Moon (LOLA)
#   Venus (Magellan)
#   Mercury (MESSENGER)
#   Ceres, Vesta, Europa, Ganymede, Titan, etc.
# Most data is in GeoTIFF or .IMG formats. Look for DEM, DTM, or topography in the search.
#
# 2. NASA PDS (Planetary Data System) - https://pds.nasa.gov
# More advanced, but hosts nearly every planetary mission dataset.
# Good for Mars, the Moon, and Mercury.
#
# 3. OpenPlanetaryMap / OpenPlanetary - https://github.com/OpenPlanetary/opm
# Community-led project with easy-to-use formats.

# Files may be large (100–500 MB)! Some are .IMG or .JP2 and must be converted to .tif using GDAL.
# Some planetary datasets use planetocentric or planetographic projections — still usable for 2D mapping.


import argparse
import numpy as np
import rasterio
from rasterio.enums import Resampling
import json

# ----------------------------
# Command-line argument parsing
# ----------------------------
parser = argparse.ArgumentParser(
    description="Convert a GeoTIFF elevation file to an OpenSCAD 2D array using nonlinear elevation scaling.",
    epilog="""Examples:
  python geotiff2scad.py mydata.tif
  python geotiff2scad.py mydata.tif -o terrain.scad -v terrain_data -r 720x360
  python geotiff2scad.py mydata.tif --resize 360 --output terrain.scad --varname elevation_map
""",
    formatter_class=argparse.RawTextHelpFormatter
)
parser.add_argument("input_file", nargs='?', default="geotiff.tif", help="Input GeoTIFF filename (default=geotiff.tif)")
parser.add_argument("-o", "--output", default="terrain.scad", help="Output OpenSCAD file (default=terrain.scad)")
parser.add_argument("-v", "--varname", default="elevation_data", help="Variable name for SCAD array (default=elevation_data)")
parser.add_argument("-r", "--resize", default="360", help="Resize to WxH or W; e.g. 300x150, or 300 width preserving aspect; default=360)")
parser.add_argument("-s", "--scale", default="cbrt", choices=["cbrt", "sqrt"], help="Scaling method (cube root or sqare root, default=cbrt)")
parser.add_argument("--min_land_value", type=float, default=0.03, help="Minimum scaled land value, default=0.03, use 0 for planets/moons")
parser.add_argument("--json", action="store_true", help="Output a .json file instead of a .scad file")
args = parser.parse_args()

# ----------------------------
# Parse resize dimensions
# ----------------------------
def parse_resize(resize_str):
    if "x" in resize_str:
        w, h = map(int, resize_str.lower().split("x"))
    else:
        w = int(resize_str)
        h = int(w / 2)  # Assume 2:1 equirectangular aspect ratio
    return w, h

output_width, output_height = parse_resize(args.resize)

# ----------------------------
# Load GeoTIFF and downsample
# ----------------------------
print(f"Reading data from {args.input_file} and resampling to {output_width}×{output_height}")
with rasterio.open(args.input_file) as src:
    data = src.read(1, out_shape=(1, output_height, output_width), resampling=Resampling.bilinear)
    print("Processing data")
    # Replace nodata values
    nodata = src.nodata
    if nodata is not None:
        data[data == nodata] = 0
    data = np.nan_to_num(data, nan=0)

# ----------------------------
# Basic elevation stats
# ----------------------------
raw_min = np.min(data)
raw_max = np.max(data)
print(f"Elevations after resampling: min={raw_min}, max={raw_max}")

min_land_value = args.min_land_value            # e.g. 0.04
land_mask = data > 0                            # positive elevations
sea_mask  = data <= 0                           # sea level and below

# ----------------------------
# Scale data using cube-root or square-root
# ----------------------------

def scale_fn(x, mode=args.scale):               # args.scale is 'cbrt' or 'sqrt'
    if mode == "sqrt":
        return np.sqrt(x)
    elif mode == "cbrt":
        return np.cbrt(x)
    else:
        raise ValueError("Unsupported scale mode")

scaled = np.zeros_like(data, dtype=np.float32)  # zero'd output array

# ---- LAND  -------------------------------------------------------
land_data = scale_fn(data[land_mask])           # transform land only
min_land  = land_data.min()
max_land  = land_data.max()

# Scale factor is derived **solely from land range**
scale_factor = (1.0 - min_land_value) / (max_land - min_land)

# Map land to  [min_land_value, 1.0]
scaled[land_mask] = (land_data - min_land) * scale_factor + min_land_value

# ---- SEA  --------------------------------------------------------
# Use the same scale_factor so land & sea remain proportional,
# but subtract sea’s own minimum (shallowest depth) so that
# sea level (0 m) maps to -min_land_value and deeper values extend down.
if np.any(sea_mask):
    sea_data = scale_fn(np.abs(data[sea_mask]))  # make depths positive, then transform
    min_sea  = sea_data.min()                    # shallowest (near zero)
    # Map sea to [ -min_land_value … more negative ]
    scaled[sea_mask] = -((sea_data - min_sea) * scale_factor + min_land_value)

# -----------------------------------------------------------------

# Compact formatter for json (no unnecessary whitespace)
def format_json_array(data_array):
    return json.dumps(data_array, separators=(',', ':'))

# Compact formatter for OpenSCAD (no unnecessary whitespace)
def format_val(val):
    # Omit leading 0 and trailing zeros
    return f"{val:.2f}".lstrip("0").rstrip("0").rstrip(".") if val >= 0 else f"-{abs(val):.2f}".lstrip("0").rstrip("0").rstrip(".")

output_filename = ""
print("Writing output file")
if args.json or args.output.endswith(".json"):
    if not args.output.endswith(".json"):
        output_filename = args.output.rsplit('.', 1)[0] + ".json"
    else:
        output_filename = args.output
    formatted_array = [
        [format_val(val) for val in row] for row in scaled.tolist()
    ]
    with open(output_filename, "w") as f:
        json.dump({args.varname: formatted_array}, f, separators=(",", ":"))
else:
    if not args.output.endswith(".scad"):
        output_filename = args.output.rsplit('.', 1)[0] + ".scad"
    else:
        output_filename = args.output
    with open(output_filename, "w") as f:
        f.write(f"// Auto-generated terrain data\n")
        f.write(f"// Source file: {args.input_file}\n")
        f.write(f"// Original resolution: {src.width}x{src.height}\n")
        f.write(f"// Output resolution: {output_width}x{output_height}\n")
        f.write(f"// Raw elevation range: {raw_min:.2f} to {raw_max:.2f} meters\n")
        f.write(f"// Scaled value range: {np.min(scaled):.4f} to {np.max(scaled):.4f}\n")
        f.write(f"{args.varname} = [\n")
        for row in scaled:
            line = "[" + ",".join(format_val(val) for val in row) + "],\n"
            f.write(line)
        f.write("];\n")

print(f"✅ Done: Output saved to {output_filename}")
