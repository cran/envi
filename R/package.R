#' The envi Package: Environmental Interpolation using Spatial Kernel Density Estimation
#'
#' Estimates an ecological niche model using occurrence data, covariates, and kernel density-based estimation methods.
#'
#' @details For a single species with presence and absence data, the 'envi' package uses the spatial relative risk function estimated using the \code{\link{sparr}} package. Details about the \code{\link{sparr}} package methods can be found in the tutorial: Davies et al. (2018) \doi{10.1002/sim.7577}. Details about kernel density estimation can be found in J. F. Bithell (1990) \doi{10.1002/sim.4780090616}. More information about relative risk functions using kernel density estimation (KDE) can be found in J. F. Bithell (1991) \doi{10.1002/sim.4780101112}.
#' 
#' This package provides a function to estimate the ecological niche for a single species with presence and absence data. The 'envi' package also provides some sensitivity and visualization tools for the estimated ecological niche, its predicted spatial distribution, and prediction diagnostics. Various options for the correction of multiple testing are available. 
#' 
#' Key content of the 'envi' package include:\cr
#' 
#' \bold{Ecological Niche Model}
#' 
#' \code{\link{lrren}} Estimates the ecological niche for a single species with presence/absence data, two covariates, and the spatial relative risk function. Provide functionality to predict the spatial distribution of the estimated ecological niche in geographic space and prepare internal k-fold cross-validation data.
#' 
#' \bold{Sensitivity Analysis}
#' 
#' \code{\link{perlrren}} Iteratively estimates the ecological niche for a single species with spatially perturbed ("jittered") presence/absence data, two covariates, and the spatial relative risk function. Various radii for the spatial perturbation can be specified.
#' 
#' \bold{Data Visualization}
#' 
#' \code{\link{plot_obs}} Visualizes the \code{\link{lrren}} output, specifically the estimated ecological niche in a space with dimensions as the two specified covariates in the model.
#' 
#' \code{\link{plot_predict}} Visualizes the \code{\link{lrren}} output, specifically the predicted spatial distribution of the ecological niche.
#' 
#' \code{\link{plot_cv}} Visualizes the \code{\link{lrren}} output, specifically two prediction diagnostics (area under the receiver operating characteristic curve and precision-recall curve).
#' 
#' \code{\link{plot_perturb}} Visualizes the \code{\link{perlrren}} output, specifically four summary statistics of the iterations, including mean log relative risk, standard deviation of the log relative risk, mean p-value, and proportion of iterations the p-value was significant based on an alpha-level threshold. It also can predict the spatial distribution of the summary statistics.
#' 
#' @name envi-package
#' @aliases envi-package envi 
#' @docType package
#' 
#' @section Dependencies: The 'envi' package relies heavily upon \code{\link{sparr}}, \code{\link{spatstat.geom}}, \code{\link{sf}}, and \code{\link{terra}}. For a single species (presence/absence data), the spatial relative risk function uses the \code{\link[sparr]{risk}} function. Cross-validation is can be performed in parallel using the \code{\link{future}}, \code{\link{doFuture}}, \code{\link{doRNG}}, and \code{\link{foreach}} packages. Spatial perturbation is performed using the \code{\link[spatstat.geom]{rjitter}} function. Basic visualizations rely on the \code{\link[spatstat.geom]{plot.ppp}} and \code{\link[fields]{image.plot}} functions.
#' 
#' @author Ian D. Buller\cr \emph{Social & Scientific Systems, Inc., a division of DLH Corporation, Silver Spring, Maryland, USA (current); Occupational and Environmental Epidemiology Branch, Division of Cancer Epidemiology and Genetics, National Cancer Institute, National Institutes of Health, Rockville, Maryland, USA (former); Environmental Health Sciences, James T. Laney School of Graduate Studies, Emory University, Atlanta, Georgia, USA (original)}\cr
#' 
#' Maintainer: I.D.B. \email{ian.buller@@alumni.emory.edu}
#'
#' @keywords package
NULL

#' @importFrom concaveman concaveman
#' @importFrom cvAUC ci.cvAUC cvAUC
#' @importFrom doFuture registerDoFuture
#' @importFrom doRNG %dorng%
#' @importFrom fields image.plot
#' @importFrom foreach %do% %dopar% foreach setDoPar
#' @importFrom future multisession plan
#' @importFrom graphics abline layout legend lines mtext par plot plot.new title
#' @importFrom grDevices chull colorRampPalette
#' @importFrom iterators icount
#' @importFrom pls cvsegments
#' @importFrom ROCR performance prediction
#' @importFrom sf st_bbox st_buffer st_coordinates st_polygon
#' @importFrom spatstat.geom as.solist im.apply marks owin pixellate plot.ppp ppp rjitter setmarks superimpose
#' @importFrom stats median na.omit sd
#' @importFrom terra crds crs image project rast res classify values
NULL
