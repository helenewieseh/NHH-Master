print("")
print("Please answer the following questions to see if you qualify for the loan.")
print("")
#--------------------------------------------------------------------
# The following code is only included for visualization purposes in the "screenshot-part"
name=str(input("What is your name? "))
print("")
#--------------------------------------------------------------------
#Step 1:  Checking if the applicant meets all the criteria
#--------------------------------------------------------------------
# We start with making a variable that takes the applicants input and stores it in Python as integer.
# Next, we use the if-statement to decide whether the applicant criteria is met or not.
# If the criteria is met, it will just print an empty line.
# If it is not met, we use the exit()-function to exit the code and print that the applicant doesn't qualify for the loan.
# We have used this procedure for the variables: age, income, credit_score.
#--------------------------------------------------------------------
age=int(input("How old are you? "))
if 18<=age<=70:
    print("")
else:
    exit(print("Your age does not qualify for our loan"))
#--------------------------------------------------------------------
income=int(input("What is your income? "))
if 65000<=income:
    print("")
else:
        exit(print("Your income does not match our loan criteria"))
#--------------------------------------------------------------------
credit_score=int(input("What is your credit score? "))
if 700<=credit_score:
    print("")
else:
    exit(print("Your credit score is too low for this loan."))
#--------------------------------------------------------------------
# We decided to use a different approach for the input of existing debt.
# We have used a while()-loop to make sure that the applicant put in a debt that is 0<=
# As long as the applicant inputs a debt >=0, the program will save it as an integer and a variable.
# If they input a negative number, the program will print a message, and the applicant can input once again.
# The [break] function stops the while()-loop once the input is >0
while True:
    existing_debt=int(input("How much do you have in existing debt? "))
    if existing_debt>=0:
        break
    else:
        print(f"You cant have negative debt. Please write a number >=0")
# Once the program knows the correct existing debt, it will calculate the DTI.
# If the applicants DTI mets the criteria, it will print an empty line.
# If the DTI is over 40%, the program will print a message that the applicant can't have a loan
DTI=(existing_debt/income*100)
if 0<=DTI<=40:
    print("")
else:
    exit(print("Your Debt-to-Income Ratio is to high. Loan is not approved"))
#--------------------------------------------------------------------
# The last applicant criteria is to check whether the applicant is currently employed.
# We have created a new while-loop because we need the applicant to answer either Yes or No.
# If they answer 'yes' or 'Yes', the program will print an empty line and break out of the loop.
# If they answer 'no' og 'No', the program will print a message that they don't qualify for the loan and exit the code.
# IF they answer anything else than yes or no, the program will print a message that tells them to write either yes or no.
# This loop will only stop once they input either yes or no.
while True:
    employed=str(input("Are you currently employed? "))
    if employed=="Yes" or employed=="yes":
        print("")
        break
    elif employed=="No" or employed=="no":
        print("")
        exit(print("You need a job to apply for a loan. You does not qualify for the loan. "))
    else:
        print("Please answer either 'Yes' or 'No'. ")
#--------------------------------------------------------------------
print("You have met all the loan criteria and are qualified for the loan.")

#--------------------------------------------------------------------
# Step 2:   Collect information about what loan the applicant wants
#--------------------------------------------------------------------

print("We need some additional information to determine the loan terms.")
print("")
#--------------------------------------------------------------------
# Here is a while-loop where the purpose is to store a variable with a loan amount that meet the criteria.
# The loan_amount variable is stored as an integer based on the applicant input
# If the inputted loan amount meets criteria, the program just print an empty line
# if the loan amount is negative, it prints a message that reminds the applicant to input a positive number
# If the loan amount is higher than 50% of the income, it prints a message that states how much they can loan.
# The while-loop stops when the loan amount >=0 and <=0.5 income
#--------------------------------------------------------------------
while True:
    loan_amount=int(input("How much do you want to loan? "))
    if 0<=loan_amount<=(0.5*income):
        print("")
        break
    elif loan_amount<0:
        print("Please enter a positive loan amount" )
    else:
        print("You cannot loan more than 50% of your income. Maximum loan amount is $",0.5*income)
#--------------------------------------------------------------------
# We use a new while-loop to collect the amount of terms on the loan.
# If they enter a number between 1 and 30, the loop will break.
# If the number is either <0 or >30, the program will print a message that reminds them to choose a number from [1-30]
# The loop will stop once a number between [1,30] is inputted
#--------------------------------------------------------------------
while True:
    loan_term=int(input("How many years is the loan being paid over? "))
    if 1<=loan_term<=30:
        print("")
        break
    else:
        print("Please enter a number between 1 and 30 ")
#--------------------------------------------------------------------
# Now, we have enough information to determine the interest rate.
# We have made several if and elif statements that will print the corresponding interest rate based on the variables;
# credit_score and loan_term
# The [and] function means that both criteria must be met for the program to print the message under.
#--------------------------------------------------------------------
if 700<=credit_score<=750 and loan_term<=15:
    print("Your loan will have an interest rate of 5%")
elif 700<=credit_score<=750 and loan_term>15:
    print("Your loan will have an interest rate of 6%")
elif 751<=credit_score<=800 and loan_term<=15:
    print("Your loan will have an interest rate of 4%")
elif 751<=credit_score<=800 and loan_term>15:
    print("Your loan will have an interest rate of 5%")
elif credit_score>800 and loan_term<=15:
    print("Your loan will have an interest rate of 3%")
elif credit_score>800 and loan_term>15:
    print("Your loan will have an interest rate of 4%")
