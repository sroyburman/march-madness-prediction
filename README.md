# March Madness Prediction

This project builds a statistical model to predict NCAA Men's Basketball Tournament outcomes using regular-season college basketball data. The model estimates team strength based on historical game results, converts matchup predictions into conformal win probabilities, and simulates the tournament bracket thousands of times to estimate each team's likelihood of winning the national championship.

## Project Overview

The goal of this project is to evaluate to what extent regular-season performance can be used to predict March Madness outcomes. Because the NCAA Tournament is single-elimination and played at neutral sites, this project focuses on estimating team strength, modeling head-to-head win probabilities, and simulating bracket outcomes. This project uses NCAA regular season schedule and results data from the hoopR package and implements a Harville team strength model along with conformal prediction.

## Methods

The project follows this workflow:

1. Load and clean NCAA Division 1 men's basketball data using hoopR
2. Filter for completed 2024-2026 regular-season games
3. Estimate different team strengths using margin of victory
4. Build a design matrix comparing home and away teams
5. Fit a linear model to estimate relative team strength
6. Compute neutral-site win probabilities using conformal prediction
7. Simulate the tournament bracket 10,000 times
8. Estimate championship probabilities for each team

## Model

The model estimates team strength based on game-level margin of victory:

diff = home score - away score

Each game is represented using a design matrix where the home team receives a +1, the away team receives a -1, and one team is dropped as a baseline. The model also gives a home-court indicator for non-neutral games. 

After estimating team strenghts, the project uses conformal prediction to generate win probabilities for neutral-site tournament games. These probabilities are then used in Monte Carlo simulation.

## Tournament Simulation

The bracket is simulated 10,000 times. In each simulated tournament, every matchup is decided probabilistically using the precomputed win probability between the two teams. Winners advance round-by-round until a champion is announced. The final output is a championship probability table showing which teams are most likely to be crowned according to the model.

## Results

The model produces estimated championship probabilities for each team in the tournament. The final vizualization shows the top teams by simulated probability of winning the national championship. 

Key outputs include:

1. Team strength rankings
2. Pairwise matchup win probabilities
3. Simulated tournament champions
4. Championship probability table
5. Bar chart of top title contenders

## Skills Demonstrated

- R programming
- Data cleaning with dplyr
- Linear modeling
- Design matrix construction
- Conformal prediction
- Monte Carlo simulation
- Data vizualization with ggplot2
- Probabilistic forecasting
- Sports analytics

## Packages Used

library(hoopR);
library(dplyr);
library(ggplot2);
library(scales)

## Possible Extensions

Some potential extensions:

- Adding team efficiency metrics
- Using player-level data
- Incorporating injuries
- Using seed information
- Backtesting performance across previous tournaments
- Testing gradient boosting, logistic regression, or random forests
