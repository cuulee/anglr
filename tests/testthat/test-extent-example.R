context("test-extent-example.R")

# Create an extent to triangulate
library(sf)
library(anglr)
library(raster)
my_extent <- st_as_sf(as(extent(c(153.185183093, 153.19443135, -27.705328446, -27.6967222119999)), 
                         "SpatialPolygons"))
## should error on max_area 
DEL(my_extent, max_area = 0.008)

test_that("dataframes with only geometry are handled", {
  expect_that(DEL(my_extent, max_area = 0.008), is_a("TRI"))
})
