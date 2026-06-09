---
pillar: personal-projects
title: "Before the Lights Go Out: Predicting Formula 1 Race Outcomes with Machine Learning"
permalink: /projects/predict-f1-race/
excerpt: "A machine-learning study that predicts F1 finishing position and points-scoring finishes from 18 pre-race features, comparing 15 models across regression and classification."
header:
  teaser: /assets/images/projects/f1-prediction/f1-hero.jpg
  image: /assets/images/projects/f1-prediction/f1-hero.jpg
categories:
  - Machine Learning
tags:
  - machine-learning
  - data-science
  - python
  - scikit-learn
---

**Timeframe:** Team project (UC Berkeley)  
**Role:** Co-author — data cleaning, modeling, and analysis  
**Team:** Zonghan Li, Hanxiao Zhang, Yiren Rong, Fengze Du, Di Tian  
**Tools:** Python, scikit-learn, pandas, NumPy, Matplotlib

## Project Overview
Formula 1 is the world's most prestigious motorsport: 20 drivers from 10 teams race around a circuit as fast as possible over 50–70 laps, and every season teams spend hundreds of millions of dollars chasing a faster car, the best drivers, and smarter strategy. That makes constructor, driver, and strategy the biggest factors separating winners from losers. We asked a simple question: **given everything we know about a driver and team's past performance, the circuit, pit-stop strategy, and weather before the race begins, can a machine-learning model predict where a driver will finish — and whether they will score points?**

The study uses historical F1 data from the 2018–2024 seasons and frames the problem as two distinct tasks: a **regression** task that predicts the exact finishing position (1–20), and a **binary classification** task that predicts a top-10 (points-scoring) finish. We trained, tuned, and compared 15 models in total and found that a tuned Gradient Boosting model was the strongest on both tasks.

## What Goes Into a Prediction
Before modeling, it helps to see what the model actually "knows" about each race entry. The 18 input features group into five families: who's driving and for which team, how they've performed recently, their pit-stop strategy, the weather, and the broader race context.

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/features-overview.png" alt="The 18 input features grouped into five categories">
  <figcaption>The 18 inputs span five families — driver and team identity, past performance, pit-stop strategy, weather, and race context. Driver and team rolling history are the most powerful raw predictors.</figcaption>
</figure>

## Data
The dataset comes from the Kaggle "Pitstop Pulse: Formula 1 Performance Data" collection, which compiles race telemetry across the 2018–2024 seasons. The raw data contained **7,374 rows × 30 columns**, where each row is a single stint (a continuous run on one set of tyres) for one driver in one race. Because race-level attributes such as finishing position and weather repeat identically across the stint rows of the same driver and race, we aggregated to **one row per driver per race**, yielding **2,679 race-level observations** built from 18 input features.

A quick check confirmed the target was well balanced — finishing positions 1–20 each appear about equally often, so no class is artificially rare and accuracy is a meaningful metric.

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/position-distribution.png" alt="Distribution of finishing positions across the dataset">
  <figcaption>Finishing position is close to uniform across P1–P20 — roughly 140 observations per position — so the label is well balanced for both tasks.</figcaption>
</figure>

## Exploratory Analysis
A few patterns stood out immediately and shaped how we trusted the later models.

Constructor is the single biggest lever. Sorting average finishing position by team reproduces the real-world pecking order of the era — Mercedes, Red Bull, and Ferrari at the sharp end, the smaller teams trailing — which is exactly why team rolling history later dominates feature importance.

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/eda-constructor.png" alt="Average finishing position by constructor">
  <figcaption>Average finishing position by constructor (2018–2024). The ordering matches the real competitive hierarchy, confirming the data is sensible before modeling.</figcaption>
</figure>

Strategy and environment tell a more nuanced story. Drivers making zero pit stops are almost always those who retired early and finished near the back, while one- and two-stop races cluster toward the front. Meanwhile track temperature and driver "aggression" scores show no clear relationship with the result — a useful early signal that weather and behaviour features would add little.

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/eda-pitstops.png" alt="Finishing position versus total pit stops">
  <figcaption>Finishing position vs total pit stops. Zero-stop entries are mostly retirements at the back; one- and two-stop races skew toward the front.</figcaption>
</figure>

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/eda-tracktemp.png" alt="Finishing position versus track temperature">
  <figcaption>Track temperature shows no clear trend against finishing position — an early hint that weather features would contribute little predictive value.</figcaption>
</figure>

## Data Cleaning
Most of the engineering effort went into preparing the data rather than fitting models. Three problems mattered most.

**Aggregation.** We collapsed the 7,374 stint rows into 2,679 race-level rows by taking the first value for race-level attributes, the mean for stint-level numerics (stint length, pit lap), and the mode for tyre compound.

**Data leakage.** Initial modeling produced a suspicious **R² = 1.000** — a perfect score that signals a feature secretly encoding the answer. A correlation check made the culprits obvious: *pit_efficiency* and *Lap Time Variation* are perfectly correlated (r = 1.00) and both are computed from post-race telemetry, while *Position Changes* is derived directly from the finishing position. Removing these result-derived features was essential to make the prediction task honest.

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/correlation-matrix.png" alt="Correlation matrix of candidate features">
  <figcaption>Correlation matrix used to hunt for leakage. The perfect 1.00 correlation between <strong>pit_efficiency</strong> and <strong>Lap Time Variation</strong> flagged post-race features that had to be dropped; team and driver history (r = 0.58 and 0.51 with Position) are the legitimate signal.</figcaption>
</figure>

