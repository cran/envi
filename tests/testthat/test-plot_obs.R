context("plot_obs")

#####################
# plot_obs testthat #
#####################

# Generate testing data
## Environmental Covariates
library(envi)
library(spatstat.data)
library(spatstat.geom)
library(spatstat.random)
library(terra)
set.seed(1234)

# -------------- #
# Prepare inputs #
# -------------- #

# Using the `bei` and `bei.extra` data from {spatstat.data}

elev <- spatstat.data::bei.extra$elev
grad <- spatstat.data::bei.extra$grad
elev$v <- scale(elev)
grad$v <- scale(grad)
elev_raster <- terra::rast(elev)
grad_raster <- terra::rast(grad)

## Presence Locations
presence <- spatstat.data::bei
spatstat.geom::marks(presence) <- data.frame("presence" = rep(1, presence$n),
                                             "lon" = presence$x,
                                             "lat" = presence$y)
spatstat.geom::marks(presence)$elev <- elev[presence]
spatstat.geom::marks(presence)$grad <- grad[presence]

# (Pseudo-)Absence Locations
set.seed(1234) # for reproducibility
absence <- spatstat.random::rpoispp(0.008, win = elev)
spatstat.geom::marks(absence) <- data.frame("presence" = rep(0, absence$n),
                                            "lon" = absence$x,
                                            "lat" = absence$y)
spatstat.geom::marks(absence)$elev <- elev[absence]
spatstat.geom::marks(absence)$grad <- grad[absence]

# Combine
obs_locs <- spatstat.geom::superimpose(presence, absence, check = FALSE)
obs_locs <- spatstat.geom::marks(obs_locs)
obs_locs$id <- seq(1, nrow(obs_locs), 1)
obs_locs <- obs_locs[ , c(6, 2, 3, 1, 4, 5)]

# Prediction Data
predict_xy <- terra::crds(elev_raster)
predict_locs <- as.data.frame(predict_xy)
colnames(predict_locs) <- c("lon", "lat")
predict_locs$elev <- terra::extract(elev_raster, predict_xy)[ , 1]
predict_locs$grad <- terra::extract(grad_raster, predict_xy)[ , 1]

# Run lrren
test_lrren <- envi::lrren(obs_locs = obs_locs,
                          predict = FALSE,
                          predict_locs = NULL,
                          conserve = TRUE,
                          cv = FALSE,
                          kfold = 10,
                          balance = FALSE,
                          parallel = FALSE,
                          n_core = NULL,
                          poly_buffer = NULL,
                          obs_window = NULL,
                          verbose = FALSE)


test_that("plot_obs throws error with invalid arguments", {
  
  # plot_obs without lrren output
  expect_error(
    plot_obs(input = NULL,
             plot_cols = c("#8b3a3a", "#cccccc", "#0000cd"),
             alpha = 0.05)
    )
  
  # incorrect alpha
  expect_error(
    plot_obs(input = test_lrren,
             plot_cols = c("#8b3a3a", "#cccccc", "#0000cd"),
             alpha = 0)
  )
  
  # not three colors
  expect_error(
    plot_obs(input = test_lrren,
             plot_cols = c("#8b3a3a", "#cccccc"),
             alpha = 0.05)
  )
}
) 

test_that("plot_obs works", {
  skip_on_cran()
  expect_silent(
    plot_obs(input = test_lrren,
             plot_cols = c("#8b3a3a", "#cccccc", "#0000cd"),
             alpha = 0.05)
  )
}
)
