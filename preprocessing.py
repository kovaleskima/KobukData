import json
import os
import xarray as xr
import numpy as np
from scipy.ndimage import map_coordinates
from pathlib import Path
from pyproj import Transformer

input_dir = Path("Sentinel2_cracks_raw/")
output_dir = Path("Sentinel2_cracks_processed/")
output_dir.mkdir(exist_ok=True)

def convert_to_lat_lon(raw_path):

    with open(raw_path) as f:
        cuts = json.load(f)
    print(cuts.values())

    # Load the SAME NetCDF used in NCCut
    filename = os.path.basename(raw_path)
    path_str = filename.replace(".json", "")
    ds = xr.open_dataset("Sentinel2_netCDF/" + path_str + ".nc")

    lat = ds.lat.values
    lon = ds.lon.values

    # Navigate JSON structure (example)
    for cut in cuts.values():
        x = np.array(cut["x"])
        y = np.array(cut["y"])

        # NCCut uses (x, y) but numpy arrays are (row=y, col=x)
        coords = np.vstack([y, x])

        lat_transect = map_coordinates(lat, coords, order=1)
        print(lat_transect.size)
        lon_transect = map_coordinates(lon, coords, order=1)

# Batch conversion
for json_path in sorted(input_dir.glob("*.json*")):
    convert_to_lat_lon(json_path)