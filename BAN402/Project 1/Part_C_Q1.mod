# =============================================================================================================
# Part C - Question 1
# =============================================================================================================

# =============================================================================================================
# Define sets
# =============================================================================================================
set Regions; # Set of regions
set Ports;   # Set of ports
set Markets; # Set of markets

# =============================================================================================================
# Define parameters
# =============================================================================================================
param supply {Regions};                # Weekly supply in regions (tons)
param cost_reg_port {Regions, Ports};  # Cost of transporting one ton from regions to ports
param cost_port_mar {Ports, Markets};  # Cost of shipping one ton from ports to markets
param cost_reg_mar {Regions, Markets}; # Cost of shipping one ton directly from regions to ports
param demand {Markets};                # Weekly demand in markets (tons)

# =============================================================================================================
# Define decision variables
# =============================================================================================================
var x {Regions, Ports} >= 0;  # Tons transported from regions to ports can not be a negative amount
var y {Ports, Markets} >= 0;  # Tons transported from ports to markets can not be a negative amount
var z {Regions, Markets} >=0; # Tons transported directly from regions to markets can not be a negative amount

# =============================================================================================================
# Objective function: Minimizing total costs
# =============================================================================================================
minimize total_cost: # Min total costs function
	sum {r in Regions, p in Ports} cost_reg_port[r,p] * x[r,p]
	+ sum {p in Ports, k in Markets} cost_port_mar[p,k] * y[p,k]
	+ sum {r in Regions, k in Markets} cost_reg_mar[r,k] * z[r,k];

# =============================================================================================================
# Define constraints
# =============================================================================================================
# Amount transported and shipped from regions can not exceed supply
subject to reg_supply {r in Regions}:
	sum {p in Ports} x[r,p] + sum {k in Markets} z[r,k] <=supply[r];

# Meet demand in all markets
subject to market_demand {k in Markets}: 
	sum {p in Ports} y[p,k] + sum {r in Regions} z[r,k] = demand[k];

# Amount transported from regions to ports is equal to amount shipped from ports to markets
subject to port_flow {p in Ports}: 
	sum {r in Regions} x[r,p] = sum {k in Markets} y[p,k];
	


