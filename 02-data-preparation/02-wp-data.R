# Create wide format dataset of parties and tags


library(tidyverse)

wp_raw <- read_csv("02-data-preparation/01-wp-infobox.csv")


# Dataset in wide format with tags as variable names ----

ib_out <-
  wp_raw %>%
  select(-source) %>%
  distinct() %>%
  mutate(
    value = 1,
    position = str_replace_all(position, "\\W+", "_")
    ) %>%
  spread(position, value, fill = 0)


write_csv(ib_out, "02-data-preparation/02-wp-data.csv")
