## Visualize left-right party positions in country plots


library(tidyverse)
library(glue)
library(ggrepel)


## Read data ----

party_raw <- read_csv("04-data-final/party-position-tags.csv")
tags_raw <- read_csv("04-data-final/tag-position.csv")


## Create plot data ----

pl_dt <- 
  party_raw %>% 
  filter(! is.na(position)) %>% 
  mutate(
    tags = ifelse(tags >= 5, 5, tags) %>% factor() %>% fct_recode(`> 4` = "5"),
    tags_position = if_else(is.na(tags_position), "no", "yes") %>% fct_rev(),
    position_lo = if_else(position_lo < -2.5, -2.5, position_lo),
    position_up = if_else(position_up > 2.5, 2.5, position_up)
  ) %>% 
  arrange(country_name)


## Country plot function ----

plot_country <- function(country_select) {
  pl_tmp <- pl_dt %>% filter(country_name == country_select)
  dodge_param = position_dodge2(width = 0.75)
  
  pl <- 
    ggplot(pl_tmp, aes(1, position, label = name_short)) +
    geom_linerange(
      aes(ymin = position_lo, ymax = position_up, group = desc(position)),
      size = 1, alpha = 0.25, position = dodge_param
    ) +
    geom_point(
      aes(group = desc(position), shape = tags, colour = tags_position),
      position = dodge_param
    ) +
    geom_text_repel(aes(group = desc(position)), size = 3, position = dodge_param) +
    coord_flip() +
    labs(title = country_select, x = NULL, y = NULL) +
    theme_minimal() +
    theme(axis.text.y=element_blank(), plot.title = element_text(hjust = 0.5)) +
    scale_color_discrete(drop = FALSE) +
    scale_shape_discrete(drop = FALSE) +
    aes(ymin = -2.5, ymax = 2.5)  
  
  return(pl)
}

pl <- plot_country("Norway")
plot(pl)


## Countries pdf ----

# plot all countries into one pdf

countries <- 
  pl_dt %>% 
  pull(country_name) %>% 
  unique() %>% 
  na.omit()
  
pdf("06-figures-tables/fig-countries.pdf", pl)
for(country in countries) {
  pl <- plot_country(country)
  plot(pl)
}
dev.off()
