## Create final dataset of party left-right positions for users


library(tidyverse)
library(glue)


## Read data ----

pf_raw <- read_csv("01-data-sources/01-partyfacts/core-parties.csv", guess_max = 10000)
pf_ctry_raw <- read_csv("01-data-sources/01-partyfacts/countries.csv")
wp_raw <- read_csv("02-data-preparation/01-wp-infobox.csv")
est_pa_raw <- read_csv("03-estimation/estimation-results/positions-parties-m2.csv")
est_tag_raw <- read_csv("03-estimation/estimation-results/positions-tags-m2.csv")


## Data clean-up ----

est_pa <-
  est_pa_raw %>%
  rename(
    position = x,
    position_lo = lo,
    position_up = up,
  ) %>%
  mutate_at(c("position", "position_lo", "position_up"), round, 3)


clean_ideology <-  function(.x) str_replace_all(.x, "[^\\p{L}]", " ")

wp <-
  wp_raw %>%
  mutate(
    tag_ignore = if_else(
      source == "ideology" & ! clean_ideology(position) %in% clean_ideology(est_tag_raw$ideology), 1, 0
      ),
    position = ifelse(tag_ignore, glue("[ {position} ]"), position)
    )


## Table with parties and tags ----

pf_country <- pf_ctry_raw %>% select(country, country_name=name, continent)

# add continent to Party Facts data
pf_pa <-
  pf_raw %>%
  filter(is.na(technical)) %>%
  left_join(pf_country, by = "country") %>%
  select(country:wikipedia, country_name, continent,
         -new, -technical, -name_other) %>%
  mutate(
  wikipedia = ifelse(is.na(wikipedia), 0, 1),
  year_last = ifelse(is.na(year_last), 2018, year_last),
  years = year_last - year_first
  )

pa_tags <-
  wp %>%
  group_by(partyfacts_id, source) %>%
  summarise(tags = paste(position, collapse = " // ")) %>%
  spread(source, tags) %>%
  select(partyfacts_id, tags_position = position, tags_ideology = ideology)

pa_tags_count <-
  wp %>%
  count(partyfacts_id, name = "tags")

pa_tags_used_count <-
  wp %>%
  filter(tag_ignore == 0) %>%
  count(partyfacts_id, name = "tags_used")


## Final dataset ----

pa <-
  pf_pa %>%
  select(partyfacts_id, country, name_short) %>%
  left_join(est_pa) %>%
  left_join(pa_tags_count) %>%
  left_join(pa_tags_used_count) %>%
  left_join(pa_tags, by = "partyfacts_id") %>%
  left_join(pf_pa %>% select(-country, -name_short)) %>%
  mutate_at(c("tags", "tags_used"), ~ ifelse(is.na(.x), 0, .x))


## Results into file ----

write_csv(pa, "04-data-final/party-position-tags.csv", na = "")
