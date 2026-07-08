---
title: "2026 March Madness Predictions"
author: "Sage Roy-Burman"
format: html
---

library(hoopR)
library(dplyr)
library(ggplot2)
library(scales)

# ── Step 1: Load and clean 2026 regular season data ───────────────

# Loads full MBB schedule/results with home/away/neutral already coded
mbb_2024 <- load_mbb_schedule(seasons = 2024)
mbb_2025 <- load_mbb_schedule(seasons = 2025)
mbb_2026 <- load_mbb_schedule(seasons = 2026)

# Load all three seasons
raw <- load_mbb_schedule(seasons = c(2024, 2025, 2026))

clean <- raw %>%
  # Keep only completed regular season games
  # season_type == 2 is regular season; 3 is post-season
  # status_type_completed filters out cancelled/postponed games
  filter(
    season_type == 2,
    status_type_completed == TRUE
  ) %>%
  
  # Convert scores from character to numeric
  mutate(
    home_score = as.numeric(home_score),
    away_score = as.numeric(away_score)
  ) %>%
  
  # Remove games with missing scores
  filter(!is.na(home_score), !is.na(away_score)) %>%
  
  # Create the key variables the paper's code needs
  mutate(
    # MOV from home team's perspective (response variable y_uvw)
    diff = home_score - away_score,
    
    # conf_tourn flag — notes_headline contains tournament info
    # season_type == 2 means regular season so this is FALSE for all
    conf_tourn = FALSE,
    
    # neutral site indicator (1 = true home game, 0 = neutral)
    non_neutral = as.numeric(!neutral_site)
  ) %>%
  
  # Select and rename to match the paper's expected format
  select(
    HomeTeam   = home_location,   # e.g. "Duke", "Kansas"
    AwayTeam   = away_location,
    diff,                          # HomeScore - AwayScore
    conf_tourn,
    non_neutral,
    year       = season
  )

train <- clean %>%
  filter(year == 2026, conf_tourn == FALSE)



# ── Step 2: Build Harville model design matrix ────────────────────

all_teams <- sort(unique(c(train$HomeTeam, train$AwayTeam)))
n_teams <- length(all_teams)
n_games <- nrow(train)

# Drop last team as baseline
baseline_team <- all_teams[n_teams]

X <- matrix(0, nrow = n_games, ncol = n_teams)
colnames(X) <- c("intercept", all_teams[-n_teams])

for (i in 1:n_games) {
  X[i, "intercept"] <- train$non_neutral[i]
  
  h <- train$HomeTeam[i]
  a <- train$AwayTeam[i]
  
  if (h %in% colnames(X)) X[i, h] <- 1
  if (a %in% colnames(X)) X[i, a] <- -1
}

y <- train$diff

fit <- lm(y ~ 0 + X)

strengths <- coef(fit)
names(strengths) <- gsub("^X", "", names(strengths))

strengths <- c(
  strengths[!names(strengths) %in% "intercept"],
  setNames(0, baseline_team)
)

ranking <- sort(strengths, decreasing = TRUE)

head(ranking, 10)



# ── Step 3: Conformal win probability function ───────────────
# Only evaluates yc = 0, because P(win) = P(MOV > 0) = 1 - pi(0)

conformal_wp_fast <- function(home_team, away_team, X, y, tau = 0.5) {
  
  if (is.na(home_team) || home_team == "") {
    stop("Invalid home_team")
  }
  if (is.na(away_team) || away_team == "") {
    stop("Invalid away_team")
  }
  
  x_new <- rep(0, ncol(X))
  names(x_new) <- colnames(X)
  
  # Neutral-site tournament game
  x_new["intercept"] <- 0
  
  if (home_team %in% names(x_new)) {
    x_new[home_team] <- 1
  }
  
  if (away_team %in% names(x_new)) {
    x_new[away_team] <- -1
  }
  
  X_aug <- rbind(X, x_new)
  y_aug <- c(y, 0)
  
  fit_aug <- lm(y_aug ~ 0 + X_aug)
  resids <- fit_aug$residuals
  
  n_aug <- length(resids)
  R_new <- resids[n_aug]
  R_train <- resids[-n_aug]
  
  pi_0 <- (sum(R_train < R_new) + tau * sum(R_train == R_new)) / n_aug
  
  win_prob <- 1 - pi_0
  
  return(win_prob)
}



# ── Step 4: Manual Round of 64 bracket order ──────────────────────
# Have to make sure row 1 winner plays row 2 winner, row 3 winner plays row 4 winner, etc.

