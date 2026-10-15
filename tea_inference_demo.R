# Tea inference demo ---------------------------------------------------------
#
# Live demo for the Inference lecture (PSYC 201A / CSS 204, Experimentology ch. 6).
# One script, base R + tidyverse only. Run it top to bottom, or one section at a
# time with Ctrl/Cmd + Enter. In RStudio, the sections below show up in the
# document outline (Ctrl/Cmd + Shift + O) so you can jump between them in class.
#
# The running example: do people rate tea higher when the milk goes in first?
# Between-subjects, one rating per person on a 1-7 scale.
#
# Every section prints a plot and, where it matters, one or two numbers.
# Nothing here takes more than a few seconds.

library(tidyverse)

set.seed(209) # this seed gives an experiment with p ~ .03; change it for a different "world"

theme_set(theme_classic(base_size = 16))


# 0. Knobs --------------------------------------------------------------------
# Change these live to answer "what if" questions from the room.

true_delta <- 1     # true difference, milk first minus tea first, in scale points
sigma      <- 1.25  # sd of ratings within each condition
n_total    <- 48    # participants per experiment (half in each condition)
n_sims     <- 1000  # how many times we rerun the experiment
alpha      <- .05

# Real Likert ratings are whole numbers, but rounding makes the histograms
# below spiky (differences can only take a few values). Leave this FALSE for
# clean pictures; flip to TRUE to show students what real 1-7 data look like.
round_ratings <- FALSE


# 1. The simulation function --------------------------------------------------
# Makes one experiment's worth of data. Ratings are drawn from a normal
# distribution and clipped to the 1-7 scale (and rounded, if round_ratings).

make_tea_data <- function(n_total = 48, delta = 1, sigma = 1.25) {
  n_half <- n_total / 2
  tibble(
    condition = factor(rep(c("milk first", "tea first"), each = n_half),
                       levels = c("milk first", "tea first")),
    rating = c(rnorm(n_half, mean = 3.5 + delta, sd = sigma),
               rnorm(n_half, mean = 3.5,         sd = sigma))
  ) |>
    mutate(rating = if (round_ratings) round(rating) else rating,
           rating = pmin(pmax(rating, 1), 7))
}

# Runs one experiment and keeps the numbers we care about: the estimated
# difference, its 95% CI, and the p-value from a two-sample t-test.
run_experiment <- function(n_total, delta, sigma, conf_level = .95) {
  d  <- make_tea_data(n_total, delta, sigma)
  tt <- t.test(rating ~ condition, data = d, var.equal = TRUE,
               conf.level = conf_level)
  tibble(diff    = unname(tt$estimate[1] - tt$estimate[2]),
         ci_low  = tt$conf.int[1],
         ci_high = tt$conf.int[2],
         p       = tt$p.value)
}

# Runs the experiment many times. Each row is one whole experiment.
run_many <- function(n_sims, n_total, delta, sigma, conf_level = .95) {
  map(seq_len(n_sims), \(i) run_experiment(n_total, delta, sigma, conf_level)) |>
    list_rbind() |>
    mutate(sim = row_number(), .before = 1)
}


# 2. One experiment -----------------------------------------------------------
# This is all a real study ever gets to see.

tea_data <- make_tea_data(n_total, true_delta, sigma)

tea_means <- tea_data |>
  group_by(condition) |>
  summarize(mean = mean(rating),
            se   = sd(rating) / sqrt(n()),
            ci_low  = mean - qt(.975, n() - 1) * se,
            ci_high = mean + qt(.975, n() - 1) * se)

ggplot(tea_data, aes(x = condition, y = rating, color = condition)) +
  geom_jitter(width = .15, height = .1, alpha = .6, size = 2) +
  geom_pointrange(data = tea_means,
                  aes(y = mean, ymin = ci_low, ymax = ci_high),
                  color = "black", linewidth = 1) +
  scale_y_continuous(breaks = 1:7, limits = c(0.5, 7.5)) +
  guides(color = "none") +
  labs(title = "One experiment",
       subtitle = "Dots = people; black = condition mean with 95% CI",
       x = NULL, y = "Tea rating (1-7)")

one_test <- t.test(rating ~ condition, data = tea_data, var.equal = TRUE)
one_test
observed_diff <- unname(one_test$estimate[1] - one_test$estimate[2])


# 3. Run the experiment many times --------------------------------------------
# Same true effect, three sample sizes. Each histogram is the spread of
# estimated differences across 1000 reruns: the sampling distribution.
# Talking point: the center doesn't move, only the spread does. Small studies
# aren't biased, just noisy.

