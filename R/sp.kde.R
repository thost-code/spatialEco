#' @title Spatial kernel density estimate
#' @description A weighted or unweighted Gaussian Kernel Density estimate 
#'              for spatial data
#'
#' @param x             sp SpatialPointsDataFrame object
#' @param y             Optional values, associated with x coordinates, 
#'                      to be used as weights
#' @param bw            Distance bandwidth of Gaussian Kernel, must be units 
#'                      of projection
#' @param newdata       A Rasterlayer, any sp class object or c[xmin,xmax,ymin,ymax] 
#'                      vector to estimate the kde extent
#' @param nr            Number of rows used for creating grid. If not defined a value 
#'                      based on extent or existing raster will be used
#' @param nc            Number of columns used for creating grid. If not defined a value 
#'                      based on extent or existing raster will be used
#' @param standardize   Standardize results to 0-1 (FALSE/TRUE)
#' @param scale.factor  Optional numeric scaling factor for the KDE (eg., 10000), to 
#'                      account for small estimate values
#' @param mask          (TRUE/FALSE) mask resulting raster if newdata is provided
#'
#' @return  Raster class object containing kernel density estimate 
#'
#' @author Jeffrey S. Evans  <jeffrey_evans@@tnc.org>
#'
#' @examples
#' \donttest{ 
#'  library(sp)
#'  library(raster)
#'    data(meuse)
#'    coordinates(meuse) <- ~x+y
#'  			
#'  # Unweighted KDE (spatial locations only)				
#'  pt.kde <- sp.kde(x = meuse, bw = 1000, standardize = TRUE, 
#'                   nr=104, nc=78, scale.factor = 10000 )
#'  
#'  # Plot results
#'    plot(pt.kde, main="Unweighted kde")
#'      points(meuse, pch=20, col="red") 
#'  
#'  #### Using existing raster(s) to define grid ####
#'
#'  # Weighted KDE using cadmium and extent with row & col to define grid
#'  e <- c(178605, 181390, 329714, 333611) 
#'  cadmium.kde <- sp.kde(x = meuse, y = meuse$cadmium, bw = 1000,  
#'                        nr = 104, nc = 78, newdata = e, 
#'  					  standardize = TRUE, 
#'  					  scale.factor = 10000  )
#'  plot(cadmium.kde)
#'    points(meuse, pch=19)
#'   			
#'  # Weighted KDE using cadmium and raster object to define grid
#'  r <- raster::raster(raster::extent(c(178605, 181390, 329714, 333611)),
#'                      nrow=104, ncol=78)
#'    r[] <- rep(1,ncell(r))
#'  cadmium.kde <- sp.kde(x = meuse, y = meuse$cadmium, bw = 1000,  
#'                        newdata = r, standardize = TRUE, 
#'  					  scale.factor = 10000  )
#'  plot(cadmium.kde)
#'    points(meuse, pch=19)
#'   			
#'  # Weighted KDE using cadmium and SpatialPixelsDataFrame object to define grid
#'  data(meuse.grid)
#'  coordinates(meuse.grid) = ~x+y
#'  proj4string(meuse.grid) <- CRS("+init=epsg:28992")
#'  gridded(meuse.grid) = TRUE
#'  cadmium.kde <- sp.kde(x = meuse, y = meuse$cadmium, bw = 1000,  
#'                        newdata = meuse.grid, standardize = TRUE, 
#'  					  scale.factor = 10000  )
#'  plot(cadmium.kde)
#'    points(meuse, pch=19)
#' }
#'
#' @export
sp.kde <- function(x, y = NULL, bw = NULL, newdata = NULL, nr = NULL, nc = NULL,  
                   standardize = FALSE, scale.factor = NULL, mask = TRUE) {
  # if(class(x) == "sf") { x <- as(x, "Spatial") }
  if(is.null(bw)){ 
    bw <- c(MASS::bandwidth.nrd(sp::coordinates(x)[,1]), 
	        MASS::bandwidth.nrd(sp::coordinates(x)[,2]))
	  message("Using", bw, "for bandwidth", "\n")
  } else {
    bw <- c(bw,bw)
  }
      if(is.null(scale.factor)) scale.factor = 1  
    if(!is.null(nr) & !is.null(nr)) { n = c(nr, nc) } else { n = NULL }   
  if(is.null(newdata)) { 
    newdata <- as.vector(raster::extent(x))
      message("Using extent of x to define grid")	
  }
  if(!is.null(newdata)) {
    if( class(newdata) == "numeric") {
      if(length(newdata) != 4) stop("Need xmin, xmax, ymin, ymax bounding coordinates")
	    if(is.null(n)) {
	      ext <- raster::raster(raster::extent(newdata))
          n <- c(raster::nrow(ext), raster::ncol(ext))		
		    warning(paste0("defaulting to ", "nrow=", raster::nrow(ext), 
		  	      " & ", " ncol=", raster::ncol(ext)))
        }
      newdata <- raster::raster(raster::extent(newdata), nrow=n[1], ncol=n[2])		
	    newdata[] <- rep(1, raster::ncell(newdata)) 	
    } else if(class(newdata) == "RasterLayer") { 	  
	  n = c(raster::nrow(newdata), raster::ncol(newdata))
        message("using existing raster dimensions to define grid")		  
    } else if(class(newdata) == "SpatialPixelsDataFrame" | class(newdata) == "SpatialGridDataFrame") {
	  newdata <- raster::raster(newdata, 1)
	    n = c(raster::nrow(newdata), raster::ncol(newdata))
          message("using existing raster dimensions to define grid")		
    }
  }	
  #### weighted kde function, modification of MASS::kde2d 
    fhat <- function (x, y, h, w, n = 25, lims = c(range(x), range(y))) {
      nx <- length(x)
        if (length(y) != nx) 
            stop("data vectors must be the same length")
        if (length(w) != nx & length(w) != 1) 
            stop("weight vectors must be 1 or length of data")
        if (missing(h)) { 
          h <- c(MASS::bandwidth.nrd(x), MASS::bandwidth.nrd(y))
        } else { 
	      h <- rep(h, length.out = 2L)
	    }	
      if (any(h <= 0)) stop("bandwidths must be strictly positive")
        if (missing(w)) { w <- numeric(nx) + 1 }
	  gx <- seq(lims[1], lims[2], length = n[1])
      gy <- seq(lims[3], lims[4], length = n[2])
            h <- h/4
          ax <- outer(gx, x, "-") / h[1]
        ay <- outer(gy, y, "-") / h[2]
      z <- ( matrix(rep(w, n[1]), nrow = n[1], ncol = nx, byrow = TRUE) * 
             matrix(stats::dnorm(ax), n[1], nx) ) %*% t(matrix(stats::dnorm(ay), n[2], nx)) /
	        ( sum(w) * h[1] * h[2] )
      return(list(x = gx, y = gy, z = z))
    }
  if(!is.null(y)) {
    message("\n","calculating weighted kde","\n")
    k  <- fhat(sp::coordinates(x)[,1], sp::coordinates(x)[,2], w = y, 
	           h = bw, n = n, lims = as.vector(raster::extent(newdata)) )
  } else {
	message("\n","calculating unweighted kde","\n")
	k <- MASS::kde2d(sp::coordinates(x)[,1], sp::coordinates(x)[,2], h = bw, 
	                 n = n, lims = as.vector(raster::extent(newdata)) )
  }
  k$z <- k$z * scale.factor	
	if( standardize == TRUE ) { k$z <- (k$z - min(k$z)) / (max(k$z) - min(k$z)) }		
    kde.est <- raster::raster(sp::SpatialPixelsDataFrame(sp::SpatialPoints(expand.grid(k$x, k$y)), 
	                          data.frame(kde = as.vector(array(k$z,length(k$z))))))
      if(is.null(newdata) == FALSE & mask == TRUE) {
	    kde.est <- raster::mask(raster::resample(kde.est, newdata), newdata) 
	  }
    sp::proj4string(kde.est) <- sp::proj4string(x)  
  return( kde.est )  
}  
