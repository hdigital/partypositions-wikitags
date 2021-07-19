## Prepare data for Jags estimation and save results as RData file.
## Transform Wikipedia data into matrix format (no data frame) and calculate
## starting values for estimation with correspondence analysis.


library(readr)
# "MASS::" used below; not loaded to avoid tidyverse conflicts (esp. "select()")


min_tags <- 50    # minimum number of tag occurrences
min_parties <- 2  # minimum number of tags per party



## Functions ----

# Select sub-matrix with row and col margins not lower than min ----

select_submat <- function(mat, row_min, col_min) {
  
  while (any(rowSums(mat) < row_min)) {
    
    row_select <- rowSums(mat) >= row_min
    mat <- mat[row_select, ]

    while (any(colSums(mat) < col_min)) {

      col_select <- colSums(mat) >= col_min
      mat <- mat[, col_select]

    }
    
  }
  
  return(mat)
  
}


# Generate starting values for alpha and beta (via logit reg) given x and o ----

generate_ab <- function(x, o) {
  
  sq_dist <- sapply(o, function(.z) (rep(.z, length(x)) - x) ^ 2)
  
  ab <- mapply(
    function(.y, .x) 
      coef(suppressWarnings(glm(.y ~ .x, family = binomial(link = "logit")))),
    ideology, 
    data.frame(sq_dist)
  )
  ab <- t(ab)
  colnames(ab) <- c("alpha", "beta")
  
  return(ab)
  
}



### Data preparation ----

bcm_raw <- read_csv("02-data-preparation/02-wp-data.csv")

lr <- c(
  "far_left", 
  "left_wing", 
  "centre_left", 
  "centre", 
  "centre_right", 
  "right_wing", 
  "far_right"
)

# Create partyfacts vector for later use and remove it from data ----

bcm_raw <- as.data.frame(bcm_raw)
row.names(bcm_raw) <- paste0("id_", bcm_raw[, "partyfacts_id"])
partyfacts_id_all <- bcm_raw[, "partyfacts_id"]
bcm_raw <- bcm_raw[, names(bcm_raw) != "partyfacts_id"]



## Model 1 ----

# Data ---

ideology <- select_submat(
  bcm_raw[, ! names(bcm_raw) %in% lr], 
  min_parties, 
  min_tags
)

partyfacts_id <- partyfacts_id_all[
  partyfacts_id_all %in% as.integer(gsub("id_", "", row.names(ideology)))
]


# Starting values ----

ca <- MASS::corresp(as.matrix(ideology), n = 1)

x_init <- ca$rscore
o_init <- ca$cscore
ab_init <- generate_ab(x_init, o_init)


save(
  ideology,
  x_init,
  o_init,
  ab_init,
  partyfacts_id,
  file = "03-estimation/estimation-model/01-data-m1.RData"
)



## Model 2 ----

bcm <- select_submat(bcm_raw, min_parties, min_tags)

partyfacts_id <- partyfacts_id_all[
  partyfacts_id_all %in% as.integer(gsub("id_", "", row.names(bcm)))
]


# Dataset: ideology classification matrix ----

ideology <- bcm[, ! names(bcm) %in% lr]


# Dataset: parties (stacked) and their lr-position tags ----

left_right <- data.frame(
  mapply(function(.x, .y) .x * .y, bcm[, lr], seq_along(lr))
)

names(left_right) <- paste("tag", lr, sep = ".")
left_right$id <- seq_len(nrow(left_right))

left_right <- reshape(
  left_right, 
  direction = "long", 
  varying = grep("\\.", names(left_right), value = TRUE),
  sep = ".",
  timevar = NULL
)

left_right <- left_right[left_right$tag != 0, ]


# Starting values ----

ca <- MASS::corresp(as.matrix(bcm), nf = 1)

x_init <- ca$rscore
o_init <- ca$cscore[names(ideology)]
ab_init <- generate_ab(x_init, o_init)

ologit <- MASS::polr(factor(left_right$tag) ~ x_init[left_right$id])

g_init <- coef(ologit)
t_init <- ologit$zeta


save(
  left_right,
  ideology,
  x_init,
  o_init,
  ab_init,
  g_init,
  t_init,
  partyfacts_id,
  file = "03-estimation/estimation-model/01-data-m2.RData"
)