round64_manual <- tibble::tribble(
  ~bracket_position, ~team1, ~team2, ~non_neutral,
   1, "Michigan", "Howard", 0,
   2, "Georgia", "Saint Louis", 0,
   3, "Texas Tech", "Akron", 0,
   4, "Alabama", "Hofstra", 0,
   5, "Tennessee", "Miami (OH)", 0,
   6, "Virginia", "Wright State", 0,
   7, "Kentucky", "Santa Clara", 0,
   8, "Iowa State", "Tennessee State", 0,
   9, "BYU", "Texas", 0,
   10, "Gonzaga", "Kennesaw State", 0,
   11, "Purdue", "Queens University", 0,
   12, "Miami", "Missouri", 0,
   13, "Wisconsin", "High Point", 0,
   14, "Arkansas", "Hawai'i", 0,
   15, "Arizona", "Long Island University", 0,
   16, "Villanova", "Utah State", 0,
   17, "Florida", "Prairie View A&M", 0,
   18, "Clemson", "Iowa", 0,
   19, "Nebraska", "Troy", 0,
   20, "Vanderbilt", "McNeese", 0,
   21, "North Carolina", "VCU", 0,
   22, "Illinois", "Pennsylvania", 0,
   23, "Saint Mary's", "Texas A&M", 0,
   24, "Houston", "Idaho", 0,
   25, "Ohio State", "TCU", 0,
   26, "Duke", "Siena", 0,
   27, "St. John's", "Northern Iowa", 0,
   28, "Kansas", "California Baptist", 0,
   29, "Louisville", "South Florida", 0,
   30, "Michigan State", "North Dakota State", 0,
   31, "UCLA", "UCF", 0,
   32, "UConn", "Furman", 0
) %>%
  arrange(bracket_position)

stopifnot(nrow(round64_manual) == 32)
stopifnot(all(round64_manual$bracket_position == 1:32))

# ── Step 5: Check team-name matching ──────────────────────────────

bracket_teams <- unique(c(round64_manual$team1, round64_manual$team2))

missing_from_X <- setdiff(bracket_teams, colnames(X))

cat("Teams missing from X:\n")
print(missing_from_X)

cat("Baseline team:", baseline_team, "\n")



# ── Step 6: Precompute all pairwise win probabilities ─────────────

all_bracket_teams <- unique(c(round64_manual$team1, round64_manual$team2))
n_teams_bracket <- length(all_bracket_teams)

wp_cache <- list()

for (i in 1:(n_teams_bracket - 1)) {
  for (j in (i + 1):n_teams_bracket) {
    
    t1 <- all_bracket_teams[i]
    t2 <- all_bracket_teams[j]
    
    key <- paste(t1, t2, sep = "_vs_")
    key_rev <- paste(t2, t1, sep = "_vs_")
    
    wp <- conformal_wp_fast(t1, t2, X, y)
    
    wp_cache[[key]] <- wp
    wp_cache[[key_rev]] <- 1 - wp
    
    cat("Computed:", key, "->", round(wp, 3), "\n")
  }
}

saveRDS(wp_cache, "wp_cache_2026_fast.RDS")

# ── Step 7: Tournament simulation function ────────────────────────

simulate_tournament <- function(round64_manual, wp_cache) {
  
  teams <- c(rbind(round64_manual$team1, round64_manual$team2))
  
  while (length(teams) > 1) {
    
    next_round <- c()
    
    for (i in seq(1, length(teams), by = 2)) {
      
      t1 <- teams[i]
      t2 <- teams[i + 1]
      key <- paste(t1, t2, sep = "_vs_")
      
      wp <- wp_cache[[key]]
      
      if (is.null(wp)) {
        stop(paste("Missing win probability for", key))
      }
      
      winner <- ifelse(runif(1) < wp, t1, t2)
      next_round <- c(next_round, winner)
    }
    
    teams <- next_round
  }
  
  return(teams)
}

# ── Step 8: Run simulations ───────────────────────────────────────

n_sims <- 10000
set.seed(2026)

winners <- replicate(
  n_sims,
  simulate_tournament(round64_manual, wp_cache)
)

# ── Step 9: Championship probability table ────────────────────────

win_probs_df <- data.frame(
  team = names(sort(table(winners), decreasing = TRUE)),
  win_prob = as.numeric(sort(table(winners), decreasing = TRUE)) / n_sims
)

head(win_probs_df, 10)



# ── Step 10: Plot top teams ───────────────────────────────────────

win_probs_df %>%
  head(15) %>%
  ggplot(aes(x = reorder(team, win_prob), y = win_prob)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = NULL,
    y = "Championship Probability",
    title = "2026 NCAA Tournament Win Probabilities",
    subtitle = "Conformal Probabilities | 2025-26 regular season data"
  ) +
  theme_minimal()



# ── Step 11: Check actual winner ──────────────────────────────────

actual_winner <- "Michigan"

predicted_rank <- match(actual_winner, win_probs_df$team)

if (is.na(predicted_rank)) {
  cat("Actual winner:", actual_winner, "\n")
  cat("Predicted rank: not in simulated winners\n")
  cat("Predicted championship probability: 0%\n")
} else {
  predicted_prob <- win_probs_df$win_prob[predicted_rank]
  
  cat("Actual winner:", actual_winner, "\n")
  cat("Predicted rank:", predicted_rank, "out of", nrow(win_probs_df), "\n")
  cat("Predicted championship probability:", round(predicted_prob * 100, 1), "%\n")
}