**Outliers and missing values.** Several behaviour-score columns had extreme outliers (Fast Lap Attempts peaked at 2,989 against a median of 43 — a 70× spike), which we compressed with IQR-based capping. Missing weather values were imputed with circuit-level medians and missing behaviour scores with season-level medians. Legacy Pirelli tyre names (HYPERSOFT, ULTRASOFT, SUPERSOFT) were mapped to their modern SOFT equivalent.

## Preventing the Models from Memorizing Identities
A subtle risk: the label-encoded identity features (driver, team, and circuit) could let a model *memorize* "driver 12 usually finishes P3" instead of learning what makes any driver finish P3 — which looks great in training but fails on new drivers or mid-season team changes. We addressed this three ways: we engineered continuous **rolling historical-position** features so identity information enters in a generalizable form; we kept the raw encodings alongside them to capture fixed effects the rolling averages smooth over (e.g. a mid-season car upgrade); and we used an **80/10/10 split** with validation-based tuning so any memorization is penalized. The best model showed a train-vs-validation R² gap below 0.10, confirming it generalized rather than memorized.

## Methods
We treated the problem as two supervised-learning tasks and tuned every model's hyperparameters on the validation set, evaluating the test set only once at the end for unbiased final numbers.

**Task A — Regression** predicts the exact finishing position (1–20). We trained eight models: Linear Regression, Ridge, Lasso, K-Nearest Neighbors, Decision Tree, Random Forest, Gradient Boosting, and a Neural Network (MLP). Metrics: R², RMSE, and MAE in positions.

**Task B — Classification** predicts a top-10 finish as a binary outcome. We trained seven models: Logistic Regression, KNN, Decision Tree, Random Forest, Gradient Boosting, SVM (RBF kernel), and a Neural Network. Metrics: Accuracy, F1, and AUC-ROC.

## Results

### Task A — Regression
Ensemble methods clearly outperformed linear and distance-based models, confirming the relationships are non-linear and hierarchical. Tuned **Gradient Boosting** led with R² = 0.658, ahead of Random Forest (0.620) and the Neural Network (0.599). The linear models cluster near 0.495 because they assume additive effects and miss interactions such as the combined influence of driver and team; KNN trails because label-encoding distorts the distances it relies on.

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/regression-comparison.png" alt="Regression models ranked by R-squared">
  <figcaption>All eight regression models ranked by R². Tuned Gradient Boosting tops the chart at 0.6584; linear models plateau near 0.495 and KNN is weakest at 0.439.</figcaption>
</figure>

### Task B — Classification
The same ordering held for predicting points-scoring finishes. Tuned Gradient Boosting again led on every metric — accuracy 0.805, F1 0.808, and AUC 0.888 — with the Neural Network and Random Forest just behind.

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/classification-accuracy.png" alt="Classification models ranked by accuracy">
  <figcaption>Top-10-finish accuracy by model. Tuned Gradient Boosting (0.805) edges the Neural Network (0.801) and Random Forest (0.791); KNN is lowest at 0.706.</figcaption>
</figure>

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/classification-f1.png" alt="Classification models ranked by F1 score">
  <figcaption>F1 score, which balances precision and recall, follows the same ranking — Gradient Boosting first at 0.808.</figcaption>
</figure>

The ROC curves make the separation visual: every model beats the random baseline, and Gradient Boosting sits highest with AUC ≈ 0.888.

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/roc-curves.png" alt="ROC curves for all classifiers">
  <figcaption>ROC curves for all seven classifiers. Gradient Boosting (AUC 0.888) dominates; KNN (0.799) is closest to the random diagonal.</figcaption>
</figure>

The normalized confusion matrices show correct-classification rates of roughly 0.75–0.84. Tree-based models are slightly stronger at catching genuine top-10 finishers (Gradient Boosting and Decision Tree both hit 0.82 on the Top-10 class), while the Neural Network is the most conservative — best at rejecting non-scorers (0.84) but more cautious about predicting a points finish.

<figure class="align-center">
  <img src="/assets/images/projects/f1-prediction/confusion-matrices.png" alt="Normalized confusion matrices for all classifiers">
  <figcaption>Normalized confusion matrices across all seven classifiers, comparing how each separates Top-10 from Not-Top-10 finishes.</figcaption>
</figure>

## Conclusion
Gradient Boosting was the best model on **both** tasks, achieving the highest R² in regression and the top Accuracy, F1, and AUC in classification. The consistency tells a clear story: F1 finishing order is **not** a simple linear function of its inputs, and models that capture non-linear feature interactions and correct their own errors iteratively have a real edge. Random Forest and the Neural Network are strong runners-up; linear models remain useful when interpretability matters; and distance-based KNN should be avoided unless categorical encoding is handled more carefully.

The most valuable lesson was not which model won, but how much the result depended on *honest data work* — catching the data leakage that produced a fake perfect score, and engineering identity features that generalize instead of memorize. Those steps were the difference between a model that looks impressive on paper and one that actually predicts an unseen race.

## Links
- [Project Site — Highlights](https://sites.google.com/berkeley.edu/team15-predict-f1-race/highlights)
- [Project Site — Methods](https://sites.google.com/berkeley.edu/team15-predict-f1-race/methods)
- [Project Site — Results](https://sites.google.com/berkeley.edu/team15-predict-f1-race/results)
- [Dataset — Pitstop Pulse: Formula 1 Performance Data (Kaggle)](https://www.kaggle.com/datasets/eshummalik/pitstop-pulse-formula-1-performance-data)
