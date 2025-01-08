
# Import necessary libraries ----------------------------------------------
install.packages("flextable") # Allows you to create tables with a flexible layout
install.packages("webshot") # Allows you to take screenshots of web pages
install.packages("magrittr") # Provides a way to pipe data and functions
install.packages("officer") # Allows you to create and manipulate Microsoft Word and PowerPoint documents
install.packages("dplyr") # Provides tools for data manipulation
install.packages("tidyverse") # A collection of packages for data manipulation and visualization
install.packages("gt") # Allows you to create tables with a flexible layout

# Load necessary libraries
library(flextable)
library(webshot)
library(magrittr)
library(officer)
library(dplyr)
library(tidyverse)
library(gt)


# Part B, Task 1 ----------------------------------------------------------
# Define the correct group colors and adjust yellow to darker orange for visibility
group_colors <- list(
  "Group A" = "#28A745",  # Green for Group A
  "Group B" = "#00008B",  # Dark Blue for Group B
  "Group C" = "#FF0000",  # Red for Group C
  "Group D" = "#FFA500",  # Darker Orange for Group D (for better visibility)
  "Group E" = "#ADD8E6",  # Light Blue for Group E
  "Group F" = "#000000"   # Black for Group F
)

# Create a match schedule with day information, venue, and group assignment
match_data <- data.frame(
  Venue = c("Berlin", "Leipzig", "Hamburg", "Dortmund", "Gelsenkirchen", 
            "Düsseldorf", "Cologne", "Frankfurt", "Stuttgart", "Munich"),
  Day_14_06 = c("", "", "", "", "", "", "", "", "", "1: GER vs SCO"),
  Day_15_06 = c("3: ESP vs CRO", "", "4: ITA vs ALB", "2: HUN vs SUI", "", "", "", "", "", ""),
  Day_16_06 = c("", "", "", "", "5: SRB vs ENG", "", "7: POL vs NED", "", "6: SVN vs DEN", ""),
  Day_17_06 = c("", "", "", "", "", "8: AUT vs FRA", "", "9: BEL vs SVK", "", "10: ROU vs UKR"),
  Day_18_06 = c("", "12: POR vs CZE", "", "11: TUR vs GEO", "", "", "", "", "", ""),
  Day_19_06 = c("", "", "15: CRO vs ALB", "", "", "", "14: GER vs HUN", "", "13: SCO vs SUI", ""),
  Day_20_06 = c("16: ESP vs ITA", "", "", "", "", "", "", "18: SVN vs SRB", "", "17: DEN vs ENG"),
  Day_21_06 = c("", "21: SVK vs UKR", "", "", "20: NED vs FRA", "19: POL vs AUT", "", "", "", ""),
  Day_22_06 = c("", "", "24: GEO vs CZE", "23: TUR vs POR", "", "", "", "", "22: BEL vs ROU", ""),
  Day_23_06 = c("", "", "", "", "", "", "26: SCO vs HUN", "25: SUI vs GER", "", ""),
  Day_24_06 = c("", "28: CRO vs ITA", "", "", "", "27: ALB vs ESP", "", "", "", ""),
  Day_25_06 = c("", "", "", "31: NED vs AUT", "32: FRA vs POL", "", "", "", "29: ENG vs SVN", "30: DEN vs SRB"),
  Day_26_06 = c("33: SVK vs ROU", "", "36: CZE vs TUR", "", "", "", "35: GEO vs POR", "34: UKR vs BEL", "", "")
)

# Ensure that all empty cells are filled with a safe empty string or valid value
match_data[is.na(match_data)] <- ""

# Function to apply the color for each match based on teams
get_match_color <- function(match) {
  if (match == "") return("#FFFFFF")  # Return white for empty cells (or any other default color)
  if (grepl("GER|SCO|HUN|SUI", match)) return(group_colors[["Group A"]])  # Group A
  if (grepl("ESP|CRO|ITA|ALB", match)) return(group_colors[["Group B"]])  # Group B
  if (grepl("SRB|DEN|SVN|ENG", match)) return(group_colors[["Group C"]])  # Group C
  if (grepl("POL|NED|AUT|FRA", match)) return(group_colors[["Group D"]])  # Group D
  if (grepl("BEL|SVK|ROU|UKR", match)) return(group_colors[["Group E"]])  # Group E
  if (grepl("TUR|GEO|POR|CZE", match)) return(group_colors[["Group F"]])  # Group F
  return("#FFFFFF")  # Default color for non-matching cells (or you can use transparent)
}


