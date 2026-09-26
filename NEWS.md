# flreefs 0.0.0.9000

* Added `reefs`, a snapshot of FWC artificial reef deployments dated
  May 7, 2026, built by `data-raw/reefs.R`.

* Added `fetch_reefs()` for downloading and cleaning the current FWC
  file, with optional on-disk caching.

* Switched the data source from the published Excel list to the FWC
  artificial reef feature service. Adds `material_category`, keeps inch
  marks in `primary_material`, and dates the snapshot from the service
  itself. 17 early deployments the Excel list marks "Pre-1970" have no
  date in the service and now carry a `date_precision` of "unknown".
