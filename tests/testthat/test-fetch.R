fake_attributes <- function(...) {
  base <- list(
    DeployID = "XX0001",
    County = "Bay",
    DDate = 20260319L,
    Name = "Test Reef",
    Description = "1 module",
    MatDescrip = "Concrete module (1)",
    MatCat = "Module",
    Tonnage = 7.5,
    Relief = 8,
    Depth = 77,
    Jurisdiction = "State",
    Coast = "Gulf",
    Lat_DM = "30\u00b0 10.108' N",
    Long_DM = "85\u00b0 54.730' W",
    Lat_DD = 30.16846103,
    Long_DD = -85.91216222,
    LocAccuracy = 3L
  )
  replacements <- list(...)
  base[names(replacements)] <- replacements
  n <- max(lengths(base))
  base <- lapply(base, rep_len, length.out = n)
  as.data.frame(base, stringsAsFactors = FALSE)
}

test_that("fetch_reefs rejects non-logical arguments", {
  expect_error(fetch_reefs(cache = "yes"), "must be TRUE or FALSE")
  expect_error(fetch_reefs(refresh = NA), "must be TRUE or FALSE")
})

test_that("clean_reefs rejects a response missing expected fields", {
  x <- fake_attributes()
  x$MatCat <- NULL
  expect_error(clean_reefs(x), "MatCat")
})

test_that("clean_reefs rejects an unrecognized accuracy code", {
  expect_error(
    clean_reefs(fake_attributes(LocAccuracy = 9L)),
    "LocAccuracy"
  )
})

test_that("clean_reefs reads every DDate shape", {
  x <- fake_attributes(
    DeployID = c("A1", "A2", "A3", "A4", "A5"),
    DDate = c(20260319L, 20030900L, 19930000L, 19919999L, 0L)
  )
  out <- clean_reefs(x)
  expect_identical(
    as.character(out$date_precision),
    c("day", "month", "year", "before", "unknown")
  )
  expect_identical(out$deploy_date[1], as.Date("2026-03-19"))
  expect_true(all(is.na(out$deploy_date[-1])))
  expect_identical(out$deploy_year, c(2026L, 2003L, 1993L, NA, NA))
  expect_identical(out$deploy_month, c(3L, 9L, NA, NA, NA))
  expect_identical(out$deploy_before, c(NA, NA, NA, 1991L, NA))
})

test_that("clean_reefs treats a zero tonnage as not recorded", {
  expect_true(is.na(clean_reefs(fake_attributes(Tonnage = 0))$tons))
})

test_that("fetch_reefs returns the same structure as reefs", {
  skip_on_cran()
  skip_if_offline()
  current <- fetch_reefs()
  skip_if(is.null(current), "FWC service unavailable")

  expect_s3_class(current, "data.frame")
  expect_named(current, names(reefs))
  expect_identical(
    vapply(current, function(x) class(x)[1], character(1)),
    vapply(reefs, function(x) class(x)[1], character(1))
  )
  # FWC only adds deployments, so today's data is never smaller.
  expect_gte(nrow(current), nrow(reefs))
})
