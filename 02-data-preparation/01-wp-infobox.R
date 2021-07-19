## Create a tag dataset from Wikipedia information 
## Clean up tag names, some harmonization, keep only tags used twice.


library(tidyverse)


n_min <- 2  # minimal number of tag usage in Wikipedia data

# read Wikipedia data
wp_raw <- read_csv(
  "01-data-sources/02-wikipedia/wikipedia-data/03-infobox-tags.csv"
)


## Check subsection links ----

tag_sec <- 
  wp_raw %>% 
  filter(str_detect(link, fixed('#'))) %>% 
  mutate(link = str_remove(link, '.+#')) %>% 
  count(link) %>% 
  arrange(-n)

print(paste("Number of links to subsections: ", sum(tag_sec$n)))
tag_sec %>% top_n(5)  


## Create tag dataset ----

lr_tags <- c(
  "far-left", 
  "left-wing", 
  "centre-left", 
  "centre-right", 
  "right-wing", 
  "far-right"
)

wp <- 
  wp_raw %>% 
  select(partyfacts_id, source = field, position = page) %>% 
  mutate(
    position = tolower(position),
    position = str_replace_all(position, "–", "-"),   # en-dash to hyphen
    position = str_remove(position, " \\(politics\\)$"),
    position = ifelse(
      position %in% paste(lr_tags, "politics"), 
      str_remove(position, " politics"),
      position
      ),
    position = str_replace(position, "^centrism$", "centre")
  ) %>% 
  filter(! is.na(position)) %>% 
  distinct()

tag_count <- 
  wp %>% 
  select(-source) %>%
  count(position) %>% 
  filter(n >= n_min)


# Final data ----

wp_out <- wp %>% filter(position %in% tag_count$position)

write_csv(wp_out, "02-data-preparation/01-wp-infobox.csv")