sampling_by_n <- c(18, 48, 200) |>
  map(\(n) run_many(n_sims, n, true_delta, sigma) |> mutate(n_total = n)) |>
  list_rbind() |>
  mutate(n_label = fct_inorder(paste0("N = ", n_total, " (", n_total / 2,
                                      " per group)")))

ggplot(sampling_by_n, aes(x = diff)) +
  geom_histogram(binwidth = .1, fill = "steelblue", color = "white") +
  geom_vline(xintercept = true_delta, linetype = "dashed") +
  facet_wrap(~ n_label, ncol = 1) +
  labs(title = "Rerunning the experiment 1000 times",
       subtitle = "Dashed line = true difference",
       x = "Estimated difference (milk first - tea first)", y = "Experiments")

sampling_by_n |>
  group_by(n_label) |>
  summarize(mean_estimate = mean(diff), sd_of_estimates = sd(diff))


# 4. The null distribution ----------------------------------------------------
# Same experiment, but now the true difference is ZERO. This is the "no effect"
# world. The x-axis is still a difference, and it's centered on zero.
# Gut check for students: x-axis is a difference centered on zero -> null
# distribution. It is NOT the control condition.

null_sims <- run_many(n_sims, n_total, delta = 0, sigma)

ggplot(null_sims, aes(x = diff)) +
  geom_histogram(binwidth = .1, fill = "grey60", color = "white") +
  geom_vline(xintercept = observed_diff, color = "firebrick", linewidth = 1.2) +
  geom_vline(xintercept = -observed_diff, color = "firebrick",
             linewidth = 1.2, linetype = "dotted") +
  labs(title = "The null distribution: 1000 experiments with no effect",
       subtitle = "Red = the difference we actually observed in section 2",
       x = "Estimated difference (milk first - tea first)", y = "Experiments")

# The p-value, by counting: how often does the no-effect world produce a
# difference at least as extreme as ours (in either direction)?
null_sims |>
  summarize(simulated_p = mean(abs(diff) >= abs(observed_diff)),
            t_test_p    = one_test$p.value)
# Say it out loud: probability of data this extreme OR MORE, assuming the null.
# If someone asks why the two p-values don't match exactly: the simulated null
# uses the TRUE sigma (we know it, we made the world). The t-test has to
# estimate sigma from this one sample. Section 5 uses our actual data, so it
# lands closer to the t-test.


# 5. Same idea from our own data: shuffle the labels --------------------------
# We don't need to know sigma to build a null distribution. Shuffle the
# condition labels in OUR experiment: if condition meant nothing, any
# labeling is as good as any other.

shuffled_diffs <- map_dbl(seq_len(n_sims), \(i) {
  shuffled <- sample(tea_data$condition)
  mean(tea_data$rating[shuffled == "milk first"]) -
    mean(tea_data$rating[shuffled == "tea first"])
})

ggplot(tibble(diff = shuffled_diffs), aes(x = diff)) +
  geom_histogram(binwidth = .1, fill = "grey60", color = "white") +
  geom_vline(xintercept = observed_diff, color = "firebrick", linewidth = 1.2) +
  labs(title = "Permutation null: our data, labels shuffled 1000 times",
       x = "Difference after shuffling", y = "Shuffles")

tibble(permutation_p = mean(abs(shuffled_diffs) >= abs(observed_diff)),
       t_test_p      = one_test$p.value)


# 6. Null vs. real effect, and why N matters (power) --------------------------
# Two distributions on one axis: no effect (grey) and the true effect (blue).
# The vertical lines are the significance cutoffs: estimates beyond them are
# p < .05. Bigger N doesn't move the centers; it squeezes both distributions,
# so they stop overlapping. Effect stays the same; noise gets out of the way.

null_by_n <- c(18, 48, 200) |>
  map(\(n) run_many(n_sims, n, 0, sigma) |> mutate(n_total = n)) |>
  list_rbind()

null_vs_effect <- bind_rows(
  null_by_n      |> mutate(world = "No effect (null)"),
  sampling_by_n  |> select(-n_label) |> mutate(world = "True effect")
) |>
  mutate(n_label = fct_inorder(paste0("N = ", n_total)))

cutoffs <- null_by_n |>
  group_by(n_total) |>
  summarize(cut = quantile(abs(diff), 1 - alpha)) |>
  mutate(n_label = factor(paste0("N = ", n_total),
                          levels = levels(null_vs_effect$n_label)))

