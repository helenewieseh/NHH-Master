###############################################################################
# Part 0 - Install and load packages --------------------------------------
###############################################################################
# Load libraries
library(readxl)
library(ggplot2)
library(gridExtra)
library(dplyr)
library(grid)
library(flextable)
library(officer)
library(scales)


###############################################################################
# Part A Task 1 
###############################################################################

# Data for Part A Task 1
task1_total_revenue <- 176018
total_revenue_formatted <- scales::dollar(task1_total_revenue, prefix = "$", format = "f", big.mark = ",")
task1_prices <- c(15.6368, 21.995, 32.6618, 25.6627, 40.5272, 44.7609, 40.6248)
task1_quantities <- c(705.528, 800, 800, 800, 800, 800, 800)
task1_revenue_per_day <- c(11032.23, 17595.98, 26129.46, 20530.16, 32421.73, 35808.69, 32499.87)
task1_utilization <- c("88.00%", "100.00%", "100.00%", "100.00%", "100.00%", "100.00%", "100.00%")

# Part A Task 1 Table
task1_data <- data.frame(
  Day = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"),
  Price = task1_prices,
  Quantity = task1_quantities,
  Revenue = task1_revenue_per_day,
  Utilization = task1_utilization
)
table_task1 <- flextable(task1_data) %>%
  add_header_lines(values = paste("Total Revenue:", total_revenue_formatted)) %>%
  # add footer note table 1
  add_footer_lines(values = "Table 1: Revenue and Utilization for Each Day of the Week") %>%
  set_header_labels(
    Day = "Day",
    Price = "Price ($)",
    Quantity = "Quantity",
    Revenue = "Revenue ($)",
    Utilization = "Utilization (%)"
  ) %>%
  autofit()

# Display Part A Task 1 Table
table_task1

###############################################################################
# Part A Task 2
###############################################################################

# Part A Task 2 Data - Friday as Weekday 
task2_total_revenue_weekday <- 142479
total_revenue_weekday_formatted <- scales::dollar(task2_total_revenue_weekday, prefix = "$", format = "f", big.mark = ",")
task2_prices_weekday <- c(25.1915, 40.1805)  # First element is weekday price, second is weekend price
task2_quantities_weekday <- c(101.149, 602.681, 800, 800, 800, 800, 800)
task2_revenue_per_day_weekday <- c(2548.09, 15182.41, 20153.17, 20153.17, 20153.17, 32144.42, 32144.42)
task2_utilization_weekday <- c("12.64%", "75.34%", "100%", "100%", "100%", "100%", "100%")

# Part A Task 2 Table - Friday as Weekday
task2_weekday_data <- data.frame(
  Day = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"),
  Price = c(rep(task2_prices_weekday[1], 5), task2_prices_weekday[2], task2_prices_weekday[2]),  # Use weekday price for Friday
  Quantity = task2_quantities_weekday,
  Revenue = task2_revenue_per_day_weekday,
  Utilization = task2_utilization_weekday
)

table_task2_weekday <- flextable(task2_weekday_data) %>%
  add_header_lines(values = paste("Total Revenue (Friday as Weekday):", total_revenue_weekday_formatted)) %>%
  add_footer_lines(values = "Scenario 1: Friday as Weekday") %>%
  set_header_labels(
    Day = "Day",
    Price = "Price ($)",
    Quantity = "Quantity",
    Revenue = "Revenue ($)",
    Utilization = "Utilization (%)"
  ) %>%
  autofit()

# Display Part A Task 2 Table - Friday as Weekday
table_task2_weekday


# Part A Task 2 Data - Friday as part of the Weekend 
task2_total_revenue_weekend <- 157150
total_revenue_weekend_formatted <- scales::dollar(task2_total_revenue_weekend, prefix = "$", format = "f", big.mark = ",")
task2_prices_weekend <- c(25.7642, 40.7205)
task2_quantities_weekend <- c(104.585, 610.699, 800, 800, 794.323, 800, 800)
task2_revenue_per_day_weekend <- c(2694.55, 15734.16, 20611.35, 20611.35, 32345.25, 32576.42, 32576.42)
task2_utilization_weekend <- c("13.07%", "76.34%", "100%", "100%", "99.29%", "100%", "100%")

