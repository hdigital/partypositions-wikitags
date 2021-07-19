## Visualize tag frequency


library(tidyverse)
library(glue)


n_min <- 20

wp_raw <- read_csv("02-data-preparation/01-wp-infobox.csv")


## Define tag type (different from source) ----

lr_tags <- c(
  "far-left", 
  "left-wing", 
  "centre-left", 
  "centre", 
  "centre-right", 
  "right-wing", 
  "far-right"
)

wp <- 
  wp_raw %>% 
  select(-source) %>%  # tag name defintion based
  mutate(Tag = ifelse(position %in% lr_tags, "lr-position", "ideology"))


## Figure entries ----

pl_dt <- 
  wp %>% 
  count(partyfacts_id, Tag) %>% 
  rename(entries = n) %>%
  filter(entries < 10) %>% 
  spread(Tag, entries, fill = 0) %>% 
  gather(Tag, entries, -partyfacts_id)

pl <- 
  ggplot(pl_dt, aes(entries)) +
  geom_bar() +
  scale_x_continuous(breaks = c(0, 5, 10)) +
  facet_wrap(~ Tag) +
  theme_minimal()

print(pl)
ggsave(
  "06-figures-tables/fig-freq-ideology-position.pdf", 
  width = 100, 
  height = 60, 
  units = "mm"
)


## Figure frequency ----

pl_dt <- 
  wp %>% 
  mutate(
    position = ifelse(Tag == "lr-position", toupper(position), position)
    ) %>% 
  count(position, Tag) %>% 
  mutate(position = fct_reorder(position, n)) %>% 
  filter(n >= n_min)

pl <-
  pl_dt %>% 
  ggplot(aes(x = position, y = n, fill = Tag)) +
  geom_bar(stat = "identity") +
  geom_hline(aes(yintercept = 50), color = "grey40", linetype = "dotted") +
  coord_flip() +
  labs(x = NULL, y = NULL) +
  theme_minimal() +
  theme(
    strip.background = element_blank(),
    strip.text.x = element_blank()
    )

print(pl)
ggsave(
  "06-figures-tables/fig-freq-tags.pdf", 
  pl, 
  width = 180, 
  height = 210, 
  units = "mm"
)
