## Estimation of left-right positions from tags (ideology and position).
## The Stan model is only estimated if no csv file with MCMC samples 
## exists in sub-folder "estimation-models". Remove csv files to start 
## estimation -- see below 


library(readr)
library(rstan)


wp_model <- 2          # model to estimate -- M1 or M2

n_chains <- 4          # number of Markov chains
n_iter <- 2500         # total number of iterations
n_burn <- 250          # number of burn-in iterations
stan_seed <- 123456


## Stan config ----

options(mc.cores = parallel::detectCores())


## Files input/output ----

file_position_out <- "03-estimation/estimation-results/positions-%s-m%d.csv"

file_stan <- sprintf("03-estimation/model-m%d.stan", wp_model)
files_stan_samples <- sprintf(
  "03-estimation/estimation-model/02-stan-samples-m%d_%d.csv", 
  wp_model, 
  seq_len(n_chains)
)
filename_stan_samples <- unique(gsub("_[[:digit:]]*.csv", "", files_stan_samples))
filename_stan_diags <- sprintf(
  "03-estimation/estimation-model/02-stan-diags-m%d",
  wp_model
)


## Stan input ----

load(sprintf("03-estimation/estimation-model/01-data-m%d.RData", wp_model))

param_save <- c("a", "b", "o", "x")

stan_inits <- list(
  delta = ab_init[, "alpha"] - abs(ab_init[, "beta"]) * o_init ^ 2,
  lambda = abs(ab_init[, "beta"]) * o_init * 2,
  beta = abs(ab_init[, "beta"]),
  xstar = x_init
)

stan_data <- list(
  con = which(levels(ideology$tag) == "conservatism"),
  I = length(party),
  J = nlevels(ideology$tag),
  N = nrow(ideology),
  party_ideo = ideology$party,
  tag = as.integer(ideology$tag),
  y_ideo = as.integer(ideology$outcome)
)

if (wp_model == 2) {
  
  param_save <- c("g", "t", param_save)
  stan_inits <- append(stan_inits, list(gamma = g_init, tau = t_init))
  data_add <- list(
    M = nrow(left_right), 
    K = length(unique(left_right$outcome)),
    party_lr = left_right$party,
    y_lr = as.integer(left_right$outcome)
  )
  stan_data <- append(stan_data, data_add)
  
}

stan_inits <- setNames(
  rep(list(stan_inits), n_chains), 
  paste("chain", seq_len(n_chains), sep = "_")
)


# Run Stan ----

if (any(file.exists(files_stan_samples))) {
  error_msg <- "No Stan estimation. Remove incomplete '02-stan-*' files"

  stan_out <- tryCatch(
    {
      read_stan_csv(files_stan_samples)
    },
    error = function(cond) {
      message(cond)
      stop(error_msg)
    }
  )
  
} else {
  
  stan_out <- stan(
    file = file_stan,
    data = stan_data,
    iter = n_iter,
    warmup = n_burn,
    chains = n_chains,
    init = stan_inits,
    pars = param_save,
    include = TRUE,
    seed = stan_seed,
    sample_file = filename_stan_samples,
    diagnostic_file = filename_stan_diags
  )
  
}



## Export position estimates (and 95% CIs) to csv ----

posterior_stats <- summary(stan_out, pars = param_save)$summary

x <- grep("x\\[[[:digit:]]*\\]$", rownames(posterior_stats), value = TRUE)
o <- grep("o\\[[[:digit:]]*\\]$", rownames(posterior_stats), value = TRUE)

pos_parties <- data.frame(
  partyfacts_id = names(party),
  x = posterior_stats[x, "50%"],
  lo = posterior_stats[x, "2.5%"],
  up = posterior_stats[x, "97.5%"]
)
write_csv(pos_parties, sprintf(file_position_out, "parties", wp_model))

pos_tags <- data.frame(
  ideology = levels(ideology$tag),
  o = posterior_stats[o, "50%"],
  lo = posterior_stats[o, "2.5%"],
  up = posterior_stats[o, "97.5%"]
)
write_csv(pos_tags, sprintf(file_position_out, "tags", wp_model))
