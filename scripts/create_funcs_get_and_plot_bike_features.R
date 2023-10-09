# Load Required Packages
library(tidyverse)
library(tidyquant)
library(plotly)

# Source Scripts
source("scripts/funcs_separate_bike_models.R")

# Read CSV File
bike_data_tbl <- read_csv("data_clean/bike_data.csv")

# Function to retrieve and preprocess bike features
get_bike_features <- function() {
    
    # Retrieve and preprocess bike features
    bike_features_tbl <- bike_data_tbl %>%
        select(price, model, category_1, category_2, frame_material) %>%
        distinct() %>%
        mutate(id = row_number()) %>%
        select(id, everything()) %>%
        separate_bike_models(keep_model_column = TRUE, append = TRUE)
    
    return(bike_features_tbl)
    
}

# Function to plot bike features
plot_bike_features <- function(interactive = TRUE) {
    
    # Retrieve and preprocess bike features
    bike_features_tbl <- get_bike_features()
    
    # Visualization
    g <- bike_features_tbl %>%
        mutate(category_2 = fct_reorder(category_2, price)) %>%
        mutate(label_text = str_glue("Model: {model}
                                  Price: {scales::dollar(price)}")) %>%
        ggplot(aes(category_2, price)) +
        geom_violin() +
        geom_jitter(aes(text = label_text), width = 0.1, color = "#2c3e50", alpha = 0.5) +
        facet_wrap(~ frame_material) +
        coord_flip() +
        theme_tq() +
        theme(strip.text.x = element_text(margin = margin(5, 5, 5, 5, unit = "pt"))) +
        labs(title = "Product Gap Analysis", x = "", y = "") +
        scale_y_continuous(labels = scales::dollar_format())
    
    # Interactive vs Static
    if (interactive) {
        return(ggplotly(g, tooltip = "text"))
    } else {
        return(g)
    }
    
}

# Test Functions
get_bike_features()
plot_bike_features()
plot_bike_features(interactive = FALSE)

# Save Functions
function_names <- c("get_bike_features", "plot_bike_features")
dump(function_names, file = "scripts/funcs_get_and_plot_bike_features.R")
