// Stan code for model 2
// estimate party positions from ideology and lr-position tags

data {

  int<lower=1> con;
  int<lower=1> I;
  int<lower=1> J;
  int<lower=1> N;
  int<lower=1> M;
  int<lower=2> K;
  int<lower=1, upper=I> party_ideo[N];
  int<lower=1, upper=I> party_lr[M];
  int<lower=1, upper=J> tag[N];
  int<lower=0, upper=1> y_ideo[N];
  int<lower=1, upper=K> y_lr[M];

}

parameters {

  vector[I] xstar;
  vector[J] delta;
  vector[J] lambda;
  vector<lower=0>[J] beta;
  ordered[K - 1] tau;
  real gamma;

}

model {

  xstar ~ std_normal();
  delta ~ normal(0, sqrt(5));
  lambda ~ normal(0, sqrt(5));
  beta ~ lognormal(0, sqrt(2));
  tau ~ normal(0, sqrt(25));
  gamma ~ normal(0, sqrt(25));

  y_ideo ~ bernoulli_logit(
    delta[tag] + lambda[tag] .* xstar[party_ideo] 
    - beta[tag] .* xstar[party_ideo] .* xstar[party_ideo] 
  );
  y_lr ~ ordered_logistic(gamma * xstar[party_lr], tau);
  
}

generated quantities {

  int<lower=-1, upper=1> polarity;
  vector[I] x;
  vector[J] a;
  vector<lower=0>[J] b;
  vector[J] o;
  vector[K - 1] t;
  real g;
  real xbar = mean(xstar);
  real sdx = sd(xstar);
  
  polarity = xbar < (lambda[con] / (2 * beta[con])) ? 1 : -1;
  x = polarity * (xstar - xbar) / sdx;
  a = delta + beta .* (lambda .* lambda ./ (4 * beta .* beta));
  b = beta * sdx ^ 2;
  o = polarity * ((lambda ./ (2 * beta)) - xbar) / sdx;
  t = tau - gamma * xbar;
  g = polarity * gamma * sdx;

}