# Create the match schedule table
schedule_table <- gt(match_data) %>%
  tab_header(
    title = "UEFA Euro 2024 Match Schedule",
    subtitle = "Group Stage with Numbered Matches"
  ) %>%
  cols_label(
    Venue = "Venue",
    Day_14_06 = "14 June",
    Day_15_06 = "15 June",
    Day_16_06 = "16 June",
    Day_17_06 = "17 June",
    Day_18_06 = "18 June",
    Day_19_06 = "19 June",
    Day_20_06 = "20 June",
    Day_21_06 = "21 June",
    Day_22_06 = "22 June",
    Day_23_06 = "23 June",
    Day_24_06 = "24 June",
    Day_25_06 = "25 June",
    Day_26_06 = "26 June"
  ) %>%
  
  # Apply bold style to the title and subtitle
  tab_style(
    style = list(
      cell_text(weight = "bold")
    ),
    locations = cells_title(groups = c("title", "subtitle"))
  )


# Apply the styles for each match day
for (col in grep("^Day_", colnames(match_data), value = TRUE)) {
  for (row in seq_len(nrow(match_data))) {
    schedule_table <- schedule_table %>%
      tab_style(
        style = list(
          cell_fill(color = get_match_color(match_data[[col]][row])),
          cell_text(color = "white")
        ),
        locations = cells_body(columns = c(col), rows = row)
      )
  }
}

# Final table options
schedule_table <- schedule_table %>%
  cols_align(align = "center") %>%
  tab_options(
    table.border.top.color = "gray",
    table.border.bottom.color = "gray",
    heading.background.color = "lightblue"
  )

# Display the table
schedule_table

# Create a data frame for the first 12 teams and their distances
df_left <- data.frame(
  Team_Left = c('GER', 'SCO', 'HUN', 'SUI', 'ESP', 'CRO', 'ITA', 'ALB', 'SVN', 'DEN', 'SRB', 'ENG', "Total distance travelled"),
  Distance_Left = c(809, 600, 99, 654, 564, 689, 470, 401, 404, 222, 693, 889, "")
)

# Create a data frame for the second 12 teams and their distances
df_right <- data.frame(
  Team_Right = c('POL', 'NED', 'AUT', 'FRA', 'BEL', 'SVK', 'ROU', 'UKR', 'TUR', 'GEO', 'POR', 'CZE', ""),
  Distance_Right = c(120, 143, 73, 60, 404, 570, 848, 801, 353, 778, 526, 399, 11569)
)

# Combine the two data frames side by side
df_combined <- cbind(df_left, df_right)

# Create flextable
ft <- flextable(df_combined)

# Add title and format header
ft <- set_header_labels(ft, 
                        Team_Left = "Team", Distance_Left = "Distance travelled (km)",
                        Team_Right = "Team", Distance_Right = "Distance travelled (km)")

# Add a row that spans across all columns (4 columns in total) for the title
ft <- add_header_row(ft, values = "Total Distance Travelled by Each Team", colwidths = c(4)) 

# Apply the vanilla theme
ft <- theme_vanilla(ft)

# Format the table with appropriate styles
ft <- bold(ft, part = "header") # Make headers bold
ft <- bold(ft, i = nrow(df_combined)) # Make the "Sum" row bold
ft <- fontsize(ft, size = 10) # Set font size
ft <- align(ft, align = "center", part = "all") # Center align the table content
ft <- align(ft, align = "center", part = "header") # Center align the header
ft <- autofit(ft) # Adjust column widths

# Display the table
ft


# Part B, Task 2 ----------------------------------------------------------
# Define the correct group colors and adjust yellow to darker orange for visibility
group_colors <- list(
  "Group A" = "#28A745",  # Green for Group A
  "Group B" = "#00008B",  # Dark Blue for Group B
  "Group C" = "#FF0000",  # Red for Group C
  "Group D" = "#FFA500",  # Darker Orange for Group D (for better visibility)
  "Group E" = "#ADD8E6",  # Light Blue for Group E
  "Group F" = "#000000"   # Black for Group F
)

