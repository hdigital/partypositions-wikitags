## Create final dataset of tag left-right positions for users


library(tidyverse)


est_tag_raw <- read_csv("03-estimation/estimation-results/positions-tags-m2.csv")

est_tag <- 
  est_tag_raw %>% 
  rename(
    position = o,
    position_lo = lo,
    position_up = up,
  ) %>% 
  mutate_at(c("position", "position_lo", "position_up"), round, 3)

write_csv(est_tag, "04-data-final/tag-position.csv", na = "")