ggplot(null_vs_effect, aes(x = diff, fill = world)) +
  geom_histogram(binwidth = .1, position = "identity", alpha = .6) +
  geom_vline(data = cutoffs, aes(xintercept = cut), linetype = "dashed") +
  geom_vline(data = cutoffs, aes(xintercept = -cut), linetype = "dashed") +
  facet_wrap(~ n_label, ncol = 1) +
  scale_fill_manual(values = c("No effect (null)" = "grey55",
                               "True effect" = "steelblue")) +
  labs(title = "Null vs. true effect at three sample sizes",
       subtitle = "Dashed lines = cutoffs for p < .05",
       x = "Estimated difference", y = "Experiments", fill = NULL) +
  theme(legend.position = "top")

# Power = how often the real effect clears the bar. Alpha = how often the null does.
null_vs_effect |>
  group_by(n_label, world) |>
  summarize(prop_significant = mean(p < alpha), .groups = "drop") |>
  pivot_wider(names_from = world, values_from = prop_significant) |>
  rename(false_positive_rate = `No effect (null)`, power = `True effect`)


# 7. What "95% confidence" means -----------------------------------------------
# 50 experiments, each with its own 95% CI. The true difference (the ball) is
# fixed; the intervals (the hoops) move. About 95% of hoops catch the ball,
# but any single interval either does or doesn't.

ci_sims <- run_many(50, n_total, true_delta, sigma) |>
  mutate(covers = ci_low <= true_delta & ci_high >= true_delta)

ggplot(ci_sims, aes(y = sim, x = diff, xmin = ci_low, xmax = ci_high,
                    color = covers)) +
  geom_pointrange(size = .3) +
  geom_vline(xintercept = true_delta, linetype = "dashed") +
  geom_vline(xintercept = 0, color = "grey70") +
  scale_color_manual(values = c(`TRUE` = "grey40", `FALSE` = "firebrick"),
                     labels = c(`TRUE` = "Contains the true value",
                                `FALSE` = "Misses it")) +
  labs(title = "50 experiments, 50 confidence intervals",
       subtitle = "Dashed = true difference; grey line = zero",
       x = "Estimated difference with 95% CI", y = "Experiment", color = NULL) +
  theme(legend.position = "top")

# Over many reruns, the coverage is ~95%:
run_many(n_sims, n_total, true_delta, sigma) |>
  summarize(coverage = mean(ci_low <= true_delta & ci_high >= true_delta),
            ci_excludes_zero = mean(ci_low > 0 | ci_high < 0),
            p_below_05 = mean(p < .05))
# Last two columns are identical: a 95% CI on the difference excludes zero
# exactly when p < .05.


# 8. p-values across many experiments -----------------------------------------
# When the null is true, p-values are flat: every value is equally likely,
# so 5% land below .05 by construction. When there's a real effect, they pile
# up near zero; how high the pile is depends on power.

p_compare <- bind_rows(
  null_by_n     |> filter(n_total == 48) |>
    mutate(world = "No effect"),
  sampling_by_n |> filter(n_total == 48) |> select(-n_label) |>
    mutate(world = "True effect")
)

ggplot(p_compare, aes(x = p)) +
  geom_histogram(breaks = seq(0, 1, .05), fill = "steelblue", color = "white") +
  geom_vline(xintercept = alpha, color = "firebrick") +
  facet_wrap(~ world, ncol = 1, scales = "free_y") +
  labs(title = "p-values from 1000 experiments (N = 48)",
       subtitle = "Red line = .05", x = "p-value", y = "Experiments")


# 9. Multiplicity: run more tests, get more false positives -------------------
# Chance of at least one false positive across k independent tests of true
# nulls is 1 - (1 - alpha)^k. Two tests ~ 10%, twenty ~ 64%.

tibble(k = 1:20, chance_at_least_one = 1 - (1 - alpha)^k) |>
  ggplot(aes(x = k, y = chance_at_least_one)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_y_continuous(labels = scales::percent, limits = c(0, 1)) +
  labs(title = "Chance of at least one false positive",
       x = "Number of independent tests (all nulls true)", y = NULL)


# 10. Bonus: peeking (optional stopping) --------------------------------------
# No true effect. We test after every 10 people and stop as soon as p < .05,
# up to 200 people. Each peek is another chance for noise to cross the line.

peek_once <- function(max_n = 200, step = 10) {
  d <- make_tea_data(max_n, delta = 0, sigma = sigma)
  # interleave conditions so each peek has equal numbers per group
  d <- d[order(rep(seq_len(max_n / 2), 2)), ]
  for (n in seq(step * 2, max_n, by = step * 2)) {
    if (t.test(rating ~ condition, data = d[1:n, ], var.equal = TRUE)$p.value < alpha)
      return(TRUE)
  }
  FALSE
}

tibble(false_positive_rate_with_peeking = mean(map_lgl(1:500, \(i) peek_once())),
       nominal_alpha = alpha)
# Expect well above .05. Same data, same test; the procedure changed.