# Create a match schedule with day information, venue, and group assignment
match_data <- data.frame(
  Venue = c("Berlin", "Leipzig", "Hamburg", "Dortmund", "Gelsenkirchen", 
            "Düsseldorf", "Cologne", "Frankfurt", "Stuttgart", "Munich"),
  Day_14_06 = c("", "", "", "", "", "", "", "", "", "1: GER vs SCO"),
  Day_15_06 = c("3: ESP vs CRO", "", "", "4: ITA vs ALB", "", "", "2: HUN vs SUI", "", "", ""),
  Day_16_06 = c("", "", "7: POL vs NED", "", "5: SRB vs ENG", "", "", "", "6. SVN vs DEN", ""),
  Day_17_06 = c("", "", "", "", "", "9: BEL vs SVK", "", "10: ROU vs UKR", "", "8: AUT vs FRA"),
  Day_18_06 = c("", "12: POR vs CZE", "", "11: TUR vs GEO", "", "", "", "", "", ""),
  Day_19_06 = c("", "", "15: CRO vs ALB", "", "", "", "13: SCO vs SUI", "", "14: GER vs HUN", ""),
  Day_20_06 = c("", "", "", "", "16: ESP vs ITA", "", "", "18: SVN vs SRB", "", "17: DEN vs ENG"),
  Day_21_06 = c("20: NED vs FRA", "19: POL vs AUT", "", "", "", "21: SVK vs UKR", "", "", "", ""),
  Day_22_06 = c("", "", "24: GEO vs CZE", "23: TUR vs POR", "", "", "22: BEL vs ROU", "", "", ""),
  Day_23_06 = c("", "", "", "", "", "", "", "25: SUI vs GER", "26: SCO vs HUN", ""),
  Day_24_06 = c("", "27: ALB vs ESP", "", "", "", "28: CRO vs ITA", "", "", "", ""),
  Day_25_06 = c("31: NED vs AUT", "", "", "32: FRA vs POL", "", "", "30: DEN vs SRB", "", "", "29: ENG vs SVN"),
  Day_26_06 = c("", "", "35: GEO vs POR", "", "36: CZE vs TUR", "", "", "34: UKR vs BEL", "33: SVK vs ROU", "")
)

# Ensure that all empty cells are filled with a safe empty string or valid value
match_data[is.na(match_data)] <- ""

# Function to apply the color for each match based on teams
get_match_color <- function(match) {
  if (match == "") return("#FFFFFF")  # Return white for empty cells (or any other default color)
  if (grepl("GER|SCO|HUN|SUI", match)) return(group_colors[["Group A"]])  # Group A
  if (grepl("ESP|CRO|ITA|ALB", match)) return(group_colors[["Group B"]])  # Group B
  if (grepl("SRB|DEN|SVN|ENG", match)) return(group_colors[["Group C"]])  # Group C
  if (grepl("POL|NED|AUT|FRA", match)) return(group_colors[["Group D"]])  # Group D
  if (grepl("BEL|SVK|ROU|UKR", match)) return(group_colors[["Group E"]])  # Group E
  if (grepl("TUR|GEO|POR|CZE", match)) return(group_colors[["Group F"]])  # Group F
  return("#FFFFFF")  # Default color for non-matching cells (or you can use transparent)
}


# Create the match schedule table
schedule_table <- gt(match_data) %>%
  tab_header(
    title = "UEFA Euro 2024 Match Schedule",
    subtitle = "Group Stage with Numbered Matches"
  ) %>%
  cols_label(
    Venue = "Venue",
    Day_14_06 = "14 June",
    Day_15_06 = "15 June",
    Day_16_06 = "16 June",
    Day_17_06 = "17 June",
    Day_18_06 = "18 June",
    Day_19_06 = "19 June",
    Day_20_06 = "20 June",
    Day_21_06 = "21 June",
    Day_22_06 = "22 June",
    Day_23_06 = "23 June",
    Day_24_06 = "24 June",
    Day_25_06 = "25 June",
    Day_26_06 = "26 June"
  ) %>%
  
  # Apply bold style to the title and subtitle
  tab_style(
    style = list(
      cell_text(weight = "bold")
    ),
    locations = cells_title(groups = c("title", "subtitle"))
  )


# Apply the styles for each match day
for (col in grep("^Day_", colnames(match_data), value = TRUE)) {
  for (row in seq_len(nrow(match_data))) {
    schedule_table <- schedule_table %>%
      tab_style(
        style = list(
          cell_fill(color = get_match_color(match_data[[col]][row])),
          cell_text(color = "white")
        ),
        locations = cells_body(columns = c(col), rows = row)
      )
  }
}

# Final table options
schedule_table <- schedule_table %>%
  cols_align(align = "center") %>%
  tab_options(
    table.border.top.color = "gray",
    table.border.bottom.color = "gray",
    heading.background.color = "lightblue"
  )

# Display the table
schedule_table

# Create a data frame for the first 12 teams and their distances
df_left <- data.frame(
  Team_Left = c('GER', 'SCO', 'HUN', 'SUI', 'ESP', 'CRO', 'ITA', 'ALB', 'SVN', 'DEN', 'SRB', 'ENG', "Total distance travelled"),
  Distance_Left = c(422, 991, 378, 196, 961, 691, 93, 752, 622, 835, 471, 669, "")
)

