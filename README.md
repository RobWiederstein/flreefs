# flreefs

<!-- badges: start -->
<!-- badges: end -->

flreefs bundles a cleaned snapshot of Florida's artificial reef
deployments, as published by the Florida Fish and Wildlife Conservation
Commission (FWC). The data frame `reefs` carries one row per deployment,
4,548 in all, and `fetch_reefs()` downloads whatever FWC publishes
today.

## Installation

flreefs is not on CRAN. Install the development version from source:

``` r
# install.packages("remotes")
remotes::install_git("https://git.robwiederstein.org/rkw/flreefs")
```

## Usage

``` r
library(flreefs)

str(reefs)

table(reefs$coast, reefs$jurisdiction)
#>
#>            Federal State
#>   Atlantic     758   530
#>   Gulf        1213  2047

sort(table(reefs$material_category), decreasing = TRUE)
#>
#>   Module Concrete   Vessel    Metal     Rock    Other
#>     2006     1448      572      281      161       80
```

Every deployment FWC publishes is kept, including those whose date is
only partly known. The `date_precision` column records how much of the
date FWC captured — `"day"`, `"month"`, `"year"`, `"before"`, or
`"unknown"` — and `deploy_date` is filled in only for `"day"`. Missing
days and months are not invented. See `?reefs` for the full column
reference.

Tonnage recorded as 0 in the source means "not recorded" and is stored
as `NA`. `relief` and `depth` are in feet.

## Data source

Florida Fish and Wildlife Conservation Commission, Division of Marine
Fisheries Management, Artificial Reef Program. Built from layer 12 of the
[Artificial Reef Locations in Florida](https://gis.myfwc.com/mapping/rest/services/Open_Data/Artificial_Reef_Locations_in_Florida/MapServer)
feature service, last edited 2026-05-13. The same deployments are also
distributed as an [Excel list, PDF, shapefile and
KML](https://myfwc.com/fishing/saltwater/artificial-reefs/locate/).

The bundled snapshot carries its own vintage:

``` r
attr(reefs, "snapshot_date")
#> [1] "2026-05-13"
```

Reef material can move, degrade, or become buried, and some historical
positions have never been verified since deployment — see
`location_accuracy`. Acquire the data directly from FWC rather than
second-hand if accuracy matters to you.

This package is not affiliated with or endorsed by FWC.

## License

MIT © Rob Wiederstein
