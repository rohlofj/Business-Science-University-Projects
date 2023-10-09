# Load Required Packages
library(tidyverse)
library(rsample)
library(parsnip)
library(yardstick)

# Source Scripts
source("scripts/funcs_separate_bike_models.R")

# Read CSV File
bike_data_tbl <- read_csv("data_clean/bike_data.csv")

# Preview Data Structure
glimpse(bike_data_tbl)

# Retrieve and preprocess bike features
bike_features_tbl <- bike_data_tbl %>%
    select(price, model, category_2, frame_material) %>%
    distinct() %>%
    mutate(id = row_number()) %>%
    select(id, everything()) %>%
    separate_bike_models(keep_model_column = TRUE, append = TRUE)

# Train / Test Splits
set.seed(0)
split_obj <- initial_split(bike_features_tbl, prop = 0.80, strata = "model_base")
train_tbl <- training(split_obj)
test_tbl  <- testing(split_obj)

# *** FIX 1 *** 
# Error: factor model_base has new levels Fat CAAD1
# - Need to move Fat CAAD1 from test to training set because model doesn't know how to handle
#   a new category that is unseen in the training data

train_tbl <- train_tbl %>%
    bind_rows(
        test_tbl %>% filter(model_base %>% str_detect("Fat CAAD1"))
    )

test_tbl <- test_tbl %>%
    filter(!model_base %>% str_detect("Fat CAAD1"))

# *** END FIX 1 *** 

# Create XGBoost Model
set.seed(0)
model_boost_tree_xgboost <- boost_tree(
    mode = "regression", 
    mtry = 30,
    learn_rate = 0.25,
    tree_depth = 7
) %>%
    set_engine("xgboost") %>%
    fit(price ~ ., data = train_tbl %>% select(-id, -model, -model_tier))

# Function to Evaluate Model
calc_metrics <- function(model, new_data = test_tbl) {
    model %>%
        predict(new_data = new_data) %>%
        bind_cols(new_data %>% select(price)) %>%
        metrics(truth = price, estimate = .pred)
    
}

# Evaluate Model
model_boost_tree_xgboost %>% calc_metrics(test_tbl)

# Save Model to RDS
model_xgboost_tbl <- list(
    model_xgboost = model_boost_tree_xgboost
) %>%
    enframe(name = "model_id", value = "model")

model_xgboost_tbl %>% 
    write_rds("models/model_xgboost_tbl.rds")
