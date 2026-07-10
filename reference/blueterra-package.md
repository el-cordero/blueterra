# blueterra: Process-oriented geomorphometry for submerged terrain

`blueterra` derives, organizes, summarizes, and visualizes terrain
metrics from user-supplied bathymetric or elevation rasters. It is
intended for submerged-landscape geomorphometry after a raster has
already been obtained.

## Details

The package accepts
[`terra::SpatRaster`](https://rspatial.github.io/terra/reference/SpatRaster-class.html)
objects, local raster file paths, and other raster inputs readable by
`terra`. Vector workflows use
[`terra::SpatVector`](https://rspatial.github.io/terra/reference/SpatVector-class.html)
objects or local vector files readable by
[`terra::vect()`](https://rspatial.github.io/terra/reference/vect.html).

Depth convention is explicit. Some bathymetric rasters store depth as
negative elevation, while other workflows use positive depth. Functions
preserve the input sign unless a conversion function or argument asks
for a sign change.

Terrain derivatives are sensitive to CRS, raster resolution, smoothing,
and focal-window scale. Use projected coordinate systems when distance,
slope, area, or buffering operations depend on linear units.

## See also

Useful links:

- <https://el-cordero.github.io/blueterra/>

- <https://github.com/el-cordero/blueterra>

- Report bugs at <https://github.com/el-cordero/blueterra/issues>

## Author

**Maintainer**: Elvin Cordero <elvin.cordero@seamountgeo.com>

Other contributors:

- SeaMount Geospatial Labs \[copyright holder\]
