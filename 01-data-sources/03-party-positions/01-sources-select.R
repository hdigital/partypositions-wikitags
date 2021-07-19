library(tidyverse)
library(glue)


path_raw <- "01-data-sources/03-party-positions/00-sources-raw/"
path_select <- "01-data-sources/03-party-positions/01-sources-select/"


# CHES // Chapel Hill Expert Survey ----

ches_raw <- read_csv(glue("{path_raw}ches/1999-2019_CHES_dataset_meansv1.csv"))

ches <- 
  ches_raw %>% 
  select(year, party_id, party, lrgen, lrecon, galtan, redistribution) %>% 
  group_by(party_id) %>% 
  filter(year == max(year))

write_csv(ches, glue("{path_select}/ches-positions.csv"))


# DALP // Kitschelt (2013) ----

dalp_raw <- read_csv(glue("{path_raw}dalp/partylevel_20130907-utf8.csv"))

dalp <- dalp_raw %>% select(ccodewb, party, partynum, dw, d2, d5, d1, d4, e2, partysize)

write_csv(dalp, glue("{path_select}/dalp-positions.csv"))


# MP // Manifesto Project ----

# Extract Manifesto Project (CMP) left-right data

mp_raw <- read_csv(glue("{path_raw}manifesto/MPDataset_MPDS2020b.csv"), guess_max = 5000)
mp_sa_raw <- read_csv(glue("{path_raw}manifesto/MPDataset_MPDSSA2020b.csv"))

mp_rile <- 
  mp_raw %>% 
  bind_rows(mp_sa_raw) %>% 
  group_by(party) %>% 
  filter(date == max(date)) %>% 
  select(rile, date)

write_csv(mp_rile, glue("{path_select}/manifesto-rile.csv"))


# WVS // World Value Survey (Wave 6) ----

wvs_raw <- read_rds(glue("{path_raw}wvs-6/F00007762-WV6_Data_R_v20180912.rds"))

wvs_pa <- 
  wvs_raw %>% 
  select(
    party_V228 = V228,
    left_right_V95 = V95
  ) %>% 
  filter(
    party_V228 > 0,
    left_right_V95 > 0
  ) %>% 
  group_by(party_V228) %>% 
  summarise(left_right_V95 = mean(left_right_V95, na.rm = TRUE))

write_csv(wvs_pa, glue("{path_select}/wvs-left-right.csv"))
