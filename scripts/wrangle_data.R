# Load Required Packages
library(tidyverse)  
library(readxl)     

# Read Excel Files
bikes_tbl <- read_excel("data_raw/bikes.xlsx")
bikeshops_tbl <- read_excel("data_raw/bikeshops.xlsx")
orderlines_tbl <- read_excel("data_raw/orderlines.xlsx")

# Preview Data Structure
glimpse(bikes_tbl)       
glimpse(bikeshops_tbl)   
glimpse(orderlines_tbl)  

# Join Data Tibbles
joined_tbl <- orderlines_tbl %>%
    left_join(bikes_tbl, by = c("product.id" = "bike.id")) %>%
    left_join(bikeshops_tbl, by = c("customer.id" = "bikeshop.id"))

# Data Wrangling
wrangled_tbl <- joined_tbl %>%
    separate(description,
             into = c("category.1", "category.2", "frame.material"),
             sep = " - ") %>%
    separate(location,
             into = c("city", "state"),
             sep  = ", ") %>%
    mutate(total.price = price * quantity) %>%
    select(-`...1`, -customer.id, -product.id) %>%
    select(order.date, contains("order"),
           quantity, price, total.price,
           everything()) %>%
    set_names(names(.) %>% str_replace_all("\\.", "_"))

# Write Wrangled Data to CSV
wrangled_tbl %>%
    write_csv("data_clean/bike_data.csv")
