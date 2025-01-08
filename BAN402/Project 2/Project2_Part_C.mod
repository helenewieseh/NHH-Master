reset;
#=============================================================================================================
# Part B - Model file
# =============================================================================================================

# =============================================================================================================
# Sets
# =============================================================================================================

set I;			 # Set of crude oils
set R; 			 # Set of refineries
set B; 			 # Set of components produced from blending crude oil
set P; 			 # Set of final products
set D; 			 # Set of depots
set K; 			 # Set of markets
set T ordered; 	 # Set of periods (days)

# =============================================================================================================
# Subsets
# =============================================================================================================

set K_REG within K; 		# Subset for regular markets
set K_EXT within K; 		# Subset for extreme markets
set K_EXT_S within K_EXT; 	# Subset for extreme south markets
set K_EXT_N within K_EXT; 	# Subset for extreme north markets


# =============================================================================================================
# Parameters
# =============================================================================================================

param Ccru{I,T}; 					# Cost of purchasing one unit of crude oil i on day t
param a{R,I,B}; 					# Amount of component b gained from one unit of crude oil i refined in r
param Q{B,P}; 						# Amount of component b needed in recipe for one unit of product p
param S{P}; 						# Price of product p in all markets
param Cpro{P}; 						# Cost of producing one unit of product p
param Cdis{R,I}; 					# Cost of processing one unit of crude oil i at the refinery r
param Ctra1; 						# Cost of transporting one unit of any component from the refining to the blending department
param Ctra2{D}; 					# Cost of transporting one unit of any product from the blending department to depot d
param Ctra3{D,K}; 					# Cost of shipping one unit of any product from depot d to market k
param Cinvi; 						# Cost of storing one unit of any type of crude oil at the refining department per day.
param Cinvb; 						# Cost of storing one unit of any component at the refining department per day
param Cinvp{D}; 					# The cost of storing one unit of any type of product at depot d
param CExtreme{D}; 					# Fixed cost for shipping any quantity to extreme markets from depot d
param delta{P,K,T}; 				# Maximum demand limit for product p from market k in day t
param I_zero_I{R,I}; 				# initial inventory of crude i at refinery r
param I_zero_b{B}; 					# Initial inventory of component b
param I_zero_pd{P,D}; 				# Initial inventory of product p at depot d
param I_final_b{B}; 				# Minimum inventory of component b
param I_final_pd{P,D}; 				# Minimum final inventory requirement of product p at depot d
param CAP{R}; 						# Maximum processing capacity for refinery r
param y_zero_b{B}; 					# Initial component b sent to blending
param x_zero_p{P,D}; 				# Initial product p sent to depot d
param v_zero_p{P,D,K} default 0; 	# Initial product p sent to market k
param M; 							# A sufficiently large constant


# =============================================================================================================
# Decision variables
# =============================================================================================================

var u{I,T} >= 0; 		# Units of crude oil i purchased at day t
var w{R,I,T} >= 0; 		# Units of crude oil i refined at refinery r on day t
var y {B,T} >= 0; 		# Units of component b sent to blending in period t
var z{P,T} >= 0; 		# Units of product p produced at the blending department in period t
var x{P,D,T} >= 0; 		# Units of product p sent to depot d on day t
var v{P,D,K,T} >= 0; 	# Units of product p shipped from depot d to market k on day t

# =============================================================================================================
# Inventory variables
# =============================================================================================================

var IO{R,I,T} >= 0; 	# Inventory of crude oil i at the refinery r in the end of period t
var IC{B,T} >= 0; 		# inventory of component b at the hub in the end of period t
var IP{P,D,T} >= 0; 	# Inventory of product p at depot d at the end of period t

# =============================================================================================================
# Binary variables
# =============================================================================================================

var EXT_S{T} binary; # 1 if shipment to any extreme south market happens on day t, 0 otherwise
var EXT_N{T} binary; # 1 if shipment to any extreme north market happens on day t, 0 otherwise

# =============================================================================================================
# Objective function: Maximize total profit
# =============================================================================================================

