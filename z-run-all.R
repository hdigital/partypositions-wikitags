# run all scripts (R and Python) -- see README.md
# time intense steps (get Wikipedia data, Jags estimation) are optional

library(callr)
library(fs)
library(tidyverse)
# packages required by some scripts: ggrepel jagsUI 


option_update_data <- FALSE
option_run_estimation <- FALSE

# run all R scripts in a folder
rscripts_dir <- function(path) {
  map(dir_ls(path, glob = "*R"), rscript, spinner = TRUE)
}


## Data preparation ----

# get Wikipedia data -- time intense (about 6h)
if(option_update_data) {
  # update Party Facts data -- needs Python and packages
  system("cd 01-data-sources/02-wikipedia/ && python3 z-get-partyfacts-data.py")
  # update Wikipedia data -- needs Python and packages
  system("cd 01-data-sources/02-wikipedia/ && python3 z-run-wikipedia-scripts.py")

  # extract party position from various sources (raw data not in Git)
  if(dir_exists("01-data-sources/03-party-positions/00-sources-raw/")) {
    rscript("01-data-sources/03-party-positions/01-sources-select.R")
  }
  
  # create harmonized party positions for validation
  rscript("01-data-sources/03-party-positions/02-party-positions.R")
}

# create Wikipedia party labels data
rscripts_dir("02-data-preparation")


## Estimation and validation ----

# estimate models (default M2 only) -- time intense (12h) and requiring JAGS
if(option_run_estimation) {
  # model is only estimated if estimation results (*.RData) are removed
  file_delete(dir_ls("03-estimation/estimation-model/", glob = "*.RData"))

  rscripts_dir("03-estimation")
  r(function() rmarkdown::render("03-estimation/03-convergence.Rmd"))
}

# create final dataset with lr-positions for parties and tags
rscripts_dir("04-data-final")

# validate lr-positions with various data sources
r(function() rmarkdown::render("05-validation/validation.Rmd"))


## Figures and tables ----

# create figures and tables
rscripts_dir("06-figures-tables")

# remove Rplots created with print()
if(file_exists("Rplots.pdf")) {
  file_delete("Rplots.pdf")
}


## Data files documentation ----

# get all data files in subfolders
files_data <- 
  dir_info(recurse = TRUE) %>% 
  filter(
    str_detect(path, "(csv|RData|html|zip)$"),
    str_detect(path, "data-files-doc|00-sources-raw|zyx", negate = TRUE)
    ) %>% 
  select(data_file=path, last_modified=modification_time)

# get documentation of datasets
files_docu <- read_csv("data-files-docs.csv")

if(nrow(anti_join(files_data, files_docu)) > 0) {
  cat("\n\nNot all dataset documented\n\n")
  anti_join(files_data, files_docu)
}


## Information session ----

cat("\n\nLast Wikipedia data extraction (needs running Python scripts)")
file.info("01-data-sources/02-wikipedia/wikipedia-data/01-wp-data-json.zip")$mtime
file.info("01-data-sources/02-wikipedia/wikipedia-data/03-infobox-tags.csv")$mtime

cat("\nLast model JAGS estimation (only run if no estimation output exists)\n")
file.info("03-estimation/estimation-model/02-result-m2.RData")$mtime
