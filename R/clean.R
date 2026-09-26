# The FWC ArcGIS feature layer behind the reef data.
#' @noRd
reef_service_url <- function() {
  paste0(
    "https://gis.myfwc.com/mapping/rest/services/Open_Data/",
    "Artificial_Reef_Locations_in_Florida/MapServer/12"
  )
}

# Fields taken from the service, mapped to the names used in `reefs`.
# `DDate` is consumed by the date parsing and does not survive.
#' @noRd
reef_fields <- function() {
  c(
    "DeployID" = "deploy_id",
    "County" = "county",
    "DDate" = "ddate",
    "Name" = "deployment_name",
    "Description" = "description",
    "MatDescrip" = "primary_material",
    "MatCat" = "material_category",
    "Tonnage" = "tons",
    "Relief" = "relief",
    "Depth" = "depth",
    "Jurisdiction" = "jurisdiction",
    "Coast" = "coast",
    "Lat_DM" = "lat_dm",
    "Long_DM" = "long_dm",
    "Lat_DD" = "lat_dd",
    "Long_DD" = "long_dd",
    "LocAccuracy" = "location_accuracy"
  )
}

# FWC's positional accuracy codes. Verified against the published Excel
# list, which spells the same values out in words.
#' @noRd
reef_accuracy <- function() {
  c("1" = "Low", "2" = "Medium", "3" = "High")
}

#' Clean a page of FWC reef attributes
#'
#' Turns the attribute table returned by the FWC feature service into the
#' form documented in [reefs]. Kept separate from the download so that
#' [fetch_reefs()] and the bundled snapshot are built by the same code.
#'
#' @param x Data frame of attributes as returned by the service.
#' @return A data frame with 21 columns. See [reefs].
#' @noRd
clean_reefs <- function(x) {
  wanted <- names(reef_fields())
  absent <- setdiff(wanted, names(x))
  if (length(absent) > 0) {
    stop(
      "The FWC service did not return the expected fields.\n",
      "  missing: ", paste(absent, collapse = ", "),
      call. = FALSE
    )
  }
  x <- x[, wanted, drop = FALSE]
  names(x) <- unname(reef_fields())

  # DDate is an integer yyyymmdd with sentinels for the unknown parts:
  #   20260319  full date
  #   20030900  month and year known, day unknown
  #   19930000  year known only
  #   19919999  deployed at some point before that year
  #          0  no date recorded at all
  # Partial dates are kept. Missing days and months are never invented.
  d <- as.integer(x$ddate)
  yy <- d %/% 10000L
  mm <- (d %/% 100L) %% 100L
  dd <- d %% 100L

  is_unknown <- d == 0L
  is_before <- !is_unknown & mm == 99L & dd == 99L
  is_year <- !is_unknown & mm == 0L & dd == 0L
  is_month <- !is_unknown & !is_before & mm != 0L & dd == 0L
  is_day <- !is_unknown & !is_before & mm != 0L & dd != 0L

  unmatched <- !(is_unknown | is_before | is_year | is_month | is_day)
  if (any(unmatched)) {
    stop(
      "Unrecognized DDate value: ",
      paste(unique(d[unmatched]), collapse = ", "),
      call. = FALSE
    )
  }
  if (any(!mm[is_month | is_day] %in% 1:12)) {
    stop("DDate contains a month outside 1 to 12.", call. = FALSE)
  }

  date_precision <- rep(NA_character_, nrow(x))
  date_precision[is_day] <- "day"
  date_precision[is_month] <- "month"
  date_precision[is_year] <- "year"
  date_precision[is_before] <- "before"
  date_precision[is_unknown] <- "unknown"

  deploy_date <- rep(as.Date(NA), nrow(x))
  deploy_date[is_day] <- as.Date(sprintf(
    "%04d-%02d-%02d", yy[is_day], mm[is_day], dd[is_day]
  ))

  deploy_year <- rep(NA_integer_, nrow(x))
  deploy_year[is_day | is_month | is_year] <- yy[is_day | is_month | is_year]

  deploy_month <- rep(NA_integer_, nrow(x))
  deploy_month[is_day | is_month] <- mm[is_day | is_month]

  deploy_before <- rep(NA_integer_, nrow(x))
  deploy_before[is_before] <- yy[is_before]

  x$deploy_date <- deploy_date
  x$date_precision <- factor(
    date_precision,
    levels = c("day", "month", "year", "before", "unknown")
  )
  x$deploy_year <- deploy_year
  x$deploy_month <- deploy_month
  x$deploy_before <- deploy_before

  # A recorded 0 means "not recorded", not a zero-ton deployment.
  x$tons[!is.na(x$tons) & x$tons == 0] <- NA_real_

  # FWC codes accuracy 1 to 3. Spell it out, as the Excel list does.
  codes <- as.character(x$location_accuracy)
  seen <- unique(codes[!is.na(codes)])
  unknown_codes <- setdiff(seen, names(reef_accuracy()))
  if (length(unknown_codes) > 0) {
    stop(
      "Unrecognized LocAccuracy code: ",
      paste(unknown_codes, collapse = ", "),
      call. = FALSE
    )
  }
  x$location_accuracy <- unname(reef_accuracy()[codes])

  # All rows are kept. Filtering choices belong in vignettes, not here.
  out <- x[, c(
    "deploy_id", "county", "deploy_date", "date_precision", "deploy_year",
    "deploy_month", "deploy_before", "deployment_name", "description",
    "primary_material", "material_category", "tons", "relief", "depth",
    "jurisdiction", "coast", "lat_dm", "long_dm", "lat_dd", "long_dd",
    "location_accuracy"
  )]
  out <- out[order(out$deploy_id), , drop = FALSE]
  row.names(out) <- NULL
  as.data.frame(out, stringsAsFactors = FALSE)
}
