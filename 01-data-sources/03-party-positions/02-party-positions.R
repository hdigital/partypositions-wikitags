library(tidyverse)
library(glue)


path_select <- "01-data-sources/03-party-positions/01-sources-select/"


## Party left/right positions

## Read and prepare data ----

pf_core <- read_csv("01-data-sources/01-partyfacts/core-parties.csv", guess_max = 10000)
pf_ext <- read_csv("01-data-sources/01-partyfacts/external-parties.csv", guess_max = 10000)

mp_raw <- read_csv(glue("{path_select}manifesto-rile.csv"))
dalp_raw <- read_csv(glue("{path_select}dalp-positions.csv"))
ches_raw <- read_csv(glue("{path_select}ches-positions.csv"))
wvs_raw <- read_csv(glue("{path_select}wvs-left-right.csv"))


# Add Party Facts ID to source dataset
get_pf_link <- function(dataset) {
  pf_ext %>%
    filter(dataset_key == dataset) %>% 
    select(partyfacts_id, dataset_party_id, name_short)
}


## CHES // Chapel Hill Expert Survey ----

ches_link <- get_pf_link("ches") %>% rename(ches_short = name_short)

ches_pos <- 
  ches_raw %>% 
  select(
    ches_id = party_id,
    ches_left_right = lrgen,    # "overall ideological stance"
    ches_gal_tan = galtan,      # "democratic freedoms and rights -- libertarian/postmaterialist vs. traditional/authoritarian
    ches_economy = lrecon,      #  government role economy (active vs. reduced)
    ches_redistribute = redistribution  # "redistribution of wealth from the rich to the poor"
  ) %>% 
  mutate(ches_id = as.character(ches_id)) %>% 
  left_join(ches_link, by = c("ches_id" = "dataset_party_id")) %>% 
  select(ches_short, everything()) %>%
  distinct(partyfacts_id, .keep_all = TRUE)


## DALP // Kitschelt (2013) ----

# Kitschelt variable selection and renaming -- see also Kitschelt codebook

dalp_link <- get_pf_link("kitschelt") %>% rename(dalp_short = name_short)

dalp_pos <- 
  dalp_raw %>%
  mutate(id = paste(ccodewb, partynum, sep = "-")) %>% 
  select(
    dalp_id = id,
    dalp_left_right = dw,    # "Overall Left-Right Placement"
    dalp_gal_tan = d5,       # "Traditional authority, institutions, and customs"
    dalp_economy = d2,       #  state role economy (major vs. minimal)
    dalp_redistribute = d1,  # "Social spending on the disadvantaged"
    dalp_identity = d4,      # "National identity" (toleration vs. promotion)
    ) %>% 
  left_join(dalp_link, by = c("dalp_id" = "dataset_party_id")) %>% 
  select(dalp_short, everything()) %>%
  distinct(partyfacts_id, .keep_all = TRUE)


## MP // Manifesto Project ----

mp_link <- 
  get_pf_link("manifesto") %>% 
  mutate(dataset_party_id = as.integer(dataset_party_id)) %>% 
  rename(mp_short = name_short)

mp_pos <-
  mp_raw %>%
  select(-date) %>% 
  left_join(mp_link, by = c("party" = "dataset_party_id")) %>% 
  select(mp_id=party, mp_short, mp_left_right=rile, partyfacts_id) %>% 
  distinct(partyfacts_id, .keep_all = TRUE)


## WVS // World Value Survey ----

wvs_link <- 
  get_pf_link("wvs") %>% 
  mutate(dataset_party_id = as.integer(dataset_party_id)) %>% 
  rename(wvs_short = name_short)

wvs_pos <- 
  wvs_raw %>%
  select(wvs_id=party_V228, wvs_left_right=left_right_V95) %>% 
  left_join(wvs_link, by = c("wvs_id" = "dataset_party_id")) %>% 
  select(wvs_short, everything()) %>%
  distinct(partyfacts_id, .keep_all = TRUE)

  
## Final dataset ----

# create vector of Party Facts IDs with party position data
pf_id_to_keep <- 
  pf_ext %>% 
  filter(dataset_key %in% c("ches", "kitschelt", "manifesto", "wvs")) %>% 
  pull(partyfacts_id)

# select Party Facts parties
pos_out <- 
  pf_core %>%
  filter(partyfacts_id %in% pf_id_to_keep) %>% 
  select(country, partyfacts_id, name_short)

# add position data
pos_out <- 
  pos_out %>% 
  left_join(ches_pos) %>% 
  left_join(dalp_pos) %>% 
  left_join(mp_pos) %>% 
  left_join(wvs_pos)

# some clean-up
pos_out <- 
  pos_out %>% 
  mutate(across(where(is.numeric), round, 2)) %>%
  arrange(country, name_short)

write_csv(pos_out, "01-data-sources/03-party-positions/02-party-positions.csv", na = "")


# count observations in final dataset
map_df(pos_out %>% select(ends_with("_id")), ~ sum(! is.na(.)))

