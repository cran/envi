#' Ecological niche model using a log relative risk surface
#' 
#' Estimate the ecological niche of a single species with presence/absence data and two covariates. Predict the ecological niche in geographic space.
#'
#' @param obs_locs Input data frame of presence and absence observations with six (6) features (columns): 1) ID, 2) longitude, 3) latitude, 4) presence/absence binary variable, 5) covariate 1 as x-coordinate, 6) covariate 2 as y-coordinate.
#' @param predict Logical. If TRUE, will predict the ecological niche in geographic space. If FALSE (the default), will not predict. 
#' @param predict_locs Input data frame of prediction locations with 4 features (columns): 1) longitude, 2) latitude, 3) covariate 1 as x-coordinate, 4) covariate 2 as y-coordinate. The covariates must be the same as those included in \code{obs_locs}.
#' @param conserve Logical. If TRUE (the default), the ecological niche will be estimated within a concave hull around the locations in \code{obs_locs}. If FALSE, the ecological niche will be estimated within a concave hull around the locations in \code{predict_locs}.
#' @param alpha Numeric. The two-tailed alpha level for the significance threshold (the default is 0.05).
#' @param p_correct Optional. Character string specifying whether to apply a correction for multiple comparisons including a False Discovery Rate \code{p_correct = "FDR"}, a Sidak correction \code{p_correct = "Sidak"}, and a Bonferroni correction \code{p_correct = "Bonferroni"}. If \code{p_correct = "none"} (the default), then no correction is applied.
#' @param cv Logical. If TRUE, will calculate prediction diagnostics using internal k-fold cross-validation. If FALSE (the default), will not. 
#' @param kfold Integer. Specify the number of folds used in the internal cross-validation. The default is 10.
#' @param balance Logical. If TRUE, the prevalence within each k-fold will be 0.50 by undersampling absence locations (assumes absence data are more frequent). If FALSE (the default), the prevalence within each k-fold will match the prevalence in \code{obs_locs}.
#' @param parallel Logical. If TRUE, will execute the function in parallel. If FALSE (the default), will not execute the function in parallel.
#' @param n_core Optional. Integer specifying the number of CPU cores on the current host for parallelization (the default is 2 cores).
#' @param poly_buffer Optional. Specify a custom distance (in the same units as covariates) to add to the window within which the ecological niche is estimated. The default is 1/100th of the smallest range among the two covariates.
#' @param obs_window Optional. Specify a custom window of class 'owin' within which to estimate the ecological niche. The default computes a concave hull around the data specified in \code{conserve}.
#' @param verbose Logical. If TRUE (the default), will print function progress during execution. If FALSE, will not print.
#' @param ... Arguments passed to \code{\link[sparr]{risk}} to select bandwidth, edge correction, and resolution.
#'
#' @details This function estimates the ecological niche of a single species (presence/absence data), or the presence of one species relative to another, using two covariates, will predict the ecological niche into a geographic area and prepare k-fold cross-validation data sets for prediction diagnostics.
#' 
#' The function uses the \code{\link[sparr]{risk}} function to estimate the spatial relative risk function and forces \code{risk(tolerate == TRUE)} in order to calculate asymptotic p-values. The estimated ecological niche can be visualized using the \code{\link{plot_obs}} function.
#' 
#' If \code{predict = TRUE}, this function will predict ecological niche at every location specified with \code{predict_locs} with best performance if \code{predict_locs} are gridded locations in the same study area as the observations in \code{obs_locs} - a version of environmental interpolation. The predicted spatial distribution of the estimated ecological niche can be visualized using the \code{\link{plot_predict}} function.
#' 
#' If \code{cv = TRUE}, this function will prepare k-fold cross-validation data sets for prediction diagnostics. The sample size of each fold depends on the number of folds set with \code{kfold}. If \code{balance = TRUE}, the sample size of each fold will be the frequency of presence locations divided by the number of folds times two. If \code{balance = FALSE}, the sample size of each fold will be the frequency of all observed locations divided by the number of folds. The cross-validation can be performed in parallel if \code{parallel = TRUE} using the \code{\link{future}}, \code{\link{doFuture}}, \code{\link{doRNG}}, and \code{\link{foreach}} packages. Two diagnostics (area under the receiver operating characteristic curve and precision-recall curve) can be visualized using the \code{plot_cv} function.
#' 
#' The \code{obs_window} argument may be useful to specify a 'known' window for the ecological niche (e.g., a convex hull around observed locations).
#' 
#' This function has functionality for a correction for multiple testing. If \code{p_correct = "FDR"}, calculates a False Discovery Rate by Benjamini and Hochberg. If \code{p_correct = "Sidak"}, calculates a Sidak correction. If \code{p_correct = "Bonferroni"}, calculates a Bonferroni correction. If \code{p_correct = "none"} (the default), then the function does not account for multiple testing and uses the uncorrected \code{alpha} level. See the internal \code{pval_correct} function documentation for more details.
#' 
#' @return An object of class 'list'. This is a named list with the following components:
#' 
#' \describe{
#' \item{\code{out}}{An object of class 'list' for the estimated ecological niche.}
#' \item{\code{dat}}{An object of class 'data.frame', returns \code{obs_locs} that are used in the accompanying plotting functions.}
#' \item{\code{p_critical}}{A numeric value for the critical p-value used for significance tests.}
#' }
#' 
#' The returned \code{out} is a named list with the following components:
#' 
#' \describe{
#' \item{\code{obs}}{An object of class 'rrs' for the spatial relative risk.}
#' \item{\code{presence}}{An object of class 'ppp' for the presence locations.}
#' \item{\code{absence}}{An object of class 'ppp' for the absence locations.}
#' \item{\code{outer_poly}}{An object of class 'matrix' for the coordinates of the concave hull around the observation locations.}
#' \item{\code{inner_poly}}{An object of class 'matrix' for the coordinates of the concave hull around the observation locations. Same as \code{outer_poly}.}
#' }
#' 
#' If \code{predict = TRUE}, the returned \code{out} has additional components:
#' 
#' \describe{
#' \item{\code{outer_poly}}{An object of class 'matrix' for the coordinates of the concave hull around the prediction locations.}
#' \item{\code{prediction}}{An object of class 'matrix' for the coordinates of the concave hull around the prediction locations.}
#' }
#' 
#' If \code{cv = TRUE}, the returned object of class 'list' has an additional named list \code{cv} with the following components:
#' 
#' \describe{
#' \item{\code{cv_predictions_rr}}{A list of length \code{kfold} with values of the log relative risk surface at each point randomly selected in a cross-validation fold.}
#' \item{\code{cv_labels}}{A list of length \code{kfold} with a binary value of presence (1) or absence (0) for each point randomly selected in a cross-validation fold.}
#' }
#' 
#' @importFrom concaveman concaveman
#' @importFrom doFuture registerDoFuture
#' @importFrom doRNG %dorng%
#' @importFrom foreach %do% %dopar% foreach setDoPar
#' @importFrom future multisession plan
#' @importFrom grDevices chull
#' @importFrom iterators icount
#' @importFrom pls cvsegments
#' @importFrom sf st_bbox st_buffer st_coordinates st_polygon
#' @importFrom sparr risk
#' @importFrom spatstat.geom owin ppp
#' @importFrom stats na.omit
#' @importFrom terra extract rast values
#' @export
#'
#' @examples
#' if (interactive()) {
#'   set.seed(1234) # for reproducibility
#'
#' # Using the 'bei' and 'bei.extra' data within {spatstat.data}
#' 
#' # Covariate data (centered and scaled)
#'   elev <- spatstat.data::bei.extra[[1]]
#'   grad <- spatstat.data::bei.extra[[2]]
#'   elev$v <- scale(elev)
#'   grad$v <- scale(grad)
#'   elev_raster <- terra::rast(elev)
#'   grad_raster <- terra::rast(grad)
#' 
#' # Presence data
#'   presence <- spatstat.data::bei
#'   spatstat.geom::marks(presence) <- data.frame("presence" = rep(1, presence$n),
#'                                                "lon" = presence$x,
#'                                                "lat" = presence$y)
#'   spatstat.geom::marks(presence)$elev <- elev[presence]
#'   spatstat.geom::marks(presence)$grad <- grad[presence]
#' 
#' # (Pseudo-)Absence data
#'   absence <- spatstat.random::rpoispp(0.008, win = elev)
#'   spatstat.geom::marks(absence) <- data.frame("presence" = rep(0, absence$n),
#'                                               "lon" = absence$x,
#'                                               "lat" = absence$y)
#'   spatstat.geom::marks(absence)$elev <- elev[absence]
#'   spatstat.geom::marks(absence)$grad <- grad[absence]
#' 
#' # Combine into readable format
#'   obs_locs <- spatstat.geom::superimpose(presence, absence, check = FALSE)
#'   obs_locs <- spatstat.geom::marks(obs_locs)
#'   obs_locs$id <- seq(1, nrow(obs_locs), 1)
#'   obs_locs <- obs_locs[ , c(6, 2, 3, 1, 4, 5)]
#'   
#' # Prediction Data
#'   predict_xy <- terra::crds(elev_raster)
#'   predict_locs <- as.data.frame(predict_xy)
#'   predict_locs$elev <- terra::extract(elev_raster, predict_xy)[ , 1]
#'   predict_locs$grad <- terra::extract(grad_raster, predict_xy)[ , 1]
#' 
#' # Run lrren
#'   test_lrren <- lrren(obs_locs = obs_locs,
#'                       predict_locs = predict_locs,
#'                       predict = TRUE,
#'                       cv = TRUE)
#' }
#' 
lrren <- function(obs_locs,
                  predict = FALSE,
                  predict_locs = NULL,
                  conserve = TRUE,
                  alpha = 0.05,
                  p_correct = "none",
                  cv = FALSE,
                  kfold = 10,
                  balance = FALSE,
                  parallel = FALSE,
                  n_core = 2,
                  poly_buffer = NULL,
                  obs_window = NULL,
                  verbose = FALSE, 
                  ...) {

  if (verbose == TRUE) { message("Estimating relative risk surfaces\n") }
  
  match.arg(p_correct, choices = c("none", "FDR", "Sidak", "Bonferroni"))

  # Compute spatial windows
  ## Calculate inner boundary polygon (extent of presence and absence locations in environmental space)
  inner_chull <- concaveman::concaveman(as.matrix(obs_locs[ , 5:6]))
  inner_chull_poly <- sf::st_polygon(list(inner_chull))
  
  if (is.null(poly_buffer)) {
    poly_buffer <- abs(min(diff(sf::st_bbox(inner_chull_poly)[c(1,3)]), diff(sf::st_bbox(inner_chull_poly)[c(2,4)])) / 100)
  }

  # add small buffer around polygon to include boundary points
  inner_chull_poly_buffer <- sf::st_buffer(inner_chull_poly, dist = poly_buffer, byid = TRUE)
  inner_poly <- sf::st_polygon(list(as.matrix(inner_chull_poly_buffer)))

  if (is.null(predict_locs)) {
    outer_chull_poly <- inner_chull_poly_buffer
    outer_poly <- inner_poly
  } else {
    ## Calculate outer boundary polygon (full extent of geographical extent in environmental space)
    if (nrow(predict_locs) > 5000000) { # convex hull
      predict_locs_woNAs <- stats::na.omit(predict_locs)
      outer_chull <- grDevices::chull(x = predict_locs_woNAs[ , 3], y = predict_locs_woNAs[ , 4])
      outer_chull_pts <- predict_locs_woNAs[c(outer_chull, outer_chull[1]), 3:4]
    } else { # concave hull
      outer_chull_pts <- concaveman::concaveman(as.matrix(stats::na.omit(predict_locs[ , 3:4])))
    }
    outer_chull_poly <- sf::st_polygon(list(as.matrix(outer_chull_pts)))
    # add small buffer around polygon to include boundary points
    outer_chull_poly_buffer <- sf::st_buffer(outer_chull_poly, dist = poly_buffer, byid = TRUE)
    outer_poly <- sf::st_polygon(list(as.matrix(outer_chull_poly_buffer)))
  }
  
  if (conserve == FALSE & is.null(predict_locs)) {
    stop("If the argument 'conserve' is FALSE, must specify the argument 'predict_locs'")
  }
  if (conserve == TRUE) { window_poly <- inner_poly } else { window_poly <- outer_poly }

  if (is.null(obs_window)) {
    wind <- spatstat.geom::owin(poly = list(x = rev(sf::st_coordinates(window_poly)[ , 1]),
                                            y = rev(sf::st_coordinates(window_poly)[ , 2])))
  } else { wind <- obs_window }

  # Input Preparation
  ## presence and absence point pattern datasets
  presence_locs <- subset(obs_locs, obs_locs[ , 4] == 1)
  absence_locs <- subset(obs_locs, obs_locs[, 4] == 0)

  ppp_presence <- spatstat.geom::ppp(x = presence_locs[ , 5],
                                     y = presence_locs[ , 6],
                                     window = wind,
                                     checkdup = FALSE)
  ppp_absence <- spatstat.geom::ppp(x = absence_locs[ , 5],
                                    y = absence_locs[ , 6],
                                    window = wind,
                                    checkdup = FALSE)

  # Calculate observed kernel density ratio
  obs <- sparr::risk(f = ppp_presence,
                     g = ppp_absence,
                     tolerate = TRUE,
                     verbose = verbose, 
                     ...)
  bandw <- obs$f$h0
  
  if (p_correct == "none") { 
    p_critical <- alpha 
  } else {
    p_critical <- pval_correct(input = as.vector(t(obs$P$v)),
                               type = p_correct, alpha = alpha)
  }
  
  if (predict == FALSE) {
    output <- list("obs" = obs,
                   "presence" = ppp_presence,
                   "absence" = ppp_absence,
                   "outer_poly" = outer_poly,
                   "inner_poly" = inner_poly)
    } else {
      # Project relative risk surface into geographic space
      if (verbose == TRUE) { message("Predicting area of interest") }

    # Convert to semi-continuous SpatRaster
    rr_raster <- terra::rast(obs$rr)

    # Convert to categorical SpatRaster
    pval_raster <- terra::rast(obs$P)

    # Prediction locations
    extract_points <- cbind(predict_locs[ , 3], predict_locs[ , 4])
    extract_predict <- data.frame("predict_locs" = predict_locs,
                                  "rr" = terra::extract(rr_raster, extract_points)[ , 1],
                                  "pval" = terra::extract(pval_raster, extract_points)[ , 1])

    output <- list("obs" = obs,
                   "presence" = ppp_presence,
                   "absence" = ppp_absence,
                   "outer_poly" = outer_poly,
                   "inner_poly" = inner_poly,
                   "predict" = extract_predict)
    }

  # K-Fold Cross Validation
  if (cv == FALSE) { cv_results <- NULL
  } else {
    
    if (kfold < 1) { 
      stop("The 'kfold' argument must be an integer of at least 1") 
    }
  
    cv_predictions_rank <- list()
    cv_predictions_quant <- list()
    cv_labels <- list()
    cv_pvals <- list()

    ## Partition k-folds
    ### Randomly sample data into k-folds
    if (balance == FALSE) {
      cv_segments <- pls::cvsegments(nrow(obs_locs), kfold)
      cv_seg_cas <- NULL
      cv_seg_con <- NULL
    } else {
      cv_seg_cas <-  pls::cvsegments(nrow(presence_locs), kfold)
      cv_seg_con <-  pls::cvsegments(nrow(absence_locs), kfold)
      cv_segments <- NULL
    }
    
    if (verbose == TRUE) { 
      message("Cross-validation in progress") 
    }

    ### Set function used in foreach
    if (parallel == TRUE) {
      oldplan <- doFuture::registerDoFuture()
      on.exit(with(oldplan, foreach::setDoPar(fun=fun, data=data, info=info)), add = TRUE)
      future::plan(future::multisession, workers = n_core)
      `%fun%` <- doRNG::`%dorng%`
    } else { `%fun%` <- foreach::`%do%` }

    ### Foreach loop
    out_par <- foreach::foreach(k = 1:kfold,
                                kk = iterators::icount(),
                                .combine = comb,
                                .multicombine = TRUE,
                                .init = list(list(), list())
                                ) %fun% {

      # Progress bar
      if (verbose == TRUE) { progBar(kk, kfold) }

      if (balance == FALSE) {
        testing <- obs_locs[cv_segments[k]$V, ]
        training <- obs_locs[-(cv_segments[k]$V), ]
      } else {
        ind <- 1:length(cv_seg_con[k]$V)
        randind <- sample(ind, length(cv_seg_cas[k]$V), replace = FALSE)
        testing_cas <- presence_locs[cv_seg_cas[k]$V, ]
        testing_con <- absence_locs[cv_seg_con[k]$V, ]
        testing_con <- testing_con[randind, ] # undersample the absences for testing
        testing <- rbind(testing_cas,testing_con)
        training_cas <- presence_locs[-(cv_seg_cas[k]$V), ]
        training_con <- absence_locs[-(cv_seg_con[k]$V), ]
        training <- rbind(training_cas,training_con)
      }

      ##### training data
      ###### presence and absence point pattern datasets
      ppp_presence_training <- spatstat.geom::ppp(x = training[ , 5][training[ , 4] == 1],
                                                  y = training[ , 6][training[ , 4] == 1],
                                                  window = wind,
                                                  checkdup = FALSE)
      ppp_absence_training <- spatstat.geom::ppp(x = training[ , 5][training[ , 4] == 0],
                                                 y = training[ , 6][training[ , 4] == 0], 
                                                 window = wind,
                                                 checkdup = FALSE)

      ##### Calculate observed kernel density ratio
      rand_lrr <- sparr::risk(f = ppp_presence_training,
                              g = ppp_absence_training,
                              tolerate = TRUE,
                              verbose = FALSE, 
                              ...)

      ##### Convert to semi-continuous SpatRaster
      rr_raster <- terra::rast(rand_lrr$rr)
      rr_raster[is.na(terra::values(rr_raster))] <- 0 # if NA, assigned null value (log(rr) = 0)

      ##### Predict testing dataset
      extract_testing <- testing[ , 5:6]

      ##### Output for each k-fold
      ###### Record category (semi-continuous) of testing data
      cv_predictions_rr <- terra::extract(rr_raster, extract_testing)[ , 2]
      cv_labels <- testing[ , 4] # Record labels (marks) of testing data

      par_results <- list("cv_predictions_rr" = cv_predictions_rr,
                          "cv_labels"= cv_labels)
      return(par_results)
    }

    if (verbose == TRUE) { message("\nCalculating Cross-Validation Statistics") }
    cv_predictions_rr <- out_par[[1]]
    cv_labels <- out_par[[2]]

    cv_results <- list("cv_predictions_rr" = cv_predictions_rr,
                       "cv_labels" = cv_labels)
    }

  # Output
  lrren_output <- list("out" = output,
                       "cv" = cv_results,
                       "dat" = obs_locs,
                       "p_critical" = p_critical)
}
