# =================================================================================================
# Part C - Question 3a
# =================================================================================================

# =================================================================================================
# Define sets
# =================================================================================================
set Regions; # Set of regions
set Ports;   # Set of ports
set Markets; # Set of markets

# =================================================================================================
# Define parameters
# =================================================================================================
param supply {Regions};                # Weekly supply in regions (tons)
param cost_reg_port {Regions, Ports};  # Cost of transporting one ton from regions to ports
param cost_port_mar {Ports, Markets};  # Cost of shipping one ton from ports to markets
param demand {Markets};                # Weekly demand in markets (tons) 

# =================================================================================================
# Define decision variables
# =================================================================================================
var x {Regions, Ports} >= 0;  # Tons transported from regions to ports can not be a negative amount
var y {Ports, Markets} >= 0;  # Tons shipped from ports to markets can not be a negative amount

# =================================================================================================
# Objective function: Minimizing total costs
# =================================================================================================
minimize total_cost: # Min total cost function
	sum {r in Regions, p in Ports} cost_reg_port[r,p] * x[r,p]
	+ sum {p in Ports, k in Markets} cost_port_mar[p,k] * y[p,k];

# =================================================================================================
# Define constraints
# =================================================================================================
# Amount transported from regions to ports cannot exceed supply
subject to reg_supply {r in Regions}: 
	sum {p in Ports} x[r,p] <=supply[r];
	
# Amount shipped from ports to markets must be equal to market demands
subject to market_demand {k in Markets}: 
	sum {p in Ports} y[p,k] = demand[k];

# Only 99% percent of the amount transported from regions to ports will reach the markets
subject to port_flow {p in Ports}:
	sum {k in Markets} y[p,k] = 0.99 * sum {r in Regions} x[r,p];




	

