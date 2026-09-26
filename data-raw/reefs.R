# Build the bundled `reefs` snapshot from the FWC artificial reef
# feature service.
#
# Source: Florida Fish and Wildlife Conservation Commission (FWC),
# Artificial Reef Locations in Florida, layer 12 of
# <https://gis.myfwc.com/mapping/rest/services/Open_Data/
#  Artificial_Reef_Locations_in_Florida/MapServer>
#
# Run with: source("data-raw/reefs.R")

# The download and the cleaning both live in R/, so that this snapshot
# and fetch_reefs() can never drift apart. Both are internal.
pkgload::load_all(quiet = TRUE)

raw_file <- "data-raw/reeflocations.json"

# Download only if the file is missing, so rebuilds are reproducible.
# Delete the stored copy by hand to pick up newer FWC data.
if (!file.exists(raw_file)) {
  jsonlite::write_json(
    fetch_reef_pages(), raw_file, na = "null", digits = NA
  )
}

api <- jsonlite::fromJSON(raw_file)
reefs <- clean_reefs(api)

# FWC stamps every feature with the time it was last edited. The most
# recent one dates the snapshot, so the vintage is read from the data
# rather than typed in by hand.
attr(reefs, "snapshot_date") <- as.Date(
  as.POSIXct(max(api$last_edited_date) / 1000, origin = "1970-01-01",
             tz = "UTC")
)

usethis::use_data(reefs, overwrite = TRUE, compress = "xz")
