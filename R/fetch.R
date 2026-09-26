# Rows per request. The service caps a single response at 2000.
#' @noRd
reef_page_size <- function() 2000L

# Ask the service for one page of attributes.
#' @noRd
reef_page_url <- function(offset) {
  paste0(
    reef_service_url(), "/query",
    "?where=1%3D1&outFields=*&returnGeometry=false",
    "&resultOffset=", offset,
    "&resultRecordCount=", reef_page_size(),
    "&f=json"
  )
}

# Walk the service a page at a time until it stops reporting more rows.
#' @noRd
fetch_reef_pages <- function() {
  pages <- list()
  offset <- 0L
  repeat {
    res <- jsonlite::fromJSON(reef_page_url(offset))
    if (!is.null(res$error)) {
      stop(
        "The FWC service returned an error: ",
        res$error$message,
        call. = FALSE
      )
    }
    rows <- res$features$attributes
    if (is.null(rows) || nrow(rows) == 0L) {
      break
    }
    pages[[length(pages) + 1L]] <- rows
    if (!isTRUE(res$exceededTransferLimit)) {
      break
    }
    offset <- offset + nrow(rows)
  }
  if (length(pages) == 0L) {
    stop("The FWC service returned no rows.", call. = FALSE)
  }
  do.call(rbind, pages)
}

#' Download the current FWC artificial reef data
#'
#' Queries the artificial reef feature service published by the Florida
#' Fish and Wildlife Conservation Commission and cleans it the same way
#' the bundled [reefs] snapshot was built, so the two have identical
#' structure.
#'
#' Use [reefs] for reproducible work: it is fixed at the version shipped
#' with the package. Use `fetch_reefs()` when you need whatever FWC
#' publishes today. FWC adds deployments throughout the year, so the two
#' will differ in row count.
#'
#' The service caps each response at 2,000 rows, so this makes several
#' requests and stitches the pages together.
#'
#' @param cache Logical. `FALSE`, the default, downloads to a temporary
#'   directory that is discarded when the session ends. `TRUE` stores
#'   the download under [tools::R_user_dir()] so later calls, including
#'   calls in later sessions, reuse it.
#' @param refresh Logical. `FALSE`, the default, reuses an existing
#'   download when one is present. `TRUE` downloads again even if a
#'   copy is already there.
#'
#' @return A data frame with the same 21 columns as [reefs], one row per
#'   deployment, sorted by `deploy_id`. If the download fails, `NULL` is
#'   returned invisibly with a message rather than an error, so scripts
#'   can fall back to [reefs].
#'
#' @seealso [reefs] for the bundled snapshot and the column reference.
#'
#' @examples
#' \donttest{
#' current <- fetch_reefs()
#' if (!is.null(current)) {
#'   nrow(current) - nrow(reefs)
#' }
#' }
#' @export
fetch_reefs <- function(cache = FALSE, refresh = FALSE) {
  if (!is.logical(cache) || length(cache) != 1L || is.na(cache)) {
    stop("`cache` must be TRUE or FALSE.", call. = FALSE)
  }
  if (!is.logical(refresh) || length(refresh) != 1L || is.na(refresh)) {
    stop("`refresh` must be TRUE or FALSE.", call. = FALSE)
  }

  dir <- if (cache) tools::R_user_dir("flreefs", "cache") else tempdir()
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  path <- file.path(dir, "reeflocations.json")

  if (!file.exists(path) || refresh) {
    rows <- tryCatch(fetch_reef_pages(), error = function(e) {
      message(
        "Could not reach the FWC reef service at\n  ", reef_service_url(),
        "\n", conditionMessage(e),
        "\nUse the bundled `reefs` data instead."
      )
      NULL
    })
    if (is.null(rows)) {
      return(invisible(NULL))
    }
    jsonlite::write_json(rows, path, na = "null", digits = NA)
  }

  out <- tryCatch(clean_reefs(jsonlite::fromJSON(path)), error = function(e) {
    message(
      "The FWC data downloaded but could not be cleaned:\n  ",
      conditionMessage(e),
      "\nUse the bundled `reefs` data instead."
    )
    NULL
  })
  if (is.null(out)) invisible(NULL) else out
}