# Create a data frame for the second 12 teams and their distances
df_right <- data.frame(
  Team_Right = c('POL', 'NED', 'AUT', 'FRA', 'BEL', 'SVK', 'ROU', 'UKR', 'TUR', 'GEO', 'POR', 'CZE', ""),
  Distance_Right = c(826, 290, 591, 1071, 257, 421, 576, 477, 34, 353, 780, 746, 13503)
)

# Combine the two data frames side by side
df_combined <- cbind(df_left, df_right)

# Create flextable
ft <- flextable(df_combined)

# Add title and format header
ft <- set_header_labels(ft, 
                        Team_Left = "Team", Distance_Left = "Distance travelled (km)",
                        Team_Right = "Team", Distance_Right = "Distance travelled (km)")

# Add a row that spans across all columns (4 columns in total) for the title
ft <- add_header_row(ft, values = "Total Distance Travelled by Each Team", colwidths = c(4)) 

# Apply the vanilla theme
ft <- theme_vanilla(ft)

# Format the table with appropriate styles
ft <- bold(ft, part = "header") # Make headers bold
ft <- bold(ft, i = nrow(df_combined)) # Make the "Sum" row bold
ft <- fontsize(ft, size = 10) # Set font size
ft <- align(ft, align = "center", part = "all") # Center align the table content
ft <- align(ft, align = "center", part = "header") # Center align the header
ft <- autofit(ft) # Adjust column widths

# Display the table
ft


# Part B, task 3A ---------------------------------------------------------
# Define the correct group colors and adjust yellow to darker orange for visibility
group_colors <- list(
  "Group A" = "#28A745",  # Green for Group A
  "Group B" = "#00008B",  # Dark Blue for Group B
  "Group C" = "#FF0000",  # Red for Group C
  "Group D" = "#FFA500",  # Darker Orange for Group D (for better visibility)
  "Group E" = "#ADD8E6",  # Light Blue for Group E
  "Group F" = "#000000"   # Black for Group F
)

# Create a match schedule with day information, venue, and group assignment
match_data <- data.frame(
  Venue = c("Berlin", "Leipzig", "Hamburg", "Dortmund", "Gelsenkirchen", 
            "Düsseldorf", "Cologne", "Frankfurt", "Stuttgart", "Munich"),
  Day_14_06 = c("", "", "", "", "", "", "", "", "", "1: GER vs SCO"),
  Day_15_06 = c("3: ESP vs CRO", "", "", "2: HUN vs SUI", "", "", "4: ITA vs ALB", "", "", ""),
  Day_16_06 = c("", "", "7: POL vs NED", "", "6. SVN vs DEN", "", "", "", "5: SRB vs ENG", ""),
  Day_17_06 = c("", "", "", "", "", "8: AUT vs FRA", "", "10: ROU vs UKR", "", "9: BEL vs SVK"),
  Day_18_06 = c("", "12: POR vs CZE", "", "11: TUR vs GEO", "", "", "", "", "", ""),
  Day_19_06 = c("", "", "15: CRO vs ALB", "", "", "", "13: SCO vs SUI", "", "14: GER vs HUN", ""),
  Day_20_06 = c("", "", "", "", "16: ESP vs ITA", "", "", "18: SVN vs SRB", "", "17: DEN vs ENG"),
  Day_21_06 = c("20: NED vs FRA", "19: POL vs AUT", "", "", "", "21: SVK vs UKR", "", "", "", ""),
  Day_22_06 = c("", "", "22: BEL vs ROU", "23: TUR vs POR", "", "", "24: GEO vs CZE", "", "", ""),
  Day_23_06 = c("", "", "", "", "", "", "", "25: SUI vs GER", "26: SCO vs HUN", ""),
  Day_24_06 = c("", "28: CRO vs ITA", "", "", "", "27: ALB vs ESP", "", "", "", ""),
  Day_25_06 = c("32: FRA vs POL", "", "", "31: NED vs AUT", "", "", "29: ENG vs SVN", "", "", "30: DEN vs SRB"),
  Day_26_06 = c("", "", "34: UKR vs BEL", "", "33: SVK vs ROU", "", "", "35: GEO vs POR", "36: CZE vs TUR", "")
)

# Ensure that all empty cells are filled with a safe empty string or valid value
match_data[is.na(match_data)] <- ""