maximize contribution:
	sum{p in P, d in D, k in K_REG, t in T:t>0 and t <= card(T)-2}S[p]*v[p,d,k,t] +
	sum{p in P, d in D, k in K_EXT, t in T:t>0 and t <= card(T)-3}S[p]*v[p,d,k,t]
	- sum{i in I, t in T:t>0}Ccru[i,t]*u[i,t]
	- sum{p in P, t in T:t>0}Cpro[p]*z[p,t]
	- sum {r in R, i in I, t in T: t > 0} Cdis[r,i] * w[r,i,t]
	- sum{b in B, t in T:t>0}Ctra1*y[b,t]
	- sum{p in P, d in D, t in T: t>0} Ctra2[d]*x[p,d,t]
	- sum{p in P, d in D, k in K, t in T: t>0} Ctra3[d,k]*v[p,d,k,t]
	- sum{d in D, t in T: t>0} CExtreme[d]*(EXT_S[t]+EXT_N[t])
	- sum{r in R, i in I, t in T:t>0}Cinvi*IO[r,i,t]
    - sum{b in B, t in T:t>0}Cinvb*IC[b,t]
    - sum{p in P, d in D, t in T:t>0}Cinvp[d]*IP[p,d,t]
    ;
    
# =============================================================================================================
# General constraints
# =============================================================================================================

subject to 
# Balance of crudes inflow purchase ,storage
BalanceCrude {r in R, i in I, t in T: t > 0}: 
    IO[r,i,t] = IO[r,i,t-1] + u[i,t] - sum{b in B} w[r,i,t]*a[r,i,b];

# Crude oils at refineries must not exceed capacity
RefineryCapacity {r in R, t in T: t > 0}:
	sum {i in I} w[r,i,t] <= CAP[r];

# Balance of outgoing components since they can not be stored at the refinery
NoStorageAtRefinery {b in B, t in T: t > 0}: 
	y[b,t] = sum {r in R, i in I} a[r,i,b] * w[r,i,t];

# Balance of inflow, storage and usage of components at the blending department
ComponentBalance {b in B, t in T: t > 0}: 
    IC[b,t] = IC[b,t-1] + y[b,t] - sum {p in P} Q[b,p] * z[p,t];
 
# Component quantity sufficient to meet recipe   
ComponentSufficiency {b in B, t in T: t > 0}: 
    y[b,t-1] >= sum {p in P} Q[b,p] * z[p,t];

# All products sent to depot, no storage at blending facility
NoStorageAtBlending {p in P, t in T: t > 0}:
    z[p,t] = sum {d in D} x[p,d,t];

# Balance of products in depots: inflow, storage and outflow to market
BalanceInDepots {p in P, d in D, t in T: t > 0}: 
    IP[p,d,t] = IP[p,d,t-1] + x[p,d,t-1] - sum {k in K} v[p,d,k,t];
   
# Demand on day t for regular markets is satisfied by shipments made on day t-1
RegularMarketDemand {p in P, k in K_REG, t in T: t > 0}:
    sum {d in D} v[p,d,k,t-1] <= delta[p,k,t];

# Demand on day t for extreme markets is satisfied by shipments made on day t-2
ExtremeMarketDemand {p in P, k in K_EXT, t in T: t > 1}:
   sum {d in D} v[p,d,k,t-2] <= delta[p,k,t];

# Initial inventory of crude oils
InventoryInitial_i{r in R, i in I}:
     	IO[r,i,0]=I_zero_I[r,i];

# Initial inventory of components b
InventoryInitial_b{b in B}:
     	IC[b,0]=I_zero_b[b];

# Initial inventory of products at depot d
InventoryInitial_p{p in P, d in D}:
     	IP[p,d,0]=I_zero_pd[p,d];  

# Initial component b sent to blending (available in t=1)
b_InitialToBlending{b in B}:
     	y[b,0]=y_zero_b[b];

# Initial product p sent to depot d (available in t=1)
p_InitialToDepot{p in P, d in D}:
     	x[p,d,0]=x_zero_p[p,d];
     	
# Initial product p sent from depot d to market k (available in t=1)
p_InitialToMarket{p in P, d in D, k in K}:
     	v[p,d,k,0]=v_zero_p[p,d,k];
     	
# Minimum final inventory of components b
FinalInventory_b {b in B}:
    IC[b,last(T)] >= I_final_b[b];  
    
# Minimum final inventory of components p
Finalinventory_p{p in P, d in D}:
	IP[p,d,last(T)] >= I_final_pd[p,d];


# =============================================================================================================
# Logical binary constraints
# =============================================================================================================

# Logic 1: Shipment to any extreme south market on day t
Logic1 {t in T: t > 0}:
    M * EXT_S[t] >= sum {p in P, d in D, k in K_EXT_S} v[p,d,k,t];

# Logic 2: Shipment to any extreme north market on day t
Logic2 {t in T: t > 0}:
    M * EXT_N[t] >= sum {p in P, d in D, k in K_EXT_N} v[p,d,k,t];

# Logic 3: Prevent shipments to both north and south extreme markets on the same day
Logic3 {t in T: t > 0}:
    EXT_S[t] + EXT_N[t] <= 1;
    