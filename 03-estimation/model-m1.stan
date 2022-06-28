// Stan code for model 1
// estimate party positions from ideology tags only

data {

  int<lower=1> tag_right_ideo;
  int<lower=1> I;
  int<lower=1> J;
  int<lower=1> N;
  int<lower=1, upper=I> party_ideo[N];
  int<lower=1, upper=J> tag[N];
  int<lower=0, upper=1> y_ideo[N];

}

parameters {

  vector[I] xstar;
  vector[J] delta;
  vector[J] lambda;
  vector<lower=0>[J] beta;

}

model {

  xstar ~ std_normal();
  delta ~ normal(0, sqrt(5));
  lambda ~ normal(0, sqrt(5));
  beta ~ lognormal(0, sqrt(2));
  
  y_ideo ~ bernoulli_logit(
    delta[tag] + lambda[tag] .* xstar[party_ideo] 
    - beta[tag] .* xstar[party_ideo] .* xstar[party_ideo]
  );
}

generated quantities {

  int<lower=-1, upper=1> polarity;
  vector[I] x;
  vector[J] a;
  vector<lower=0>[J] b;
  vector[J] o;
  real xbar = mean(xstar);
  real sdx = sd(xstar);
  
  polarity = xbar < (lambda[tag_right_ideo] / (2 * beta[tag_right_ideo])) ? 1 : -1;
  x = polarity * (xstar - xbar) / sdx;
  a = delta + beta .* (lambda .* lambda ./ (4 * beta .* beta));
  b = beta * sdx ^ 2;
  o = polarity * ((lambda ./ (2 * beta)) - xbar) / sdx;

}