# Function to apply the color for each match based on teams
get_match_color <- function(match) {
  if (match == "") return("#FFFFFF")  # Return white for empty cells (or any other default color)
  if (grepl("GER|SCO|HUN|SUI", match)) return(group_colors[["Group A"]])  # Group A
  if (grepl("ESP|CRO|ITA|ALB", match)) return(group_colors[["Group B"]])  # Group B
  if (grepl("SRB|DEN|SVN|ENG", match)) return(group_colors[["Group C"]])  # Group C
  if (grepl("POL|NED|AUT|FRA", match)) return(group_colors[["Group D"]])  # Group D
  if (grepl("BEL|SVK|ROU|UKR", match)) return(group_colors[["Group E"]])  # Group E
  if (grepl("TUR|GEO|POR|CZE", match)) return(group_colors[["Group F"]])  # Group F
  return("#FFFFFF")  # Default color for non-matching cells (or you can use transparent)
}


# Create the match schedule table
schedule_table <- gt(match_data) %>%
  tab_header(
    title = "UEFA Euro 2024 Match Schedule",
    subtitle = "Group Stage with Numbered Matches"
  ) %>%
  cols_label(
    Venue = "Venue",
    Day_14_06 = "14 June",
    Day_15_06 = "15 June",
    Day_16_06 = "16 June",
    Day_17_06 = "17 June",
    Day_18_06 = "18 June",
    Day_19_06 = "19 June",
    Day_20_06 = "20 June",
    Day_21_06 = "21 June",
    Day_22_06 = "22 June",
    Day_23_06 = "23 June",
    Day_24_06 = "24 June",
    Day_25_06 = "25 June",
    Day_26_06 = "26 June"
  ) %>%
  
  # Apply bold style to the title and subtitle
  tab_style(
    style = list(
      cell_text(weight = "bold")
    ),
    locations = cells_title(groups = c("title", "subtitle"))
  )


# Apply the styles for each match day
for (col in grep("^Day_", colnames(match_data), value = TRUE)) {
  for (row in seq_len(nrow(match_data))) {
    schedule_table <- schedule_table %>%
      tab_style(
        style = list(
          cell_fill(color = get_match_color(match_data[[col]][row])),
          cell_text(color = "white")
        ),
        locations = cells_body(columns = c(col), rows = row)
      )
  }
}

# Final table options
schedule_table <- schedule_table %>%
  cols_align(align = "center") %>%
  tab_options(
    table.border.top.color = "gray",
    table.border.bottom.color = "gray",
    heading.background.color = "lightblue"
  )

# Display the table
schedule_table

# Create a data frame for the first 12 teams and their distances
df_left <- data.frame(
  Team_Left = c('GER', 'SCO', 'HUN', 'SUI', 'ESP', 'CRO', 'ITA', 'ALB', 'SVN', 'DEN', 'SRB', 'ENG', "Total distance travelled"),
  Distance_Left = c(422, 991, 452, 295, 569, 689, 553, 826, 471, 669, 622, 835, "")
)

# Create a data frame for the second 12 teams and their distances
df_right <- data.frame(
  Team_Right = c('POL', 'NED', 'AUT', 'FRA', 'BEL', 'SVK', 'ROU', 'UKR', 'TUR', 'GEO', 'POR', 'CZE', ""),
  Distance_Right = c(578, 791, 908, 565, 790, 714, 855, 641, 452, 295, 698, 880, 15561)
)

# Combine the two data frames side by side
df_combined <- cbind(df_left, df_right)

# Create flextable
ft <- flextable(df_combined)

# Add title and format header
ft <- set_header_labels(ft, 
                        Team_Left = "Team", Distance_Left = "Distance travelled (km)",
                        Team_Right = "Team", Distance_Right = "Distance travelled (km)")

# Add a row that spans across all columns (4 columns in total) for the title
ft <- add_header_row(ft, values = "Total Distance Travelled by Each Team", colwidths = c(4)) 

# Apply the vanilla theme
ft <- theme_vanilla(ft)

# Format the table with appropriate styles
ft <- bold(ft, part = "header") # Make headers bold
ft <- bold(ft, i = nrow(df_combined)) # Make the "Sum" row bold
ft <- fontsize(ft, size = 10) # Set font size
ft <- align(ft, align = "center", part = "all") # Center align the table content
ft <- align(ft, align = "center", part = "header") # Center align the header
ft <- autofit(ft) # Adjust column widths

# Display the table
ft


# Part B, task3b ----------------------------------------------------------
# Create a data frame for the first 12 teams and their distances
# Define the correct group colors and adjust yellow to darker orange for visibility
group_colors <- list(
  "Group A" = "#28A745",  # Green for Group A
  "Group B" = "#00008B",  # Dark Blue for Group B
  "Group C" = "#FF0000",  # Red for Group C
  "Group D" = "#FFA500",  # Darker Orange for Group D (for better visibility)
  "Group E" = "#ADD8E6",  # Light Blue for Group E
  "Group F" = "#000000"   # Black for Group F
)

