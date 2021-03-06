% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/raster.downscale.R
\name{raster.downscale}
\alias{raster.downscale}
\title{Raster Downscale}
\usage{
raster.downscale(
  x,
  y,
  p = NULL,
  n = NULL,
  filename = FALSE,
  scatter = FALSE,
  ...
)
}
\arguments{
\item{x}{Raster class object representing independent variable(s)}

\item{y}{Raster class object representing dependent variable}

\item{p}{Percent sample size}

\item{n}{Fixed sample size}

\item{filename}{Name of output raster}

\item{scatter}{(FALSE/TRUE) Optional scatter plot}

\item{...}{Additional arguments passed to predict}
}
\value{
A list object containing:
\itemize{ 
\item  downscale downscaled raster (omitted if filename is defined)
\item  model     rlm model object 
\item  MSE       Mean Square Error
\item  AIC       Akaike information criterion
}
}
\description{
Downscales a raster to a higher resolution raster using 
             a robust regression
}
\examples{
\donttest{
 library(raster)
 elev <- raster::getData('alt', country='SWZ', mask=TRUE)
 tmax <- raster::getData('worldclim', var='tmax', res=10, 
                         lon=8.25, lat=46.8)
   tmax <- crop(tmax[[1]], extent(elev))
 
 tmax.ds <- raster.downscale(elev, tmax, scatter=TRUE)

 opar <- par(no.readonly=TRUE)
   par(mfrow=c(2,2))
   plot(tmax, main="Temp max")
   plot(elev, main="elevation")
     plot(tmax.ds$downscale, main="Downscaled Temp max")
 par(opar)
}

}
\author{
Jeffrey S. Evans  <jeffrey_evans@tnc.org>
}
