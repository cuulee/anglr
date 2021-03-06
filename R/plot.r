plot.DEL <- function(x, ..., add = FALSE) {
  
  if (!add) plot(x$vertex[c("x_", "y_")], type = "n")
  if ("color_" %in% names(x$object)) {
    cols <- x$object$color_
  } else {
    cols <- viridis::viridis(nrow(sc_object(x)))
  }
  for (i in seq_len(nrow(x$object))) { 
    asub <- dplyr::filter(x$object_link_triangle, .data$object_ == x$object$object_[i]) %>%
      dplyr::inner_join(x$triangle) %>% 
      dplyr::transmute(.data$.vertex0, .data$.vertex1, .data$.vertex2, fill = NA_character_) %>% 
      t() %>% 
      as.vector() 
    asub <-   tibble::tibble(vertex_ = asub)
    asub <- head(asub, -1L)
    graphics::polypath(dplyr::left_join(asub,x$vertex,  "vertex_") %>% dplyr::select(.data$x_, .data$y_), 
                       col = cols[i], ...)
    
  }
}


#' Title
#'
#' @param x quad_mesh
#' @param ... args passed to rgl plot
#' @param add reset plot?
#' @return qmesh
#' @export
#'
#' @seealso anglr.RasterLayer
plot.quad_mesh <- function(x, ..., add = FALSE) {
  .Deprecated(new = "plot.QUAD", package = "anglr", old = "plot(<quad_mesh>)")
  ## etc blah
  ob <- mkq_3d()
  ob$vb <- t(cbind(as.matrix(x$v[, c("x_", "y_", "z_")]), 1))
  ob$ib <- matrix(x$qXv$vertex_, nrow = 4)
  ob$material$col <- trimesh_cols(nrow(x$qd))[ob$ib]
  #rgl::shade3d(ob, col = trimesh_cols(nrow(x$qd))[ob$ib], ...)
  if (!add & length(rgl::rgl.dev.list()) < 1L) rgl::rgl.clear()
  
  rgl::shade3d(ob, ...)
  #if ( rgl::rgl.useNULL()) force(rgl::rglwidget()  )
  
  invisible(ob)
}


#' Plot objects in OpenGL
#' 
#' Plot using the \code{\link[rgl]{rgl-package}}. 
#'
#' The data structures from \code{\link{anglr}} are converted to their analogous forms
#' used by the \code{\link[rgl]{rgl}} package and plotted. These plot methods return
#' the rgl form invisibly. 
#'
#' @param x object from \code{\link{anglr}}
#' @param ... args for underlying plotting
#' @param add_normals if TRUE use `rgl::addNormals` to smooth the model before plotting
#' @param add add to existing plot if exists
#'
#' @return the rgl mesh3d object, invisibly
#' @export
#' @importFrom rgl shade3d
#' @name plot-anglr
#' @aliases plot
plot.trimesh <- function(x,  ..., add = FALSE, add_normals = FALSE) {
  .Deprecated(new = "plot.TRI", package = "anglr", old = "plot(<tri_mesh>)")
  
  if (!"color_" %in% names(x$o)) {
    x$o$color_ <- trimesh_cols(nrow(x$o))
  }
  
  if (!requireNamespace("rgl", quietly = TRUE))
    stop("rgl required")
  haveZ <- "z_" %in% names(x$v)
  tt <- th3d()
  
  if (haveZ) {
    tt$vb <- t(cbind(x$v$x_, x$v$y_, x$v$z_, 1))
  } else {
    
    tt$vb <- t(cbind(x$v$x_, x$v$y_, 0, 1))
  }
  vv <- x$v[, "vertex_"]; vv$row_n <- seq(nrow(vv))


  pindex <- x$tXv %>% dplyr::inner_join(x$t, "triangle_") %>% 
    dplyr::inner_join(x$o[c("object_", "color_")], "object_") 
  vindex <- dplyr::inner_join(x$tXv, vv, "vertex_")
 
  
  triangle <- x$t %>% dplyr::inner_join(x$o[c("object_", "color_")], "object_")
  ## join up triangle's to vertices by on separately, per object
  vertex <- purrr::map_df(split(triangle[c("color_", "triangle_")], triangle$object_), 
                          ~inner_join(.x, x$tXv, "triangle_")) %>% 
    inner_join(vv, "vertex_")
  
  tt$it <- t(matrix(vertex$row_n, ncol = 3, byrow = TRUE))
  if (!add & length(rgl::rgl.dev.list()) < 1L) rgl::rgl.clear()
  if (add_normals) tt <- rgl::addNormals(tt)
  rgl::shade3d(tt, col = vertex$color_, ...)
  
 # if ( rgl::rgl.useNULL()) rgl::rglwidget()  
  invisible(tt)

}

#' @name plot-anglr
#' @export
plot.linemesh <- function(x,  ..., add = FALSE) {
  .Deprecated(new = "plot.PATH or plot.SC", package = "anglr", old = "plot(<line_mesh>)")
  
  if (!"color_" %in% names(x$o)) {
    x$o$color_ <- trimesh_cols(nrow(x$o))
  }
  if (!requireNamespace("rgl", quietly = TRUE))
    stop("rgl required")
  haveZ <- "z_" %in% names(x$v)
  #tt <- th3d()
  
  if (haveZ) {
    vb <- t(cbind(x$v$x_, x$v$y_, x$v$z_))
  } else {
    
    vb <- t(cbind(x$v$x_, x$v$y_, 0))
  }
  vv <- x$v["vertex_"]; vv$row_n <- seq(nrow(vv))
  pindex <- dplyr::inner_join(dplyr::inner_join(x$o[, c("object_", "color_")], x$l), 
                              x$lXv)
  
  vindex <- dplyr::inner_join(x$lXv, vv, "vertex_")
  itex <- t(matrix(vindex$row_n, ncol = 2, byrow = TRUE))
  if (!add & length(rgl::rgl.dev.list()) < 1L) rgl::rgl.clear()
  
  rgl::segments3d(t(vb)[itex,], col = pindex$color_, ...)
  
  #if ( rgl::rgl.useNULL()) rgl::rglwidget() 
  
  invisible(list(v = vb, it = itex))

}

#' @name plot-anglr
#' @export
plot.pointmesh <- function(x,  ..., add = FALSE) {
  if (!"color_" %in% names(x$o)) {
    x$o$color_ <- viridis::viridis(nrow(x$o))
  }
  if (!requireNamespace("rgl", quietly = TRUE))
    stop("rgl required")
  haveZ <- "z_" %in% names(x$v)
  #tt <- th3d()
  
  if (haveZ) {
    vb <- t(cbind(x$v$x_, x$v$y_, x$v$z_))
  } else {
    
    vb <- t(cbind(x$v$x_, x$v$y_, 0))
  }
  vv <- x$v[, "vertex_"]; vv$row_n <- seq(nrow(vv))
  
  pindex <- dplyr::inner_join(dplyr::inner_join(x$o[, c("object_", "color_")], x$b), 
                              x$bXv)
  
  # vindex <- dplyr::inner_join(x$bXv, vv, "vertex_")
  #itex <- t(matrix(vindex$row_n, ncol = 2, byrow = TRUE))
  if (!add & length(rgl::rgl.dev.list()) < 1L) rgl::rgl.clear()
  
  rgl::rgl.points(t(vb), col = pindex$color_, ...)
  
 # if ( rgl::rgl.useNULL()) rgl::rglwidget()
  invisible(list(v = vb, material = list(col = pindex$color_)))
}
