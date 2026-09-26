# flreefs: Florida Artificial Reefs R Data Package

## Start of session
- Read TODO.md at the start of every session before doing other work.
- Keep it current: check off finished items and add new ones as found.
- TODO.md is local only. It is in .Rbuildignore and .gitignore.

## Goal
- Build a simple R data package named flreefs.
- Follow Wickham and Bryan, R Packages 2e.
- Provide clean, documented FWC artificial reef deployment data.

## Data Source
- FWC reef deployments: https://myfwc.com/media/mvnhg1ss/reeflocations.xlsx
- About 4,500 rows, one per deployment.
- Read with skip = 2.

## Package Design
- Ship a data snapshot in data/.
- Build it with data-raw/reefs.R and usethis::use_data().
- Provide a function to fetch the latest data from FWC.
- Compress bundled data: LazyDataCompression: xz in DESCRIPTION.
- Keep all rows. Put filtering choices in vignettes.
- Keep Imports minimal. Prefer base R.
- Add CLAUDE.md and .claude/ to .Rbuildignore.

## Fetch Function
- Model on tigris and rnaturalearth.
- Download to tempdir() by default.
- Argument cache = FALSE. If TRUE, use tools::R_user_dir("flreefs", "cache").
- Argument refresh = FALSE. If TRUE, re-download even if cached.
- If cached and refresh = FALSE, read the cached file. Do not download.
- Do not use rappdirs. CRAN prefers tools::R_user_dir().
- Return the cleaned data, same format as the bundled snapshot.

## Style
- Follow the tidyverse style guide: https://style.tidyverse.org
- Format code with styler::style_pkg().
- Check code with lintr::lint_package().
- Use <- for assignment, not =.
- Indent with 2 spaces. No tabs.
- Keep lines under 80 characters.
- Put spaces around operators and after commas.
- Use pkg::fun(). No library() in package code.
- Use TRUE and FALSE, never T and F.
- Use snake_case for all names.
- Use the native pipe |>.
- Prefer simple, readable code.
- The snapshot build script stores its raw download in data-raw/. Never modify it.
- Never put subfolders in data/. R CMD check will warn.
- Download only if the file is missing.
- Use mode = "wb" for binary downloads.

## Data Cleaning
- Read with na = c("", "NA"). Some numeric cells contain the text "NA".
- Clean names at read time: .name_repair = janitor::make_clean_names.
- Resulting names: deploy_id, county, deploy_date, deployment_name, description, primary_material, tons, relief, depth, jurisdiction, coast, lat_dm, long_dm, lat_dd, long_dd, location_accuracy.
- Relief and depth are in feet. Document units in R/data.R.
- deploy_date mixes Excel serial numbers and partial dates.
- Excel date origin is 1899-12-30.
- Partial dates look like 00/00/1993, 09/00/2003, and Pre-1970.
- Keep partial-date rows. Do not invent days or months.
- Add date_precision, deploy_year, deploy_month, and deploy_before columns.
- tons = 0 means not recorded. Convert to NA.
- Large tonnage values are real. Do not treat them as errors.
- Examples: mitigation boulder fields, bridge demolitions, large ships.
- Leave primary_material as-is. It has hundreds of variants.

## CRAN Readiness
- Write all code to pass CRAN submission guidelines.
- devtools::check() must return 0 errors, 0 warnings, 0 notes.
- Examples must run offline. Wrap network examples in \donttest{}.
- Tests that download must use testthat::skip_on_cran() and testthat::skip_if_offline().
- Network functions must fail gracefully with an informative message, not an error.
- Never write to the user's home or working directory. Use tools::R_user_dir() only.
- Keep the installed package under 5 MB.
- Document every exported function and dataset with roxygen2.
- Every exported function needs @return and @examples.
- Cite FWC as the data source in R/data.R and README.
- Use an MIT license: usethis::use_mit_license().
- Keep NEWS.md updated for each version.

## Commands
- Document: devtools::document()
- Test: devtools::test()
- Check: devtools::check()
- Rebuild data snapshot: source("data-raw/reefs.R")
- Style: styler::style_pkg()
- Lint: lintr::lint_package()