# Create a match schedule with day information, venue, and group assignment
match_data <- data.frame(
  Venue = c("Berlin", "Leipzig", "Hamburg", "Dortmund", "Gelsenkirchen", 
            "Düsseldorf", "Cologne", "Frankfurt", "Stuttgart", "Munich"),
  Day_14_06 = c("", "", "", "", "", "", "", "", "", "1: GER vs SCO"),
  Day_15_06 = c("3: ESP vs CRO", "", "", "2: HUN vs SUI", "", "", "4: ITA vs ALB", "", "", ""),
  Day_16_06 = c("", "", "7: POL vs NED", "", "5: SRB vs ENG", "", "", "", "6. SVN vs DEN", ""),
  Day_17_06 = c("", "", "", "", "", "9: BEL vs SVK", "", "10: ROU vs UKR", "", "8: AUT vs FRA"),
  Day_18_06 = c("", "11: TUR vs GEO", "", "12: POR vs CZE", "", "", "", "", "", ""),
  Day_19_06 = c("", "", "15: CRO vs ALB", "", "", "", "13: SCO vs SUI", "", "14: GER vs HUN", ""),
  Day_20_06 = c("", "", "", "", "16: ESP vs ITA", "", "", "18: SVN vs SRB", "", "17: DEN vs ENG"),
  Day_21_06 = c("20: NED vs FRA", "19: POL vs AUT", "", "", "", "21: SVK vs UKR", "", "", "", ""),
  Day_22_06 = c("", "", "22: BEL vs ROU", "24: GEO vs CZE", "", "", "23: TUR vs POR", "", "", ""),
  Day_23_06 = c("", "", "", "", "", "", "", "25: SUI vs GER", "26: SCO vs HUN", ""),
  Day_24_06 = c("", "28: CRO vs ITA", "", "", "", "27: ALB vs ESP", "", "", "", ""),
  Day_25_06 = c("32: FRA vs POL", "", "", "31: NED vs AUT", "", "", "30: DEN vs SRB", "", "", "29: ENG vs SVN"),
  Day_26_06 = c("", "", "33: SVK vs ROU", "", "34: UKR vs BEL", "", "", "35: GEO vs POR", "36: CZE vs TUR", "")
)

# Ensure that all empty cells are filled with a safe empty string or valid value
match_data[is.na(match_data)] <- ""

# Function to apply the color for each match based on teams
get_match_color <- function(match) {
  if (match == "") return("#FFFFFF")  # Return white for empty cells (or any other default color)
  if (grepl("GER|SCO|HUN|SUI", match)) return(group_colors[["Group A"]])  # Group A
  if (grepl("ESP|CRO|ITA|ALB", match)) return(group_colors[["Group B"]])  # Group B
  if (grepl("SRB|DEN|SVN|ENG", match)) return(group_colors[["Group C"]])  # Group C
  if (grepl("POL|NED|AUT|FRA", match)) return(group_colors[["Group D"]])  # Group D
  if (grepl("BEL|SVK|ROU|UKR", match)) return(group_colors[["Group E"]])  # Group E
  if (grepl("TUR|GEO|POR|CZE", match)) return(group_colors[["Group F"]])  # Group F
  return("#FFFFFF")  # Default color for non-matching cells (or you can use transparent)
}


# Create the match schedule table
schedule_table <- gt(match_data) %>%
  tab_header(
    title = "UEFA Euro 2024 Match Schedule",
    subtitle = "Group Stage with Numbered Matches"
  ) %>%
  cols_label(
    Venue = "Venue",
    Day_14_06 = "14 June",
    Day_15_06 = "15 June",
    Day_16_06 = "16 June",
    Day_17_06 = "17 June",
    Day_18_06 = "18 June",
    Day_19_06 = "19 June",
    Day_20_06 = "20 June",
    Day_21_06 = "21 June",
    Day_22_06 = "22 June",
    Day_23_06 = "23 June",
    Day_24_06 = "24 June",
    Day_25_06 = "25 June",
    Day_26_06 = "26 June"
  ) %>%
  
  # Apply bold style to the title and subtitle
  tab_style(
    style = list(
      cell_text(weight = "bold")
    ),
    locations = cells_title(groups = c("title", "subtitle"))
  )


# Apply the styles for each match day
for (col in grep("^Day_", colnames(match_data), value = TRUE)) {
  for (row in seq_len(nrow(match_data))) {
    schedule_table <- schedule_table %>%
      tab_style(
        style = list(
          cell_fill(color = get_match_color(match_data[[col]][row])),
          cell_text(color = "white")
        ),
        locations = cells_body(columns = c(col), rows = row)
      )
  }
}

