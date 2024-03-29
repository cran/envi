#' Visualizations for an estimated ecological niche in covariate space
#' 
#' Create multiple plots of output from the \code{\link{lrren}} function, specifically for the observation data and estimated ecological niche. 
#' 
#' @param input An object of class 'list' from the \code{\link{lrren}} function.
#' @param plot_cols Character string of length three (3) specifying the colors for plotting: 1) presence, 2) neither, and 3) absence. The default colors in hex are \code{c("#8B3A3A", "#CCCCCC", "#0000CD")} or \code{c("indianred4", "grey80", "blue3")}.
#' @param alpha Optional, numeric. The two-tailed alpha level for significance threshold (default is the \code{p_critical} value imported from \code{input}).
#' @param lower_lrr Optional, numeric. Lower cut-off value for the log relative risk value in the color key (typically a negative value). The default is no limit, and the color key will include the minimum value of the log relative risk surface. 
#' @param upper_lrr Optional, numeric. Upper cut-off value for the log relative risk value in the color key (typically a positive value). The default is no limit, and the color key will include the maximum value of the log relative risk surface.
#' @param digits Optional, integer. The number of significant digits for the color key labels using the \code{\link[base]{round}} function (default is 1).
#' @param ... Arguments passed to \code{\link[spatstat.geom]{plot.ppp}} and \code{\link[fields]{image.plot}} for additional graphical features.
#'
#' @return This function produces three plots in a two-dimensional space where the axes are the two specified covariates: 1) observation locations by group, 2) log relative risk surface, and 3) significant p-value surface. 
#' 
#' @importFrom fields image.plot
#' @importFrom graphics par
#' @importFrom spatstat.geom plot.ppp setmarks superimpose
#' @importFrom terra rast values
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
#' # Run lrren
#'   test_lrren <- lrren(obs_locs = obs_locs,
#'                       cv = FALSE)
#'                       
#' # Run plot_obs   
#'   plot_obs(input = test_lrren)
#' }
#' 
plot_obs <- function(input,
                     plot_cols = c("#8B3A3A", "#CCCCCC", "#0000CD"),
                     alpha = input$p_critical,
                     lower_lrr = NULL,
                     upper_lrr = NULL,
                     digits = 1,
                     ...) {
  
  if (alpha >= 1 | alpha <= 0) {
    stop("The argument 'alpha' must be a numeric value between 0 and 1")
  }
  
  if (length(plot_cols) != 3) { 
    stop("The argument 'plot_cols' must have 3 colors")
  }

  op <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(op))
  graphics::par(pty = "s")
  names_obs <- names(input$dat)
  presence <- spatstat.geom::setmarks(input$out$presence, "presence")
  absence <-  spatstat.geom::setmarks(input$out$absence, "absence")
  dat <- spatstat.geom::superimpose(absence, presence, check = FALSE)

  # Plot 1: Locations
  p1 <- spatstat.geom::plot.ppp(dat,
                                pch = 1,
                                cex = 0.8,
                                cols = c(plot_cols[3], plot_cols[1]),
                                leg.side = "bottom",
                                leg.args = list(cex.axis = 0.9, cex = 1, pch = c(1,1)),
                                main = "locations",
                                main.panel = "",
                                xlab = names_obs[5],
                                ylab = names_obs[6],
                                axes = TRUE,
                                ann = TRUE,
                                ...)

  # Plot 2: log relative risk
  rrp <- div_plot(input = input$out$obs$rr,
                  cols = plot_cols,
                  midpoint = 0,
                  thresh_low = lower_lrr,
                  thresh_up = upper_lrr,
                  digits = digits)

  p2 <- spatstat.geom::plot.ppp(dat,
                                cols = c("transparent", "transparent"),
                                leg.side = "bottom",
                                leg.args = list(annotate = FALSE),
                                main = "log relative risk",
                                xlab = names_obs[5],
                                ylab = names_obs[6],
                                axes = TRUE,
                                ann = TRUE,
                                ...)
  fields::image.plot(rrp$v,
                     add = TRUE,
                     breaks = rrp$breaks,
                     col = rrp$cols,
                     legend.mar = 3.1,
                     axis.args = list(at = rrp$at,
                                      las = 0,
                                      labels = rrp$labels,
                                      cex.axis = 0.67))

  # Plot 3: Significant p-values
  pvalp <- terra::rast(input$out$obs$P)  # create raster
  terra::values(pvalp) <- cut(terra::values(pvalp),
                              breaks = c(-Inf, alpha / 2, 1 - alpha / 2, Inf),
                              right = FALSE)
  
  if (all(terra::values(pvalp)[!is.na(terra::values(pvalp))] == 2)) {
    pcols <- plot_cols[2]
    brp <- c(1, 3)
    atp <- 2
    labp <- "insignificant"
  } else {
    pcols <- plot_cols
    brp <- c(1, 1.67, 2.33, 3)
    atp <- c(1.33, 2, 2.67)
    labp <- c("presence", "insignificant", "absence")
  }

  p3 <- spatstat.geom::plot.ppp(dat,
                                cols = c("transparent", "transparent"),
                                leg.side = "bottom",
                                leg.args = list(annotate = FALSE),
                                xlab = names_obs[5],
                                ylab = names_obs[6],
                                axes = TRUE,
                                ann = TRUE,
                                main = paste("significant p-values\nalpha =", formatC(alpha, format = "e", digits = 2), sep = " "),
                                ...)
  fields::image.plot(pvalp,
                     add = TRUE,
                     breaks = brp,
                     col = pcols,
                     legend.mar = 3.1,
                     axis.args = list(at = atp,
                                      las = 0,
                                      labels = labp,
                                      cex.axis = 0.67))
}
