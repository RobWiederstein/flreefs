test_that("reefs has rows", {
  expect_gt(nrow(reefs), 0)
})

test_that("deploy_month is a calendar month or NA", {
  months <- reefs$deploy_month[!is.na(reefs$deploy_month)]
  expect_true(is.integer(reefs$deploy_month))
  expect_identical(sort(unique(setdiff(months, 1:12))), integer(0))
})

test_that("deploy_month is missing exactly where it should be", {
  # Known for "day" and "month" precision, unknowable for the other two.
  known <- reefs$date_precision %in% c("day", "month")
  expect_false(any(is.na(reefs$deploy_month[known])))
  expect_true(all(is.na(reefs$deploy_month[!known])))
})