# Final table options
schedule_table <- schedule_table %>%
  cols_align(align = "center") %>%
  tab_options(
    table.border.top.color = "gray",
    table.border.bottom.color = "gray",
    heading.background.color = "lightblue"
  )

# Display the table
schedule_table

# Create a data frame for the teams and their distances
df_slack <- data.frame(
  Team = c('GER', 'SCO', 'HUN', 'SUI', 'ESP', 'CRO', 'ITA', 'ALB', 'SVN', 'DEN', 'SRB', 'ENG', 
                'POL', 'NED', 'AUT', 'FRA', 'BEL', 'SVK', 'ROU', 'UKR', 'TUR', 'GEO', 'POR', 'CZE', "Total distance travelled"),
  noslack = c(422, 991, 378, 196, 569, 689, 485, 754, 669, 471, 835, 622, 791, 578, 570, 839, 576, 477, 257, 421, 353, 700, 461, 399, 13503),
  fiveslack = c(422, 991, 452, 295, 553, 826, 569, 689, 622, 835, 471, 669, 578, 791, 839, 570, 576, 477, 257, 421, 700, 353, 399, 461, 13816),
  tenslack = c(422, 991, 452, 295, 569, 689, 553, 826, 622, 835, 471, 669, 578, 791, 839, 570, 750, 403, 508, 298, 880, 698, 295, 452, 14456)
)


# Create flextable
ft <- flextable(df_slack)

# Add title and format header
ft <- set_header_labels(ft, 
                        Team = "Team", noslack = "No Slack", fiveslack = "5% Slack", tenslack = "10% Slack")

# Add a row that spans across all columns (4 columns in total) for the title
ft <- add_header_row(ft, values = "Total Distance Travelled by Each Team", colwidths = c(4)) 

# Apply the vanilla theme
ft <- theme_vanilla(ft)

# Format the table with appropriate styles
ft <- bold(ft, part = "header") # Make headers bold
ft <- bold(ft, i = nrow(df_slack)) # Make the "Sum" row bold
ft <- fontsize(ft, size = 10) # Set font size
ft <- align(ft, align = "center", part = "all") # Center align the table content
ft <- align(ft, align = "center", part = "header") # Center align the header
ft <- autofit(ft) # Adjust column widths

# Display the table
ft

# Part C, Task 1A ---------------------------------------------------------
# Create the dataset
schedule_data <- data.frame(
  `Start Day` = c("Day 3", "Day 4", "Day 5", "Day 6"),
  `Market Region` = c("Extreme South", "Extreme South", "Extreme South", "Extreme South"),
  `Depot(s)` = c("D1, D2", "D1, D2", "D1", "D1")
)

# Create and style the flextable
schedule_table <- flextable(schedule_data) %>%
  set_caption(caption = "Distribution Schedule") %>%
  theme_booktabs() %>%
  align(align = "center", part = "header") %>%
  bold(part = "header") %>%
  bg(bg = "white", part = "all") %>%
  set_table_properties(layout = "autofit")

# Display the table
print(schedule_table)


# Part C, Task 1B ---------------------------------------------------------
# Create the data frame with your markets and products
demand_data <- data.frame(
  Markets = c("K1", "K2", "K3", "K4", "K5", "K6", "K7", "K8", "K9", "EN1", "EN2", "ES1", "ES2", "Sum"),
  Premium = c(0, 0, 0, 30, 0, 0, 0, 0, 0, 25, 34, 26, 27, 142),
  Regular = c(0, 0, 0, 10, 70, 0, 0, 0, 0, 23, 22, 20, 28, 173),
  DistilF = c(0, 10, 26, 4, 0, 0, 0, 0, 0, 16, 16, 18, 18, 108),
  Super = c(0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 22, 27, 33, 99),
  Sum = c(0, 10, 26, 44, 70, 0, 0, 0, 0, 81, 94, 91, 106, 522)
)

# Transpose the table so that markets are in columns
transposed_data <- demand_data %>%
  select(-Markets) %>%
  t() %>%
  as.data.frame()

# Set column names to the markets
colnames(transposed_data) <- demand_data$Markets

# Add a row with product names
transposed_data <- cbind(Product = c("Premium", "Regular", "DistilF", "Super", "Sum"), transposed_data)

# Create the flextable with the desired formatting
demand_table <- flextable(transposed_data) %>%
  set_caption(caption = "Unsatisfied Demand for Products and Markets") %>%  # Optional caption
  theme_booktabs() %>%
  align(align = "center", part = "header") %>%
  align(align = "center", part = "body") %>%
  bold(i = 5, j = 1:15, bold = TRUE, part = "body") %>%  # Bold the 'Sum' row
  set_table_properties(layout = "autofit")

