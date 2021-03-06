
[![Travis-CI Build Status](http://badges.herokuapp.com/travis/hypertidy/anglr?branch=master&env=BUILD_NAME=trusty_release&label=linux)](https://travis-ci.org/hypertidy/anglr) [![Build Status](http://badges.herokuapp.com/travis/hypertidy/anglr?branch=master&env=BUILD_NAME=osx_release&label=osx)](https://travis-ci.org/hypertidy/anglr) [![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/hypertidy/anglr?branch=master&svg=true)](https://ci.appveyor.com/project/mdsumner/anglr) [![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/anglr)](https://cran.r-project.org/package=anglr) [![Coverage Status](https://img.shields.io/codecov/c/github/hypertidy/anglr/master.svg)](https://codecov.io/github/hypertidy/anglr?branch=master)

<!-- README.md is generated from README.Rmd. Please edit that file -->
NOTE: none of these 3D scenes can be viewed on github so a temporary copy of this readme with the figures rendered is here: <http://rpubs.com/cyclemumner/367003>

Topological forms for plotting spatial data
-------------------------------------------

The 'anglr' package illustrates some generalizations of GIS-y tasks in R with a database-y approach.

The basic idea is to showcase topological forms of objects from a variety of sources:

-   silicate forms
-   simple features
-   Spatial features
-   rgl 3D objects
-   trip objects (and general animal tracking data types)
-   regular raster grids
-   igraph
-   Lidar

To do this anglr works with forms defined by [silicate](https://github.com/hypertidy/silicate) and (after [rgl](https://cran.r-project.org/package=rgl)) provides `plot3d` methods for each of the models `SC`, `PATH`, `ARC` and `TRI`. Here we add two more models `DEL` (for high-quality triangulation) and `QUAD` (for raster data).

Usage
=====

The general approach is re-model your data using one of these models, optionally use `copy_down` to augment the model with a Z coordinate, and then `plot3d` it.

``` r
library(anglr)
model <- sf::st_read("some/shapefile.shp")
araster <- raster::raster("some/gridraster.tif")
mesh <- copy_down(silicate::SC(model), araster)
plot3d(mesh)
```

The copy down process will copy feature attributes (a constant measure) or raster attributes (a continuous measure) in the appropriate way. After copy down the mesh will be unique in XYZ, whereas the usual starting point is uniqueness in XY.

These *mesh* or *topological* forms can be used to merge disparate data into a single form, or used to convert standard spatial objects to `rgl` ready forms.

An example of merging vector and raster can be seen with this.

``` r
## a global DEM
data("gebco1", package = "anglr")
library(sf)
## North Carolina, the sf boilerplate polygon layer
nc <- read_sf(system.file("shape/nc.shp", package="sf"))


library(raster)
library(anglr) 
library(silicate)

p_mesh <- DEL(nc, max_area = 0.002)
## a relief map, composed of triangles grouped by polygon with ##  interpolated raster elevation 
p_mesh <- copy_down(p_mesh, z = gebco1)


## plot the scene
library(rgl)

rgl.clear()  ## rerun the cycle from clear to widget in browser contexts 
plot3d(p_mesh) 
bg3d("black"); material3d(specular = "black")
aspect3d(1, 1, .1)
rglwidget()  ## not needed if you have a local device
```

Here the `z` argument to `copy_down` is a raster, and so the `z_` coordinate of the mesh is updated by extracting values from the raster. If `z_` is alternately set to a column in the layer or a specific vector of values this is used as a constant offset for the `z_` value, and the mesh is *separated by feature*.

We only use TRI here both to illustrate its availability, but also because we only need poor quality triangles for planar geometry.

``` r

c_mesh <- copy_down(TRI(nc), z = p_mesh$object$BIR74)

rgl.clear()
a <- plot3d(c_mesh) 
bg3d("black"); material3d(specular = "black")
aspect3d(1, 1, .2)
rglwidget()  ## not needed if you have a local device
```

In the silicate models, complex objects are decomposed to a set of related, linked tables. Object identity is maintained with attribute metadata and this is carried through to colour and other aesthetics.

Plot (3D) methods take those tables and generate the "indexed array" structures needed for 'rgl'. (`plot3d` will return the rgl-model form). This gets us part of the way towards having the best of both worlds of GIS and 3D graphics.

Another example shows this approach applied to a 3D multipatch shapefile, with a few easy steps we can plot a wiremesh or roof/floor polygons from a civic building footprint.

<http://rpubs.com/cyclemumner/367010>

Ongoing design
--------------

The core work for translating spatial classes is done by the unspecialized 'silicate::PATH' function and its underlying decomposition generics. Ongoing work in the [silicate](https://github.com/hypertidy/silicate) package will improve and support these types more fully.

Planar polygons and lines are described by the same 1D primitives, and this is easy to do. Harder is to generate 2D primitives and for that we rely on [Jonathan Richard Shewchuk's Triangle](https://www.cs.cmu.edu/~quake/triangle.html).

Triangulation in DEL is with `RTriangle` package using "constrained mostly-Delaunay Triangulation" from the Triangle library, and TRI in silicate uses ear-clipping via Mapbox's `earcut.hpp` (this is analogous to but faster and more robust than `rgl::triangulate`). Independent work for mostly-Delaunay methods is in the `laridae` project.

With RTriangle we can set a max area for the triangles, so it can wrap around curves like globes and hills, and this can only be done by the addition of Steiner points. All of this takes us very far from the path-based types generally used by GIS-alikes.

Grids
-----

Raster gridded data are decomposed to `QUAD` forms, essentially a 2D primitive with four corners rather than three. This works well in rgl and is super fast using the quadmesh package that can translate from the raster package.

Texture mapping is possible with rgl, but it needs a local coordinate system mapped to the index space of a PNG image. It's easy enough but requires a bit of awkward preparation, not yet simplified.

Some different approaches:

<https://rpubs.com/cyclemumner/frink-polyogn>

Deprecated use of rangl here, but shows the general texture coordinate approach required:

<https://gist.github.com/mdsumner/dc80283de50bb23ff7681b14768b9367>

Installation
------------

Also required are packages 'rgl' and 'RTriangle', so first make sure you can install and use these.

``` r
install.packages("rgl")
install.packages("RTriangle")
devtools::install_github("hypertidy/anglr")
```

### Ubuntu/Debian

On Linux you will need at least the following installed by an administrator, here tested on Ubuntu Xenial 16.04 (note the apt/sources.list is specific to version).

``` bash
## key for apt-get update, see http://cran.r-project.org/bin/linux/ubuntu/README
echo 'deb https://cloud.r-project.org/bin/linux/ubuntu xenial/' >> /etc/apt/sources.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

## up to date GDAL and PROJ.4 and GEOS
## https://launchpad.net/~ubuntugis/+archive/ubuntu/ubuntugis-unstable
add-apt-repository ppa:ubuntugis/ubuntugis-unstable --yes

apt update 
apt upgrade --assume-yes

## Install 3rd parties
apt install libproj-dev libgdal-dev libgeos-dev  libssl-dev libgl1-mesa-dev libglu1-mesa-dev libudunits2-dev
## install R, if you need to
## apt install r-base r-base-dev 
```

Then in R

``` r
install.packages("devtools")
install.packages(c("dplyr", "proj4", "raster",  "rgl", "rlang", "RTriangle", "spbabel", "tibble", "viridis"))
devtools::install_github("hypertidy/anglr")
```

Get involved!
-------------

Let me know if you have problems, or are interested in this work. See the issues tab to make suggestions or report bugs.

<https://github.com/hypertidy/anglr/issues>

Examples
--------

See the vignettes: <https://hypertidy.github.io/anglr/articles/index.html>

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.
