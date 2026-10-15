# Tea inference demo

An R Markdown notebook for the live demo in the **Inference** lecture of PSYC 201A / CSS 204
(UC San Diego), following chapter 6 of [Experimentology](https://experimentology.io/).
It simulates the "lady tasting tea" experiment many times so you can *see* a
sampling distribution, a null distribution, a *p*-value, power, and what a 95%
confidence interval means.

This is the instructor's run-through. The student version with exercises to fill
in is [inference_simulations_lab_2](https://github.com/psyc-201/inference_simulations_lab_2).

## What you need

R, the **tidyverse**, and **rmarkdown** (RStudio installs rmarkdown for you).

```r
install.packages(c("tidyverse", "rmarkdown"))
```

## How to run it

1. Double-click `tea_inference_demo.Rproj` to open RStudio in this folder.
2. Open `tea_inference_demo.Rmd`.
3. Either click **Knit** to build an HTML page with every plot (about 20 seconds),
   or run one chunk at a time with the green ▶ on each chunk (or Ctrl/Cmd + Shift + Enter).
   The sections show up in RStudio's outline (Ctrl/Cmd + Shift + O), so you can
   jump between them.

If you run chunks by hand, run them in order. Sections 6 and 8 reuse simulations made in sections 3
and 6.

## The experiment

Between subjects. Each person rates one cup of tea on a 1-7 scale. Half get
milk poured first, half get tea first. The question is whether milk-first tea
gets higher ratings.

All the settings are in **section 0** at the top of the notebook:

| Setting | Default | What it is |
|---|---|---|
| `true_delta` | 1 | True difference (milk first − tea first), in scale points |
| `sigma` | 1.25 | Spread of ratings within a condition |
| `n_total` | 48 | People per experiment, split evenly |
| `n_sims` | 1000 | How many times each experiment is rerun |
| `alpha` | .05 | Significance threshold |
| `round_ratings` | FALSE | Round to whole points like real Likert data (makes histograms spiky) |

Change these and rerun to answer "what if" questions from the room.
`set.seed(209)` makes the single experiment in section 2 come out at about
*p* = .03, which puts it in a useful spot on the null distribution. Change the
seed for a different result.

## What each section shows

| # | Section | The point to make |
|---|---|---|
| 1 | Simulation function | We control the true world, so we can check our methods against it |
| 2 | One experiment | This is all a real study gets: one sample, one estimate, one *p* |
| 3 | Run it many times | Sampling distribution. Bigger N leaves the center where it is but shrinks the spread. Small studies are noisy, not biased |
| 4 | Null distribution | Rerun with no effect. The x-axis is a **difference**, centered on zero. *p* = the share of no-effect experiments at least as extreme as ours |
| 5 | Shuffle the labels | The same null, built from our own data with no assumptions about sigma |
| 6 | Null vs. true effect | Two distributions and the *p* < .05 cutoffs. Bigger N pulls them apart: power goes up, false positives stay at 5% |
| 7 | 50 confidence intervals | The true value is fixed and the intervals move. ~95% catch it, but any one interval either does or doesn't. A 95% CI on the difference excludes zero exactly when *p* < .05 |
| 8 | *p*-values across experiments | Flat under the null (5% below .05 by construction); piled near zero when the effect is real |
| 9 | Multiplicity | 1 − 0.95^k: two tests ≈ 10%, twenty ≈ 64% |
| 10 | Bonus: peeking | Test every 10 people, stop at *p* < .05. With no true effect, the false-positive rate climbs to roughly 20% |

## Questions that may come up

**"Why don't the simulated *p* and the t-test *p* match in section 4?"**
The simulation uses the true sigma, because we built the world. The t-test has to
estimate sigma from the one sample. The permutation *p* in section 5 uses the
real data, so it lands closer to the t-test.

**"Why is the false-positive rate in section 6 not exactly .05?"**
It's an estimate from 1000 simulated experiments, so it bounces around .05 by a
point or so. More simulations means less bounce.

**"Why do we clip ratings at 1 and 7?"**
Real scales have floors and ceilings. With the defaults this barely matters.
With a large `true_delta`, clipping squashes the effect a little.

## Files

```
tea_inference_demo/
├── README.md                 this file
├── tea_inference_demo.Rproj  open this to start
├── tea_inference_demo.Rmd    the demo (R Markdown)
└── tea_inference_demo.R      the original plain-R script
```
