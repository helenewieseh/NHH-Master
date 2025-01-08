### Problem 3
#----------------------------------------------------------------------------------------------------------------------
## For loop scenario
#----------------------------------------------------------------------------------------------------------------------
# We ask the user how many customers to collect feedback from
num_customers = int(input("How many customers would you like to collect feedback from? "))

# List to store feedback
list_of_feedback = []

# We collect feedback using a for loop for the specified number of customers
for i in range(num_customers):
    feedback = input(f"Enter feedback for customer {i + 1}: ")
    list_of_feedback.append(feedback)

# We print the final list of feedback
print("You entered the following feedbacks:",list_of_feedback)

#----------------------------------------------------------------------------------------------------------------------
## While loop scenario
#----------------------------------------------------------------------------------------------------------------------

# List to store feedback
list_of_feedback = []

# We collect feedback using a while loop
while True:
    feedback = input("Enter your feedback: ")
    list_of_feedback.append(feedback)

    # We ask if the user wants to continue
    continue_feedback = input("Do you want to continue? (yes/no): ").strip().lower()
    if continue_feedback == "no":
        break

# We print the final list of feedback
print("You entered the following feedbacks:", list_of_feedback)