# Print the formatted table
demand_table


# Part C, Task 1C ---------------------------------------------------------
# Create the dataset
inventory_data <- data.frame(
  Component = c("distilA", "distilB", "ISO", "POL", "Sum"),
  `Final Inventory` = c(1245.95, 1882.05, 400, 400, 3928),  # Sum is the total of Final Inventory
  `Minimum Required` = c(100, 100, 400, 400, 1000),  # Sum is the total of Minimum Required
  `Slack` = c(1145.95, 1782.05, 0, 0, 2928)  # Sum is the total of Slack
)

# Create and style the flextable
inventory_table <- flextable(inventory_data) %>%
  set_caption(
    caption = "Final Inventory, Minimum Required, and Slack for Components" # Add a caption
  ) %>%
  theme_booktabs() %>%
  align(align = "center", part = "header") %>%
  align(align = "center", part = "body") %>%
  bold(i = 5, j = 1:4, bold = TRUE, part = "body") %>%  # Bold the 'Sum' row
  set_table_properties(layout = "autofit")

# Print the table
inventory_table


# Part C, Task 2 ----------------------------------------------------------
# Create the initial data frame
comparison_data <- data.frame(
  Day = 1:10,  # Days 1 to 10 for R1 and R2
  
  # Original Scenario values for R1 and R2
  Original_R1 = c(40, 0, 0, 0, 0, 0, 0, 0, 0, 0),
  Original_R2 = c(0, 0, 40, 80, 0, 0, 0, 0, 0, 0),
  Original_sum = c(40, 0, 40, 80, 0, 0, 0, 0, 0, 0),
  
  # Revised Scenario values for R1 and R2
  Revised_R1 = c(40, 0, 0, 0, 635, 0, 0, 0, 0, 0),
  Revised_R2 = c(0, 0, 40, 80, 621, 0, 0, 0, 0, 0),
  Revised_sum = c(40, 0, 40, 80, 1256, 0, 0, 0, 0, 0)
)

# Add a sum row to the data frame
comparison_data <- rbind(
  comparison_data,
  data.frame(
    Day = "Sum",  # Label for the sum row
    Original_R1 = sum(comparison_data$Original_R1),
    Original_R2 = sum(comparison_data$Original_R2),
    Original_sum = sum(comparison_data$Original_sum),
    Revised_R1 = sum(comparison_data$Revised_R1),
    Revised_R2 = sum(comparison_data$Revised_R2),
    Revised_sum = sum(comparison_data$Revised_sum)
  )
)

# Create the flextable with the additional sum row and bold styling
comparison_table <- flextable(comparison_data) %>%
  set_caption(caption = "Comparison of Crude Oil Inventories Between Original and Revised Scenarios") %>%
  
  # Add the top-level headers for Original Scenario and Revised Scenario
  add_header_row(
    top = TRUE,
    values = c("", "Original Scenario", "", "", "Revised Scenario", "", ""),
    colwidths = c(1, 1, 1, 1, 1, 1, 1)
  ) %>%
  
  # Merge the headers for Original Scenario and Revised Scenario
  merge_at(i = 1, j = 2:4, part = "header") %>%  # Merging for Original Scenario
  merge_at(i = 1, j = 5:7, part = "header") %>%  # Merging for Revised Scenario
  
  # Rename header of the data
  set_header_labels(
    Day = "Day",
    Original_R1 = "R1",
    Original_R2 = "R2",
    Original_sum = "Sum",
    Revised_R1 = "R1",
    Revised_R2 = "R2",
    Revised_sum = "Sum"
  ) %>%
  
  # Add padding for spacing and nice display
  padding(padding = 6) %>%
  
  # Adjust the column widths for spacing
  width(j = 1, width = 1) %>%  # Day column
  width(j = 2:4, width = 1) %>%  # Original Scenario columns
  width(j = 5:7, width = 1) %>%  # Revised Scenario columns
  
  # Style the table to align, bold necessary headers, and autofit
  theme_booktabs() %>%
  align(align = "center", part = "header") %>%
  align(align = "center", part = "body") %>%
  bold(i = 1, j = c(2, 5), bold = TRUE, part = "header") %>%
  bold(i = 2, j = c("Day", "Original_R1", "Original_R2", "Original_sum", "Revised_R1", "Revised_R2", "Revised_sum"), bold = TRUE, part = "header") %>%
  
  # Bold the last row (sum row)
  bold(i = nrow(comparison_data), part = "body") %>%
  
  bg(bg = "white", part = "all") %>%
  set_table_properties(layout = "autofit")

# Print the table
comparison_table




