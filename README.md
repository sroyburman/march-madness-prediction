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

