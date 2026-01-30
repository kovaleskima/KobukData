import rasterio
import xarray as xr
import numpy as np
from pyproj import Transformer
from pathlib import Path

input_dir = Path("./Sentinel2_TIFF")
output_dir = Path("./Sentinel2_netCDF")
output_dir.mkdir(exist_ok=True)

def convert_tif_to_nc(tif_path):
    with rasterio.open(tif_path) as ds:
        if ds.crs is None or ds.transform is None:
            raise ValueError(f"{tif_path.name} is not georeferenced")

        data = ds.read(1)
        height, width = data.shape

        rows, cols = np.meshgrid(
            np.arange(height),
            np.arange(width),
            indexing="ij"
        )

        xs, ys = rasterio.transform.xy(ds.transform, rows, cols)
        xs = np.asarray(xs).reshape(height, width)
        ys = np.asarray(ys).reshape(height, width)


        if ds.crs.to_epsg() != 4326:
            transformer = Transformer.from_crs(
                ds.crs, "EPSG:4326", always_xy=True
            )
            lon, lat = transformer.transform(xs, ys)
        else:
            lon, lat = xs, ys

    da = xr.DataArray(
        data,
        dims=("y", "x"),
        coords={
            "lat": (("y", "x"), lat),
            "lon": (("y", "x"), lon),
        },
        name=tif_path.stem
    )

    out_nc = output_dir / f"{tif_path.stem}.nc"
    da.to_netcdf(out_nc, engine='netcdf4')
    print(f"Converted: {tif_path.name} → {out_nc.name}")

# Run batch conversion
for tif in sorted(input_dir.glob("*.tiff*")):
    convert_tif_to_nc(tif)
