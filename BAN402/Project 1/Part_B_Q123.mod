# =================================================================================================
# Part B - Question 1-3
# =================================================================================================

# =================================================================================================
# Define sets
# =================================================================================================
set Products;   # Set of products;
set Inputs;		# Set of raw materials or inputs
set Nutrients; 	# Set of nutritions for each product

# =================================================================================================
# Define parameters
# =================================================================================================
param revenue {Products};	# Profit per unit
param demand {Products};	# Demand for each product
param prodcost;				# Production cost per ton (500 NOK)
param cost {Inputs};        # Cost of one unit of input i from supplier
param capacity;             # Total production capacity (1300 tons)
param supply {Inputs};      # Supply limit for each material in tons
param nutrient_content {Inputs, Nutrients}; # Nutrition content of each material

# Nutrition limits for each product (in weight %)
param min_nutrient {Products, Nutrients}; # Minimum nutrition for each product
param max_nutrient {Products, Nutrients} default Infinity; # Maximum nutrition for each product

# =================================================================================================
# Define decision variables
# =================================================================================================
var x {Products} >= 0; 	        # Amount of product produced
var y {Products, Inputs} >= 0; 	# Tons of input i used in product p 

# =================================================================================================
# Objective function: Maximizing total profit
# =================================================================================================
maximize total_profit: # Max total profit function
	sum {p in Products} revenue[p] * x[p] 
	- sum {p in Products} prodcost * x[p]
	- sum {p in Products, i in Inputs} cost[i] * y[p,i];
	
subject to 

# =================================================================================================
# Define constraints
# =================================================================================================
Demandlimit {p in Products}: # Demand constraint
	x[p] >= demand[p]; 
	
Capacitylimit: # Total production capacity constraint
	sum {p in Products} x[p] <= capacity;
	
Inputlimit {i in Inputs}: # Material constraint
	sum {p in Products} y[p,i] <= supply[i];
	
Proteinlimit {p in Products}: # Protein content constraint
	sum {i in Inputs} nutrient_content[i, "Protein"] * y[p,i] >= min_nutrient[p, "Protein"] * x[p];
	
Carbominlimit {p in Products}: # Carbohydrate content constraint minimum
	sum {i in Inputs} nutrient_content[i, "Carbohydrate"] * y[p,i]
	>= min_nutrient[p, "Carbohydrate"] * x[p];
	
Carbomaxlimit {p in Products}: # Carbohydrate content constraint maximum
	sum {i in Inputs} nutrient_content[i, "Carbohydrate"] * y[p,i]
	<= max_nutrient[p, "Carbohydrate"] * x[p];
	
Vitaminlimit {p in Products}: # Vitamin content constraint
	sum {i in Inputs} nutrient_content[i, "Vitamin"] * y[p,i]
	>= min_nutrient[p, "Vitamin"] * x[p];
