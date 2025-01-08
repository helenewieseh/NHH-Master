# =================================================================================================================
# Part A - Question 1 - Model file
# =================================================================================================================

# =================================================================================================================
# Set
# =================================================================================================================

set I; # Set of the seven days of the week

# =================================================================================================================
# Parameters
# =================================================================================================================

param cap;           # Maximum capacity at the theatre, which is the same for each day
param intercept {I}; # Intercepts of the demand functions
param slope {I};     # Slopes of the demand functions
param min_demand;    # Minimum amount of tickets, which is the same for each day


# =================================================================================================================
# Decision variables
# =================================================================================================================

var p {I} >= 0;        # Price per ticket for each day
var Q {i in I} >= 0;   # Demand on each day

# =================================================================================================================
# Objective funtion: Maximize total revenue
# =================================================================================================================

maximize Total_Revenue:
    sum {i in I} (Q[i] * p[i]);
    
    
# =================================================================================================================
# Constraints
# =================================================================================================================

# Ensure that the amount of tickets sold each day do not exceed the capacity:
subject to Capacity_Constraint {i in I}:
    Q[i] <= cap;

# Ensure that the amount of tickets sold each day is at least the minimum number of tickets:
subject to Min_Tickets_Constraint {i in I}:
    Q[i] >= min_demand;

# Define demand functions:
subject to Demand_Constraint {i in I}:
	Q[i] <= intercept[i] + slope[i] * p[i] + sum {j in I: j != i} 2 * (p[j] - p[i]);
	
