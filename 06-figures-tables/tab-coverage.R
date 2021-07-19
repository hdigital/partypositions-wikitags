## Create a table of party coverage for different datasets


library(tidyverse)
library(glue)


## Get data ----

pos_tags <- read_csv("03-estimation/estimation-results/positions-parties-m2.csv")

path_pf <- "01-data-sources/01-partyfacts/"

pf <- read_csv(glue("{path_pf}core-parties.csv", guess_max = 10000))
pf_dt <- read_csv(glue("{path_pf}external-parties.csv"))
ctry <- read_csv(glue("{path_pf}countries.csv"))

ctry_continent <- ctry %>% select(country, continent)


## Coverage data ----

cv_pf <-
  pf %>%
  filter(is.na(technical)) %>%
  select(partyfacts = partyfacts_id, country, wikipedia) %>%
  left_join(ctry_continent) %>%
  mutate(tags = ifelse(partyfacts %in% pos_tags$partyfacts_id, 1, NA)) %>%
  group_by(continent) %>%
  summarise_all(list(~ is.na(.) %>% `!` %>% as.integer() %>% sum())) %>%
  select(-country)

cv_dt <-
  pf_dt %>%
  filter(dataset_key %in% c("ches", "kitschelt", "manifesto", "wvs")) %>%
  left_join(ctry_continent) %>%
  group_by(continent, dataset_key) %>%
  summarise(n = n()) %>%
  spread(dataset_key, n, fill = 0)

cv <-
  cv_pf %>%
  left_join(cv_dt) %>%
  rbind(., c( "TOTAL", colSums(select_if(., is.numeric)))) %>%
  select(continent:tags, manifesto, wvs, kitschelt, ches)


write_csv(cv, "06-figures-tables/tab-coverage.csv")
