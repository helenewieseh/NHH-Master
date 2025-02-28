import math  # Importing math module for factorial calculations

# Parameters
N = 5 # Total number of machines
lambda_rate = 1 / 8 # Failure rate 
mu_rate = 1 / 2 # Repair rate 

# Function to calculate P0 (probability that there are no broken machines)
def calculate_P0(N, c, lambda_rate, mu_rate):
    sum1 = sum(
        (math.factorial(N) / (math.factorial(N - n) * math.factorial(n))) * 
        (lambda_rate / mu_rate) ** n 
        for n in range(c)
    )
    
    sum2 = sum(
        (math.factorial(N) / (math.factorial(N - n) * math.factorial(c) * c ** (n - c))) * 
        (lambda_rate / mu_rate) ** n 
        for n in range(c, N + 1)
    )
    
    P0 = 1 / (sum1 + sum2)
    return P0

# Function to calculate probability of n broken machines (Pn)
def calculate_Pn(N, c, lambda_rate, mu_rate, P0):
    Pn_values = []
    for n in range(N + 1):
        if n < c:
            Pn = (math.factorial(N) / (math.factorial(N - n) * math.factorial(n))) * \
                 (lambda_rate / mu_rate) ** n * P0
        else:
            Pn = (math.factorial(N) / (math.factorial(N - n) * math.factorial(c) * c ** (n - c))) * \
                 (lambda_rate / mu_rate) ** n * P0
        Pn_values.append(Pn)
    return Pn_values

# Function to calculate Lq (average number of broken machines in service queue)
def calculate_Lq(N, c, Pn_values):
    return sum((n - c) * Pn for n, Pn in enumerate(Pn_values) if n >= c)

# Function to calculate L (average number of broken machines)
def calculate_L(N, c, Pn_values, Lq):
    sum_nPn = sum(n * Pn_values[n] for n in range(c))
    sum_Pn = sum(Pn_values[n] for n in range(c))
    return Lq + sum_nPn + c * (1 - sum_Pn)

# Function to calculate W (average downtime)
def calculate_W(L, lambda_rate, N):
    return L / (lambda_rate * (N - L))

# Function to calculate Wq (average time a broken machine spends in service queue)
def calculate_Wq(Lq, lambda_rate, N, L):
    return Lq / (lambda_rate * (N - L))

# Function to calculate the expected cost per hour
def calculate_expected_cost(N, c, L):
    return 50 * L + 10 * c


# Calculate metrics for each value of c
results = []
for c in range(1, N + 1):
    P0 = calculate_P0(N, c, lambda_rate, mu_rate)
    Pn_values = calculate_Pn(N, c, lambda_rate, mu_rate, P0)
    Lq = calculate_Lq(N, c, Pn_values)
    L = calculate_L(N, c, Pn_values, Lq)
    W = calculate_W(L, lambda_rate, N)
    Wq = calculate_Wq(Lq, lambda_rate, N, L)
    cost = calculate_expected_cost(N, c, L)

    # Store results
    results.append({
        'c': c,
        'P0': P0,
        'Pn_values': Pn_values,
        'L': L,
        'Lq': Lq,
        'W': W,
        'Wq': Wq,
        'cost': cost
    })
    
    # Print the results for each value of c
    print(f"\nFor c = {c}:")
    print(f"P0 = {P0:.4f}")
    # Print all Pn values
    for n, Pn in enumerate(Pn_values):
        if n > 0:
            print(f"P{n} = {Pn:.4f}")
    print(f"L (mean number in system) = {L:.4f} machines")
    print(f"Lq (mean number in queue) = {Lq:.4f} machines")
    print(f"W (average total time in system) = {W:.4f} hours")
    print(f"Wq (average queue time) = {Wq:.4f} hours")
    print(f"Expected cost per hour = ${cost:.2f}")

# Find optimal number of repairmen (c) that minimizes cost
optimal = min(results, key=lambda x: x['cost'])
print(f"\nOptimal solution:")
print(f"Number of repairmen (c) = {optimal['c']}")
print(f"Minimum expected cost per hour = ${optimal['cost']:.2f}")
