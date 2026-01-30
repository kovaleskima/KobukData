import json
import os
import xarray as xr
import numpy as np
from scipy.ndimage import map_coordinates
from pathlib import Path

input_dir = Path("Sentinel2_cracks_raw/")
output_dir = Path("Sentinel2_cracks_processed/")
output_dir.mkdir(exist_ok=True)

def convert_to_lat_lon(raw_path):

    with open(raw_path) as fin:
        c_dat = json.load(fin)


    # Load the SAME NetCDF used in NCCut
    filename = os.path.basename(raw_path)
    path_str = filename.replace(".json", "")
    ds = xr.open_dataset("Sentinel2_netCDF/" + path_str + ".nc")

    lat = ds.lat.values
    lon = ds.lon.values

    chain_points = {}

    for metadata_name, metadata in c_dat.items():

        for chain_name, chain in metadata.items():
            points_list = []
            # Get actual inline chain objects
            if isinstance(metadata[chain_name], dict): 
                for cut_name, cut in chain.items():
                    if cut_name.startswith("Cut"):
                        x = np.array(cut['x'])
                        y = np.array(cut['y'])
                        points_list.append(np.vstack([y, x]))  # shape (2, N_cut)
                
                if points_list:  # make sure there are cuts
                    coords = np.hstack(points_list)  # shape (2, total_points)
                    
                    lat_transect = map_coordinates(lat, coords, order=1)
                    lon_transect = map_coordinates(lon, coords, order=1)
                    
                    # save as (2, total_points) array: first row lat, second row lon
                    chain_points[chain_name] = {"lat": lat_transect.tolist(), "lon": lon_transect.tolist()}
    
    # Save chain_points to its own json
    processed_path = str(output_dir) + '/' + str(filename)
    with open(processed_path, "w") as fout:
        json.dump(chain_points, fout, indent=4)
        
# Batch conversion
for json_path in sorted(input_dir.glob("*.json*")):
    convert_to_lat_lon(json_path)