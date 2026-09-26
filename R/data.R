#' Florida Artificial Reef Deployments
#'
#' A cleaned snapshot of the artificial reef deployments published by the
#' Florida Fish and Wildlife Conservation Commission (FWC), one row per
#' deployment. Every row FWC publishes is kept, including rows whose
#' deployment date is only partly known.
#'
#' @details
#' FWC records deployment dates at four levels of precision, carried in
#' `date_precision`, and leaves a fifth group undated. `deploy_date` is
#' filled in only when the source gives a full calendar date; missing
#' days and months are not invented. Use `deploy_year`, `deploy_month`,
#' and `deploy_before` to work with the partial dates:
#'
#' \describe{
#'   \item{`"day"`}{Full date. `deploy_date`, `deploy_year`, and
#'     `deploy_month` are all set. 4,226 rows.}
#'   \item{`"month"`}{Month and year known, day unknown. `deploy_date`
#'     is `NA`. 10 rows.}
#'   \item{`"year"`}{Year known only. `deploy_date` and `deploy_month`
#'     are `NA`. 269 rows.}
#'   \item{`"before"`}{Deployed at some point before a stated year,
#'     carried in `deploy_before`. All other date fields are `NA`.
#'     26 rows.}
#'   \item{`"unknown"`}{No deployment date recorded at all. Every date
#'     field is `NA`. 17 rows, all of them early deployments that the
#'     printed FWC lists describe as "Pre-1970".}
#' }
#'
#' A tonnage of 0 in the source means "not recorded" rather than a
#' zero-ton deployment, and is stored as `NA`. Large tonnages are real:
#' they come from mitigation boulder fields, bridge demolitions, and
#' scuttled ships.
#'
#' `relief` and `depth` are in feet.
#'
#' The date FWC last edited any record in this snapshot is stored on the
#' data frame, so the vintage travels with the data:
#' `attr(reefs, "snapshot_date")`.
#'
#' @section Source and cleaning:
#' `reefs` is a cleaned copy of what the FWC feature service returns
#' rather than a reworking of it. All 4,548 deployments are kept and no
#' row is filtered. The build script is `data-raw/reefs.R`, which is not
#' installed with the package; the download and the cleaning it calls are
#' the same internal code [fetch_reefs()] uses, so the snapshot and a
#' live fetch cannot drift apart.
#'
#' The service publishes these fields: `DeployID`, `County`, `DDate`,
#' `DeployDate`, `Description`, `Name`, `MatDescrip`, `MatCat`,
#' `Tonnage`, `Relief`, `Depth`, `Jurisdiction`, `Coast`, `Lat_DM`,
#' `Long_DM`, `Lat_DD`, `Long_DD`, and `LocAccuracy`, alongside internal
#' identifiers and geometry that are not carried over.
#'
#' Four changes are applied:
#' \enumerate{
#'   \item Field names are converted to snake_case, and a few are
#'     renamed for clarity: `Name` becomes `deployment_name`,
#'     `MatDescrip` becomes `primary_material`, `MatCat` becomes
#'     `material_category`, and `Tonnage` becomes `tons`.
#'   \item `DDate`, an integer of the form `yyyymmdd` that uses `00` and
#'     `99` as sentinels for unknown parts, becomes `deploy_date` plus
#'     `date_precision`, `deploy_year`, `deploy_month`, and
#'     `deploy_before`.
#'   \item A recorded tonnage of 0 becomes `NA`, affecting 1,162 rows.
#'   \item `LocAccuracy`, coded 1 to 3, is spelled out as `"Low"`,
#'     `"Medium"`, and `"High"`, matching FWC's own printed lists.
#' }
#'
#' Rows are sorted by `deploy_id`. Nothing else is touched:
#' `primary_material` and the degrees-and-minutes coordinate strings are
#' left exactly as the service returns them.
#'
#' @section Comparison with the published Excel list:
#' FWC also distributes an Excel list of the same deployments. The two
#' agree on every deployment, on all coordinates, and on tonnage, relief,
#' depth, county, coast, jurisdiction, and accuracy. They differ in three
#' small ways, all of which favour the service:
#'
#' \itemize{
#'   \item The service keeps inch marks that the spreadsheet drops, so a
#'     material reads `Piling 3-6" X 12" X 12"` rather than
#'     `Piling 3-6' X 12 X 12`. This affects 24 rows.
#'   \item The service carries `material_category`, which the
#'     spreadsheet has no equivalent for.
#'   \item The spreadsheet records 17 early deployments as `Pre-1970`,
#'     where the service gives no date at all. Those rows appear here
#'     with `date_precision` of `"unknown"`. This is the one respect in
#'     which the spreadsheet holds more information.
#' }
#'
#' @format A data frame with 4,548 rows and 21 variables:
#' \describe{
#'   \item{deploy_id}{Character. FWC deployment identifier, unique across
#'     the file. A two-letter county prefix and a number, such as
#'     `"BA0621"`.}
#'   \item{county}{Character. Florida county responsible for the reef
#'     site. 34 counties appear.}
#'   \item{deploy_date}{Date. Date of deployment, `NA` unless
#'     `date_precision` is `"day"`.}
#'   \item{date_precision}{Factor with levels `"day"`, `"month"`,
#'     `"year"`, `"before"`, and `"unknown"`. How much of the deployment
#'     date FWC recorded.}
#'   \item{deploy_year}{Integer. Year of deployment. `NA` when
#'     `date_precision` is `"before"` or `"unknown"`.}
#'   \item{deploy_month}{Integer, 1 to 12. Month of deployment. `NA`
#'     unless `date_precision` is `"day"` or `"month"`.}
#'   \item{deploy_before}{Integer. Year the deployment is known to
#'     predate. Set only when `date_precision` is `"before"`.}
#'   \item{deployment_name}{Character. Name FWC gives the deployment,
#'     often a memorial name or the name of a scuttled vessel.}
#'   \item{description}{Character. Free-text description of the material
#'     placed, as recorded by FWC.}
#'   \item{primary_material}{Character. FWC's material description, left
#'     exactly as recorded. It is not a controlled vocabulary: roughly
#'     1,500 distinct strings appear. Use `material_category` to group
#'     deployments.}
#'   \item{material_category}{Character. FWC's own grouping of the
#'     material into `"Concrete"`, `"Metal"`, `"Module"`, `"Other"`,
#'     `"Rock"`, or `"Vessel"`.}
#'   \item{tons}{Numeric. Tons of material deployed. `NA` where not
#'     recorded.}
#'   \item{relief}{Numeric. Vertical relief above the seafloor, in feet.}
#'   \item{depth}{Numeric. Water depth at the site, in feet.}
#'   \item{jurisdiction}{Character. `"State"` or `"Federal"` waters.}
#'   \item{coast}{Character. `"Gulf"` or `"Atlantic"`.}
#'   \item{lat_dm}{Character. Latitude in degrees and decimal minutes, as
#'     published, such as `"30° 06.466' N"`. This is the form marine
#'     chartplotters expect.}
#'   \item{long_dm}{Character. Longitude in degrees and decimal minutes,
#'     as published.}
#'   \item{lat_dd}{Numeric. Latitude in decimal degrees.}
#'   \item{long_dd}{Numeric. Longitude in decimal degrees, negative west
#'     of the prime meridian.}
#'   \item{location_accuracy}{Character. FWC's rating of positional
#'     accuracy: `"High"`, `"Medium"`, or `"Low"`. Reef material can
#'     move, degrade, or become buried, and some historical positions
#'     have never been verified.}
#' }
#'
#' @source Florida Fish and Wildlife Conservation Commission, Division of
#'   Marine Fisheries Management, Artificial Reef Program. Built from
#'   layer 12, Artificial Reef Locations in Florida, of
#'   <https://gis.myfwc.com/mapping/rest/services/Open_Data/Artificial_Reef_Locations_in_Florida/MapServer>,
#'   last edited 2026-05-13.
#'
#' @examples
#' str(reefs)
#'
#' attr(reefs, "snapshot_date")
#'
#' table(reefs$coast, reefs$jurisdiction)
#'
#' # What the reefs are made of
#' sort(table(reefs$material_category), decreasing = TRUE)
#'
#' # How much of the deployment date is known
#' table(reefs$date_precision)
#'
#' # Deployments with a full date, most recent first
#' dated <- reefs[reefs$date_precision == "day", ]
#' head(dated[order(dated$deploy_date, decreasing = TRUE), c(
#'   "deploy_id", "deploy_date", "county", "material_category"
#' )])
"reefs"
