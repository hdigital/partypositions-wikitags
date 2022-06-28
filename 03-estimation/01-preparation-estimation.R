## Prepare data for Stan estimation and save results as RData file.
## Calculate starting values for estimation with correspondence analysis 
## and logit regression. Transform binary data matrix to stacked (long)
## format for estimation (vectorized processing in Stan)


library(readr)
# "MASS::" used below; not loaded to avoid tidyverse conflicts (esp. "select()")


min_tags <- 50    # minimum number of tag occurrences
min_parties <- 2  # minimum number of tags per party

data_source_file <- "02-data-preparation/02-wp-data.csv"


## Functions ----

select_submat <- function(mat, row_min, col_min) {
  
  # select sub-matrix with row and  
  # col margins not lower than min
  
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

stack_tag_mat <- function(mat) {
  
  # reshape tag presence-absence matrix to  
  # long format and make party id var
  
  names(mat) <- gsub("^", "outcome.", names(mat))
  mat$party <- seq_len(nrow(mat))
  
  mat <- reshape(
    mat, 
    direction = "long", 
    varying = grep("\\.", names(mat), value = TRUE),
    sep = ".",
    idvar = "party",
    timevar = "tag"
  )
  mat$tag <- as.factor(mat$tag)
  
  return(mat)
  
}

generate_ab <- function(x, o, y_mat) {
  
  # make starting values for alpha and beta (via  
  # logit reg), given values for x, o and binary
  # data matrix y
  
  sq_dist <- sapply(o, function(.z) (rep(.z, length(x)) - x) ^ 2)
  
  ab <- mapply(
    function(.y, .x) 
      coef(suppressWarnings(glm(.y ~ .x, family = binomial(link = "logit")))),
    y_mat, 
    data.frame(sq_dist)
  )
  ab <- t(ab)
  colnames(ab) <- c("alpha", "beta")
  
  return(ab)
  
}


## Files output ----

filename_out <- "03-estimation/estimation-model/01-data-m%d.RData"



### Data preparation ----

bcm_raw <- read_csv(data_source_file)

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

wp_model <- 1


# Trim data (minimum occurrences) ---

ideology <- select_submat(
  bcm_raw[, ! names(bcm_raw) %in% lr], 
  min_parties, 
  min_tags
)

partyfacts_id <- partyfacts_id_all[
  partyfacts_id_all %in% as.integer(gsub("id_", "", row.names(ideology)))
]
party <- setNames(seq_len(nrow(ideology)), nm = partyfacts_id)


# Starting values ----

ca <- MASS::corresp(as.matrix(ideology), n = 1)

x_init <- ca$rscore
o_init <- ca$cscore
ab_init <- generate_ab(x_init, o_init, ideology)


# Data set: parties (stacked) and their ideology tags ----

ideology <- stack_tag_mat(ideology)

save(
  ideology,
  x_init,
  o_init,
  ab_init,
  party,
  partyfacts_id,
  file = sprintf(filename_out, wp_model)
)


## Model 2 ----

wp_model <- 2

bcm <- select_submat(bcm_raw, min_parties, min_tags)
ideology_mat <- bcm[, ! names(bcm) %in% lr]

partyfacts_id <- partyfacts_id_all[
  partyfacts_id_all %in% as.integer(gsub("id_", "", row.names(bcm)))
]
party <- setNames(seq_len(nrow(bcm)), nm = partyfacts_id)


# Data set: parties (stacked) and their ideology tags ----

ideology <- stack_tag_mat(ideology_mat)
tagsum <- aggregate(ideology["outcome"], ideology["party"], sum)
ideology <- ideology[ideology$party %in% tagsum$party[tagsum$outcome > 0], ]


# Data set: parties (stacked) and their lr-position tags ----

left_right <- mapply(function(.x, .y) .x * .y, bcm[, lr], seq_along(lr))
left_right <- stack_tag_mat(data.frame(left_right))
left_right <- left_right[left_right$outcome > 0, setdiff(names(left_right), "tag")]


# Starting values ----

ca <- MASS::corresp(as.matrix(bcm), nf = 1)

x_init <- ca$rscore
o_init <- ca$cscore[names(ideology_mat)]
ab_init <- generate_ab(x_init, o_init, ideology_mat)

ologit <- MASS::polr(factor(left_right$outcome) ~ x_init[left_right$party])

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
  party,
  partyfacts_id,
  file = sprintf(filename_out, wp_model)
)
