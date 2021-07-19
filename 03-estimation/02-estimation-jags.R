## Estimation of left-right positions from tags (ideology and position).
## The Jags model is only estimated if no RData in sub-folder "estimation-models"
## exist. Remove Rdata file to start estimation -- see below 


library(readr)
library(jagsUI)


wp_model <- 2          # model to estimate -- M1 or M2

n_chains <- 4          # number of Markov chains
n_iter <- 25000        # total number of iterations
n_burn <- 2500         # number of burn-in iterations
n_thin <- 10           # keep every nth iteration
run_parallel <- TRUE   # run chains in parallel


file_jags_results <- sprintf(
  "03-estimation/estimation-model/02-result-m%d.RData", 
  wp_model
)
file_position_out <- "03-estimation/estimation-results/positions-%s-m%d.csv"



## Declare JAGS input ----

load(sprintf("03-estimation/estimation-model/01-data-m%d.RData", wp_model))

param_save <- c("a", "b", "o", "x")

jags_inits <- list(
  delta = ab_init[, "alpha"] - abs(ab_init[, "beta"]) * o_init ^ 2,
  lambda = abs(ab_init[, "beta"]) * o_init * 2,
  beta = abs(ab_init[, "beta"]),
  xstar = x_init
)
inits_add <- list()

rng_names <- c(
  "Wichmann-Hill", 
  "Marsaglia-Multicarry", 
  "Super-Duper", 
  "Mersenne-Twister"
)
rng_chain <- rep_len(paste0("base::", rng_names), n_chains)

jags_data <- list(
  y_ideo = ideology,
  D = dim(ideology),
  con = which(names(ideology) == "conservatism")
)

if (wp_model == 2) {
  
  param_save <- c(c("g", "t"), param_save)
  inits_add <- list(gamma = g_init, tau = t_init)
  jags_data <- append(jags_data, list(y_lr = left_right, N = nrow(left_right)))
  
}

jags_inits <- lapply(
  seq_len(n_chains), 
  function(.x) append(
    append(jags_inits, inits_add),
    list(".RNG.name" = rng_chain[.x], ".RNG.seed" = .x * 10)
  )
)



## Run JAGS ----

if (file.exists(file_jags_results)) {
  
  load(file_jags_results)
  
} else {
  
  jags_out <- jags(
    data = jags_data,
    inits = jags_inits,
    parameters.to.save = param_save,
    model.file = sprintf("03-estimation/model-m%d-jags.txt", wp_model),
    n.chains = n_chains,
    parallel = run_parallel,
    n.iter = n_iter,
    n.burnin = n_burn,
    n.thin = n_thin
  )
  save(jags_out, partyfacts_id, file = file_jags_results)
  
}



## Export position estimates (and 95% CIs) to csv ----

pos_parties <- data.frame(
  partyfacts_id = partyfacts_id,
  x = apply(jags_out$sims.list$x, 2, median),
  lo = apply(jags_out$sims.list$x, 2, quantile, 0.025),
  up = apply(jags_out$sims.list$x, 2, quantile, 0.975)
)
write_csv(pos_parties, sprintf(file_position_out, "parties", wp_model))

pos_tags <- data.frame(
  ideology = names(ideology),
  o = apply(jags_out$sims.list$o, 2, median),
  lo = apply(jags_out$sims.list$o, 2, quantile, 0.025),
  up = apply(jags_out$sims.list$o, 2, quantile, 0.975)
)
write_csv(pos_tags, sprintf(file_position_out, "tags", wp_model))