# Part A Task 2 Table - Friday as Weekend
task2_weekend_data <- data.frame(
  Day = c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"),
  Price = c(rep(task2_prices_weekend[1], 4), task2_prices_weekend[2], task2_prices_weekend[2], task2_prices_weekend[2]),
  Quantity = task2_quantities_weekend,
  Revenue = task2_revenue_per_day_weekend,
  Utilization = task2_utilization_weekend
)
table_task2_weekend <- flextable(task2_weekend_data) %>%
  add_header_lines(values = paste("Total Revenue (Friday as part of the Weekend):", total_revenue_weekend_formatted)) %>%
  add_footer_lines(values = "Scenario 2: Friday as Weekend") %>%
  set_header_labels(
    Day = "Day",
    Price = "Price ($)",
    Quantity = "Quantity",
    Revenue = "Revenue ($)",
    Utilization = "Utilization (%)"
  ) %>%
  autofit()

# Display Part A Task 2 Table - Friday as Weekend
table_task2_weekend


###############################################################################
# Part B - Task 1: Plotting Supply and Demand Curves
###############################################################################

# Import the data
data <- read_excel("prøve.xlsx", sheet = "plot4")

# Filter out missing values to ensure continuous lines
data_supply <- data %>% filter(!is.na(Supply) & !is.na(`Supply linear`))
data_demand <- data %>% filter(!is.na(Demand) & !is.na(`Demand linear`))

# Plot 1: Linearized Curves
plot1 <- ggplot() +
  geom_point(data = data_supply, aes(x = Volume, y = `Supply linear`, color = "Supply linear")) +
  geom_line(data = data_supply, aes(x = Volume, y = `Supply linear`, group = 1, color = "Supply linear")) +
  geom_point(data = data_demand, aes(x = Volume, y = `Demand linear`, color = "Demand linear")) +
  geom_line(data = data_demand, aes(x = Volume, y = `Demand linear`, group = 1, color = "Demand linear")) +
  scale_color_manual(values = c("Supply linear" = "grey", "Demand linear" = "orange")) +
  labs(title = "Supply and Demand for Period Four\nLinearized Curves") + # Title in two lines
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14, color = "#6e6e6e"), 
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text = element_text(size = 10)
  )

# Plot 2: Step Function Curves 
plot2 <- ggplot() +
  geom_point(data = data_supply, aes(x = Volume, y = Supply, color = "Supply")) +
  geom_step(data = data_supply, aes(x = Volume, y = Supply, color = "Supply")) +
  geom_point(data = data_demand, aes(x = Volume, y = Demand, color = "Demand")) +
  geom_step(data = data_demand, aes(x = Volume, y = Demand, color = "Demand")) +
  scale_color_manual(values = c("Supply" = "#5a7d9a", "Demand" = "lightgreen")) +
  labs(title = "Supply and Demand for Period Four\nStep Function Curves") + 
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 14, color = "#6e6e6e"), 
    axis.title.x = element_blank(),
    axis.title.y = element_blank(),
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text = element_text(size = 10)
  )

# Combine plots 
combined <- grid.arrange(
  plot1, plot2, ncol = 2,
  bottom = textGrob("Figure 1: Supply and Demand for Period Four – Step Function and Linearized Curves", 
                    gp = gpar(fontface = "italic", fontsize = 12, col = "#6e6e6e"), hjust = 0.5)
)


###############################################################################
# Part B - Task 2 A: Calculating Equilibrium Price and Quantity
###############################################################################

# Table 4: Calculating Equilibrium Price and Quantity
data <- read_excel("datap3.xlsx", sheet = "SA3")

# Round the Profit column to remove decimals
data$Profit <- round(data$Profit)

# Create the flextable with formatting
table <- flextable(data) %>%
  set_header_labels(
    Iteration = "Iteration",
    Period = "Period",
    Price = "Price",
    Volume = "Volume",
    PS = "PS",
    S = "S",
    Bid = "Bid",
    Cost = "Cost",
    Quantity_Bid_MW = "Quantity Bid (MW)",
    Quantity_Accepted_MW = "Quantity Accepted (MW)",
    Profit = "Profit"
  ) %>%
  add_header_row(values = "Optimal Quantity and Price Tuning Across Multiple Iterations", colwidths = ncol(data)) %>%
  add_footer_row(values = "Table 4: Impact of Incremental Bid Adjustments in Quantity and Price on Period Profits", colwidths = ncol(data)) %>%
  align(align = "center", part = "all") %>%
  fontsize(size = 10, part = "all") %>%
  border_remove() %>%
  hline(i = 1, part = "header", border = fp_border(color = "black", width = 1)) %>% 
  hline_bottom(part = "header", border = fp_border(color = "black", width = 1)) %>% 
  autofit() %>%
  bg(i = ~ grepl("Sum", Iteration), bg = "#D3EAF2") %>% 
  bold(i = ~ grepl("Sum", Iteration), bold = TRUE, part = "body") %>% 
  hline(i = ~ grepl("Sum", Iteration), border = fp_border(color = "black", width = 1)) 

# Display the table
table

