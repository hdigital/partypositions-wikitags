## Visualize left-right positions of tags


library(tidyverse)
library(glue)
library(ggrepel)


tags_m2_raw <- read_csv("03-estimation/estimation-results/positions-tags-m2.csv")

tags <- 
  tags_m2_raw %>% 
  mutate(
    ideology = str_replace_all(ideology, fixed("."), " "),
    ideology = fct_reorder(ideology, o, .desc = TRUE)
    )

## Tags plot ----

# group tags -- one estimate of group outside interval
pl_limit <- 2.5

pl_tags <- 
  tags %>% 
  group_by(ideology) %>% 
  mutate(group = if_else(min(lo) < -1 * pl_limit | max(up) > pl_limit, "B", "A"))

pl <- 
  ggplot(pl_tags, aes(ideology, o)) +
  geom_hline(
    yintercept = c(-pl_limit, pl_limit),
    linetype = "longdash", color = "darkblue", alpha = 0.6, size = 0.25
    ) +
  geom_pointrange(
    aes(ymin = lo, ymax = up),
    # fatten = 2, alpha = 0.8,
    position = position_dodge2(width = 0.6, reverse = TRUE)
  ) +
  facet_wrap(~ group, scales = "free") +
  coord_flip() +
  labs(x = NULL, y = NULL) +
  theme_minimal()

print(pl)
ggsave(
  glue("06-figures-tables/fig-tags-scaled.pdf"), pl,
  width = 200, height = 150, units = "mm"
  )

