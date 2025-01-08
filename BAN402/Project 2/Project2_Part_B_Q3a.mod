reset;
#=============================================================================================================
# Part B - Question 3a - Model file
# =============================================================================================================

# =============================================================================================================
# Sets
# =============================================================================================================

set TEAMS;                                     # Set of teams
set MATCHES;                                   # Set of matches
set GROUPS;                                    # Set og groups 
set VENUES;                                    # Set of venues
set DAYS ordered;                              # Ordered set of days
set GERMANY_MATCHES within MATCHES;            # Subset of Germany's matches
set VenueDaysPairs within {DAYS, VENUES};      # Subset of predefined (day, venue) pairs
# =============================================================================================================
# Parameters
# =============================================================================================================

param distance{VENUES, VENUES};                       # Distance between venue v1 and v2
param t1{MATCHES} symbolic;                           # Team 1 playing in match m
param t2{MATCHES} symbolic;                           # Team 2 playing in match m
param group{TEAMS} symbolic;                          # Group of team t
param day_of_match{MATCHES};                          # Day scheduled for match m
param matches_per_venue{VENUES};                      # Capacity at each venue
param germany_match_venue{GERMANY_MATCHES} symbolic;  # Venue of Germany's matches
# =============================================================================================================
# Decision variables
# =============================================================================================================

# Binary variable to indicate if a match m is played at venue v
var x{MATCHES, VENUES} binary;          

# Binary variable to indicate if team t travels between consecutive matches m1 at v1 and m2 at v2
var y{TEAMS, MATCHES, MATCHES, VENUES, VENUES} binary;  

# Total travel distance for team t
var travel{TEAMS} >= 0;  

# Longest travel distance 
var longest_travel >= 0; 

# Shortest travel distance 
var shortest_travel >= 0;  
# =============================================================================================================
# Auxiliary variables
# =============================================================================================================

# Auxiliary binary variable to indicate if a group g has a match at venue v
var group_venue_present{GROUPS, VENUES} binary;

# Auxiliary binary variable to indicate if a venue v has a match by June 18
var early_game_venue{VENUES} binary;

# Auxiliary binary variable to indicate if a venue v has a match on or after June 24
var late_game_venue{VENUES} binary;


# =============================================================================================================
# Objective function: Minimize total difference in travel differences among all teams
# =============================================================================================================

minimize MinimizeTravelDifference:
    longest_travel - shortest_travel;

# =============================================================================================================
# Logical constraints
# =============================================================================================================

# Ensure that group_venue_present can only be set to 1 if group g has at least one match scheduled at venue v:
subject to DefineGroupVenuePresent {g in GROUPS, v in VENUES}:
    group_venue_present[g, v] <= sum {m in MATCHES: group[t1[m]] = g or group[t2[m]] = g} x[m, v];
    # If there are matches of group `g` at venue `v`, then `group_venue_present` will be 1.

# Ensure that early_game_venue can only be set to 1 if venue v has at least one match scheduled on or before June 18:
subject to DefineEarlyGameVenue {v in VENUES}:
    early_game_venue[v] <= sum {m in MATCHES: day_of_match[m] <= 18} x[m, v];

# Ensure that late_game_venue can only be set to 1 if venue v has at least one match scheduled after or on June 24. 
subject to DefineLateGameVenue {v in VENUES}:
    late_game_venue[v] <= sum {m in MATCHES: day_of_match[m] >= 24} x[m, v];

subject to GermanyMatchesConstraint {m in GERMANY_MATCHES}:
	x[m, germany_match_venue[m]] = 1;

# Ensure venues host matches on specified days
subject to PredefinedVenueDays {(d, v) in VenueDaysPairs}:
    sum {m in MATCHES: day_of_match[m] = d} x[m, v] = 1;
    
    
# Ensure longest_travel captures the longest travel distance
subject to DefineLongestTravel {t in TEAMS}:
    longest_travel >= travel[t];

# Ensure shortest_travel captures the shortest travel distance
subject to DefineShortestTravel {t in TEAMS}:
    shortest_travel <= travel[t];


# Linearization Constraints for y
subject to LinkY1 {t in TEAMS, m1 in MATCHES, m2 in MATCHES, v1 in VENUES, v2 in VENUES:
    (t1[m1] = t or t2[m1] = t) and 
    (t1[m2] = t or t2[m2] = t) and 
    day_of_match[m1] < day_of_match[m2]}:
    
    y[t, m1, m2, v1, v2] <= x[m1, v1];  # Ensure that y can only be set to 1 if match m1 is scheduled at venue v1

subject to LinkY2 {t in TEAMS, m1 in MATCHES, m2 in MATCHES, v1 in VENUES, v2 in VENUES:
    (t1[m1] = t or t2[m1] = t) and 
    (t1[m2] = t or t2[m2] = t) and 
    day_of_match[m1] < day_of_match[m2]}:
    
    y[t, m1, m2, v1, v2] <= x[m2, v2];  # Ensure that y can only be set to 1 if match m2 is scheduled at venue v2


subject to LinkY3 {t in TEAMS, m1 in MATCHES, m2 in MATCHES, v1 in VENUES, v2 in VENUES:
    (t1[m1] = t or t2[m1] = t) and 
    (t1[m2] = t or t2[m2] = t) and 
    day_of_match[m1] < day_of_match[m2]}:
    
    y[t, m1, m2, v1, v2] >= x[m1, v1] + x[m2, v2] - 1;  # Ensure that y can only be set to 1 if both x-variables are 1
    
    
# =============================================================================================================
# General constraints
# =============================================================================================================

# Each match must be schedules at exactly one venue
subject to VenueAssignment {m in MATCHES}:
    sum{v in VENUES} x[m,v] = 1;

# Each venue must host the exact number of matches assigned to it in the real schedule
subject to MatchesPerVenue {v in VENUES}:
    sum{m in MATCHES} x[m,v] = matches_per_venue[v];

# Ensure there is a rest period for two days after a match at a venue
subject to TwoDayRestPeriod {v in VENUES, d in DAYS: ord(d) <= card(DAYS) - 2}:
    sum{m in MATCHES: day_of_match[m] = d or day_of_match[m] = d+1 or day_of_match[m] = d+2} x[m,v] <= 1;
 
# Ensure group games are distributed across at least four different venues:
subject to GroupGamesDistribution {g in GROUPS}:
    sum {v in VENUES} group_venue_present[g, v] >= 4;

# No venue can host more than two matches for the same group
subject to MaxGroupGamesPerVenue {v in VENUES, g in GROUPS}:
    sum{m in MATCHES: group[t1[m]] = g or group[t2[m]] = g} x[m,v] <= 2;

# Force each venue to have at least one early game:
subject to EnsureEarlyGameAtEveryVenue:
    sum {v in VENUES} early_game_venue[v] = card(VENUES);

# Ensure every venue has at least one late game
subject to EnsureLateGameAtEveryVenue:
    sum {v in VENUES} late_game_venue[v] = card(VENUES);
    

# Calculation of travel distace:
subject to TravelDistance {t in TEAMS}:
    travel[t] = sum{m1 in MATCHES, m2 in MATCHES, v1 in VENUES, v2 in VENUES:
        (t1[m1] = t or t2[m1] = t) and 
        (t1[m2] = t or t2[m2] = t) and 
        day_of_match[m1] < day_of_match[m2] and
        forall {m3 in MATCHES: day_of_match[m1] < day_of_match[m3] < day_of_match[m2]} 
            (t1[m3] != t and t2[m3] != t)} # Ensure matches are truly consecutive
    distance[v1,v2] * y[t,m1,m2,v1,v2];








