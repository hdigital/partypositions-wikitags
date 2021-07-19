## Create plots with response curves to visualize the left-right positions
## of ideology tags, the probability of assignment and discrimination


wp_model <- 2     # set model to estimate -- M1 or M2

eval <- 500       # smoothness of plotted curves (evaluation points)
lr_curv <- FALSE  # include resp. curves for lr-position tags

file_graph_out <- sprintf(
  "03-estimation/estimation-results/response-curves-m%d.pdf", wp_model
)


## Functions: (cumulative) responses ----

response <- function(alpha, beta, o, x) {
  
  xb <- alpha - beta * (o - x) ^ 2
  return(1 / (1 + exp(-xb)))
  
}

logistic <- function(tau, gamma, x) {
  
  xb <- tau - gamma * x
  return(1 / (1 + exp(-xb)))
  
}


## Data for plotting ----

load(sprintf("03-estimation/estimation-model/01-data-m%d.RData", wp_model))
load(sprintf("03-estimation/estimation-model/02-result-m%d.RData", wp_model))


# Create variables ----

pos <- jags_out$q50$x
loc <- jags_out$q50$o

invisible(
  lapply(
    c("a", "b", "o", "g", "t"),
    function(.x) assign(.x, jags_out[["sims.list"]][[.x]], envir = .GlobalEnv)
  )
)


## Create inputs for plot ----

domain <- range(pos) + 0.05 * diff(range(pos)) * c(-1, 1)
xvals <- seq(min(domain), max(domain), length.out = eval)


# Ideology tags ----

pr_ideo <- t(
  sapply(xvals, function(.x) apply(response(a, b, o, .x), 2, median))
  )

tags_ideo <- names(ideology)

# coordinates for text (tags) if response peaks within x-range
in_range <- min(pos) < loc & loc < max(pos)
x_in <- loc[in_range]
y_in <- (apply(response(a, 0, 0, 0), 2, median) + 0.02)[in_range]

# ... if response peaks left of x-range
out_l <- loc < min(pos)
x_l <- min(pos) - 0.1
y_l <- apply(response(a, b, o, x_l), 2, median)[out_l] 

# ... if response peaks right of x-range
out_r <- loc > max(pos)
x_r <- max(pos) + 0.1
y_r <- apply(response(a, b, o, x_r), 2, median)[out_r]


# lr-position tags ----

if (wp_model == 2) {
  
  tags_lr <- c(
    "far_left", 
    "left_wing",
    "centre_left",
    "centre",
    "centre_right",
    "right_wing",
    "far_right"
  )  # ordering is deliberate
  
  if (lr_curv) {

    pr_lr <- matrix(NA, nrow = length(xvals), ncol = length(tags_lr))

    for (i in seq_len(ncol(pr_lr))) {
  
      t_l <- ifelse(i == 1, -Inf, t[, i - 1])
      t_r <- ifelse(i == ncol(pr_lr), Inf, t[, i])

      pr_lr[, i] <- sapply(
        xvals, 
        function(.x) median(logistic(t_r, g, .x) - logistic(t_l, g, .x))
      )
    
    }
    
  }
  
  # cut points
  cut <- apply(cbind(t, g), 1, function(.x) .x / .x["g"])
  cut <- apply(cut, 1, median)
  cut <- cut[! names(cut) == "g"]
  
  # coordinates for placement of lr-position tags
  half_intervals <- (c(cut, max(domain)) - c(min(domain), cut)) * 0.5
  x_lr <- c(min(domain), cut) + half_intervals
  
}



## Plot ----

pdf(file_graph_out, width = 14, height = 7)

plot(
  range(pos), 
  c(0, 1), 
  type = "n", 
  main = "", 
  ylab = "Probability of tag assignment", 
  xlab = "left-right"
)

if (wp_model == 2) {
  
  invisible(lapply(cut, function(.x) abline(v = .x, col = "grey")))

  if (lr_curv) {
  
    invisible(apply(pr_lr, 2, function(.x) lines(xvals, .x, col = "grey")))
  
  }

  text(x_lr, 1, labels = tags_lr, col = "grey")

}
  
invisible(apply(pr_ideo, 2, function(.x) lines(xvals, .x, col = "grey50")))

text(x_in, y_in, labels = tags_ideo[in_range])
text(x_l, y_l, labels = tags_ideo[out_l], pos = 4)
text(x_r, y_r, labels = tags_ideo[out_r], pos = 2)

rug(pos)

dev.off()