# Table 5: Calculating Equilibrium Price and Quantity
data <- read_excel("datap3.xlsx", sheet = "SA2")

# Round the Profit column to remove decimals
data$Profit <- round(data$Profit)

# Determine the total profit row index
total_profit_index <- nrow(data)

# Create the table
table <- flextable(data) %>%
  set_header_labels(
    Period = "Period",
    Price = "Price",
    Volume = "Volume",
    PS = "PS",
    s = "s",
    Bid = "Bid",
    Cost = "Cost",
    Quantity_Bid_MW = "Quantity Bid (MW)",
    Quantity_Accepted_MW = "Quantity Accepted (MW)",
    Profit = "Profit"
  ) %>%
  add_header_row(values = "Alternative Strategy - Reduced Quantity with Ask Price Tuning", colwidths = ncol(data)) %>%
  add_footer_row(values = "Table 5: Iteration Strategy with Reduced Quantity and Ask Price Tuning", colwidths = ncol(data)) %>%
  align(align = "center", part = "all") %>%
  fontsize(size = 10, part = "all") %>%
  bold(j = "Profit", i = total_profit_index) %>%  
  italic(part = "footer") %>%  
  color(color = "black", part = "footer") %>%
  bg(bg = "transparent", part = "all") %>%
  border_remove() %>%
  hline(i = 1, part = "header", border = fp_border(color = "black", width = 1)) %>%  
  hline_bottom(part = "header", border = fp_border(color = "black", width = 1)) %>% 
  hline(i = total_profit_index, part = "body", border = fp_border(color = "black", width = 1)) %>%  
  autofit()

# Display the table
table

###############################################################################
# Part B task 2 B: Calculating Equilibrium Price and Quantity
###############################################################################

# Import data
data <- read_excel("datap3.xlsx", sheet = "SB1")

# Round the Profit column to remove decimals
data$Profit <- round(data$Profit)

# Find the optimal (highest) profit for each period
data <- data %>%
  group_by(Period) %>%
  mutate(optimal_strategy = Profit == max(Profit)) %>%
  ungroup()

# Identify the last row index for each unique period
last_rows <- data %>%
  mutate(row_num = row_number()) %>%
  group_by(Period) %>%
  filter(row_num == max(row_num)) %>%
  pull(row_num)

# Create the table 
table <- flextable(data) %>%
  set_header_labels(
    Iteration = "Iteration",
    Period = "Period",
    Quantity_Bid_MW = "Quantity Bid (MW)",
    Quantity_Accepted_MW = "Quantity Accepted (MW)",
    Ask_price = "Ask Price",
    Equilibrium_Price = "Equilibrium Price",
    Cost = "Cost",
    Revenue = "Revenue",
    Profit = "Profit",
    optimal_strategy = "Optimal Strategy"  
  ) %>%
  add_header_row(values = "Optimal Quantity and Price Tuning Across Multiple Iterations", colwidths = ncol(data)) %>%
  add_footer_row(values = "Table 6: Impact of Incremental Bid Adjustments in Quantity and Price on Period Profits", colwidths = ncol(data)) %>%
  align(align = "center", part = "all") %>%
  fontsize(size = 10, part = "all") %>%
  italic(j = 1, part = "footer") %>%  
  color(color = "black", part = "footer") %>%
  bg(bg = "transparent", part = "all") %>%
  border_remove() %>%
  hline_bottom(part = "header", border = fp_border(color = "black", width = 1)) %>%  
  autofit() %>%
  bg(i = ~ optimal_strategy == TRUE, bg = "#D3EAF2")  

# Apply lines after each period's last row
for (row in last_rows) {
  table <- hline(table, i = row, part = "body", border = fp_border(color = "black", width = 1))
}

# Display the table with caption
table


# Table 6: Calculating Equilibrium Price and Quantity
data <- read_excel("datap3.xlsx", sheet = "SB2")

# Round the Profit column to remove decimals
data$Profit <- round(data$Profit)

# Determine the total profit row index 
total_profit_index <- nrow(data)

# Create the table
table <- flextable(data) %>%
  set_header_labels(
    Period = "Period",
    Price = "Price",
    Volume = "Volume",
    PS = "PS",
    s = "s",
    Bid = "Bid",
    Cost = "Cost",
    Quantity_Bid_MW = "Quantity Bid (MW)",
    Quantity_Accepted_MW = "Quantity Accepted (MW)",
    Profit = "Profit"
  ) %>%
  add_header_row(values = "Optimal Bidding Strategy", colwidths = ncol(data)) %>%
  add_footer_row(values = "Table 7: Optimal Profit Outcomes through Price Tuning and Flexible Quantities", colwidths = ncol(data)) %>%
  align(align = "center", part = "all") %>%
  fontsize(size = 10, part = "all") %>%
  bold(j = "Profit", i = total_profit_index) %>%  
  italic(part = "footer") %>%  
  color(color = "black", part = "footer") %>%
  bg(bg = "transparent", part = "all") %>%
  border_remove() %>%
  hline(i = 1, part = "header", border = fp_border(color = "black", width = 1)) %>% 
  hline_bottom(part = "header", border = fp_border(color = "black", width = 1)) %>%  
  hline(i = total_profit_index, part = "body", border = fp_border(color = "black", width = 1)) %>%  
  autofit()

