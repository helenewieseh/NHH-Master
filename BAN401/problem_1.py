#### Problem 1

# We set the correct password and total amount of attempts
correct_password = "friend"
total_attempts = 5

# We create while loop to check the inputs
attempts_left = total_attempts
while attempts_left > 0:
    user_password = input("Enter your password to access the client database: ")
    if user_password == correct_password:
        print("Access granted. Welcome, friend!")
        break # We break the loop if the user inputs the correct password
    else:
        attempts_left -= 1 # If the input is incorrect, we decrease the number of remaining attempts

        # We calculate match percentage based on length
        matches = 0
        comparison_length = min(len(user_password), len(correct_password))

        # We compare characters up to the length of the shorter input
        for i in range(comparison_length):
            if user_password[i] == correct_password[i]:
                matches += 1

        # We calculate the match percentage
        match_percentage = (matches / len(correct_password)) * 100

        if match_percentage > 50: # We check for match greater than 50%
            print(f"Partial match: {match_percentage:.0f}% Attempts remaining: {attempts_left}")
        else:
            print(f"Incorrect password. Attempts remaining: {attempts_left}")

        if attempts_left == 0:
            print("Incorrect password supplied 5 (five) times. Access denied.")
            break # We break the loop if the user inputs the wrong password five times