# Display the table
table

###############################################################################
# Part B - Task 3: Plotting Equilibrium Price and Quantity
###############################################################################

# Import the data
data <- read_excel("datap3.xlsx", sheet = "SC1")

# Round the Profit column to remove decimals
data$Profit <- round(data$Profit)

# Rank the profit values to assign unique colors based on ranking
data <- data %>%
  mutate(profit_rank = rank(Profit, ties.method = "first"),
         `Profit Scale` = round(profit_rank / max(profit_rank), 3))  # Limit to 3 decimals

# Generate a lighter color gradient without dark colors 
color_gradient <- colorRampPalette(c("lightcoral", "lightsalmon", "lightyellow", "palegreen", "lightgreen"))(max(data$profit_rank))

# Map each rank to a specific color in the gradient
data <- data %>%
  mutate(profit_color = color_gradient[profit_rank])

# Remove the profit_color and profit_rank columns from the table data to avoid displaying them
table_data <- data %>% select(-profit_color, -profit_rank)

# Create the table with color shading in the Profit column based on the ranking
table <- flextable(table_data) %>%
  set_header_labels(
    Volume_MW = "Volume (MW)",
    Ask_price = "Ask Price",
    Price_P2 = "Price P2",
    Price_P3 = "Price P3",
    Price_P4 = "Price P4",
    Price_P5 = "Price P5",
    Cost = "Cost",
    Profit = "Profit",
    `Profit Scale` = "Profit Scale",
    Strategy = "Strategy"
  ) %>%
  add_header_row(values = "Profit Optimization through Incremental Quantity and Price Tuning", colwidths = ncol(table_data)) %>%
  add_footer_row(values = "Table 8: Comparative Profit Outcomes Across Different Quantity and Pricing Configurations", colwidths = ncol(table_data)) %>%
  align(align = "center", part = "all") %>%
  fontsize(size = 10, part = "all") %>%
  italic(part = "footer") %>%
  color(color = "black", part = "footer") %>%
  bg(bg = "transparent", part = "all") %>%
  border_remove() %>%
  hline(i = 1, part = "header", border = fp_border(color = "black", width = 1)) %>%  
  hline_top(part = "body", border = fp_border(color = "black", width = 1)) %>%  
  hline(i = nrow(table_data), part = "body", border = fp_border(color = "black", width = 1)) %>%  
  autofit() %>%
  bg(i = 1:nrow(table_data), j = "Profit", bg = data$profit_color)  # Apply color based on the profit_color column

# Display the table
table

# Table 9: Calculating Equilibrium Price and Quantity
data <- read_excel("datap3.xlsx", sheet = "SC2")

# Round the Profit column to remove decimals
data$Profit <- round(data$Profit)

# Determine the total profit row index 
total_profit_index <- nrow(data)

# Create the table
table <- flextable(data) %>%
  set_header_labels(
    Period = "Period",
    Price = "Price",
    Volume = "Volume",
    PS = "PS",
    s = "s",
    Bid = "Bid",
    Cost = "Cost",
    Quantity_Bid_MW = "Quantity Bid (MW)",
    Quantity_Accepted_MW = "Quantity Accepted (MW)",
    Profit = "Profit"
  ) %>%
  add_header_row(values = "Optimal Results with Block Bids", colwidths = ncol(data)) %>%
  add_footer_row(values = "Table 9: Highest Profit Realized Through Optimized Block Bidding Approach", colwidths = ncol(data)) %>%
  align(align = "center", part = "all") %>%
  fontsize(size = 10, part = "all") %>%
  bold(j = "Profit", i = total_profit_index) %>%  
  italic(part = "footer") %>%  # Italicize the caption
  color(color = "black", part = "footer") %>%
  bg(bg = "transparent", part = "all") %>%
  border_remove() %>%
  hline(i = 1, part = "header", border = fp_border(color = "black", width = 1)) %>%  
  hline_bottom(part = "header", border = fp_border(color = "black", width = 1)) %>%  
  hline(i = total_profit_index, part = "body", border = fp_border(color = "black", width = 1)) %>%  
  autofit()

# Display the table
table
