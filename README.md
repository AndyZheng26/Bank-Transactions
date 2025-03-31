--- SQL CLEANING & ANALYSIS -> [ Bank_Transactions_SQL_Markdown ](https://github.com/AndyeliSays/Bank-Transactions/blob/main/bank_transactions_sql_markdown.md)

--- TABLEAU DASHBOARD ->

<img src=https://github.com/AndyeliSays/Bank-Transactions/blob/main/assets/BankDashboard1.png>
<img src=https://github.com/AndyeliSays/Bank-Transactions/blob/main/assets/Bank_Dashboard2.png>
<img src=https://github.com/AndyeliSays/Bank-Transactions/blob/main/assets/BankDashboard3.png>

<h1 align="center">Bank Transactions </h1>

## Introduction:
  
This project transforms raw transaction data into actionable insights to make data-driven decisions for a Banking Instituion. The goal is to leverage banking transaction data to identify patterns, improve userservice, and detect potential fraud. By analyzing transaction patterns, user behaviors, and payment methods, we will pinpoint areas for improvement in banking processes.

## Business Task & Objectives: 
  
Key metrics involving transaction patterns, user demographics, payment types, and financial behavior will be explored to provide a comprehensive understanding of banking operations. Some examples of questions, topics addressed but not limited to:

- User segmentation to identify trends in financial behavior.
- What are the key transaction metrics and overall banking performance?
- Which merchant areas are seeing the most traffic? Fraud? Errors?
- How do debt and spending fit into the context of transactions?
- What are the yearly transaction trends and seasonal patterns?
- How do different payment methods (Chip, Online, Swipe) affect transaction volume?


The dataset consists of 5 main tables: Transactions( >1million rows), Users, Cards, Merchants and Fraud; containing bank transaction data spanning from  2010 to 2019.

- Cleaning Process and Dataset Breakdown:

<img src=https://github.com/AndyeliSays/Bank-Transactions/blob/main/assets/cleaning_process.png>

<img src=https://github.com/AndyeliSays/Bank-Transactions/blob/main/assets/dataconnections.png width=300>

## Tools:
- Data cleaning, preparation, analysis done in POWERQUERY & SQL.
- Data visualizations made in TABLEAU.

## Data Source: 
[Bank Transactions Dataset](https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets/data)

---

<h1 align="center">Insights</h1>


## Transactions
- The majority of the transactions and movement is concetrated within middle-age groups.
- As age increases, so does the number of credit cards owned by users.
- Total transaction volume is approximately $570 million across 13.3 million transactions, with middle-aged users (36-50) representing the key demographic despite having a lower average credit score (718) than younger adults.
- Transaction activity is heavily concentrated in major metropolitan areas, particularly in the eastern United States.
- Young adults (18-25) show responsible credit behavior with the highest average credit score (726) despite lower financial activity, while older users tend to hold more credit cards.
- Females have a higher average yearly income ($47,394 vs. $45,946), a larger user base (6.8M vs. 6.4M), total transaction amount ($292M vs $277M) and slightly more total debt than males.
    - However, the average debt per user is slightly lower for females($57,350) compared to males ($58,739). This could imply males are taking onhigher individual debt.
- Most users use their cards through chip and swipe transactions.
- Grocery stores generate the most transactions (1.59M) but with lower average amounts ($25.73), while money transfers lead in total transaction amount ($51.78M) with higher average transactions ($90.30).

## Financial Behavior
- The average user financial profile includes a credit score of 709.7, a debt-to-income ratio of 1.39, and a significantly higher spending-to-income ratio of 6.23, suggesting most users spend a substantial portion of their income.
- Most Users maintain debt proportional to their income with exceptions in higher income brackets.
- Card ownership patterns reveal most Users prefer holding multiple cards (highest concentration at 3-4 cards), with those Users demonstrating the most balanced financial behaviors and highest transaction volumes.
- 2075 Users do not own cards.
- The "Good" credit score range (670–739) has the highest number of Users (931) while the "Poor" credit score range (300–579) has the fewest Users, however they all exhibit very similar average yearly income.

## Fraud & Error

- There are a total of 13,332 fraudulent transactions (0.1% of total) totaling $1.47M with an average value of $110.23, while transaction errors are significantly more prevalent with 204,034 occurrences (1.54% of total) totaling $12.15M.
- Error analysis shows "Insufficient Balance" as the most frequent specific error (123,552), followed by "Bad PIN" (32,110) and "Technical Glitch" (26,271), with card detail errors including Bad Card Number (7,767), Bad Expiration (7,191), and other validation issues.
- Service stations, grocery stores and money transfer transactions have the most error transactions.
- Department stores, Cruise lines and Wholesale Clubs account for most of the money being counted as fraud within transactions.
- Swipe transactions lead with 99,288 errors, chip transactions follow with 69,185, and online transactions with the lowest of 35,561 errors.
- The transactions show 2M exact integer transactions, 152,885 transactions ending in "00", and 10,455 transactions flagged as "Possible Structuring" (values ≤ $10,000), with no transactions exceeding $10,000.

<h1 align="center">Recommendations </h1>

## User Segmentation
- Develop tailored financial products for middle-aged Users (36-50) who show highest transaction volume ($197M) but have declining credit scores.
- Create educational programs for young adults (18-25) to maintain their excellent credit scores (726 average) as they take on more financial responsibilities.
  - More research is needed to understand this age group has significantly less transactions then all other age groups.
- Focus acquisition efforts on the 2,075 Users with no cards through targeted onboarding campaigns.
- Design card offerings optimized for 3-4 cards, the preference shown by the most financially active Users.

## Transactions
- Create location-specific promotions for areas with high transaction density but lower average values.
- Focus on seamless payment systems for Money Transfer and Utilities that cater to fewer, high-value transactions.
- Continue promoting Chip technology adoption given its popularity (821,407 transactions) and security benefits.
- Prioritize service improvements in high-volume cities (Houston, Miami, NYC-Brooklyn) to maximize impact.
- Develop specialized partnerships with grocery stores (1.59M transactions) and service stations given their high transaction volumes.
 
## Financial Health
- Address the concerning year-over-year decline (-17.03% in transaction volume) through targeted User reactivation campaigns.
  - More details needed to understand the drop off in transactions for the most recent year.
- Implement credit improvement programs for Users with scores below the average (709.7).
- Provide debt consolidation loans or refinancing opportunities for Users with high debt-to-income ratios (above 1.39).
- Implement targeted financial programs for Users with high spending-to-income ratios (6.23 average).
- Use recurring month data for forecasting merchant revenue, with higher recurring months indicating steadier income streams.

## Fraud & Error Prevention
- Focus on small-value, high-frequency fraud cases by enhancing detection systems for transactions below $150 (Avg.Max Fraud Transaction).
- Strengthen fraud detection for Department Stores, Cruise Lines, and Wholesale Clubs which account for most fraud.
- Flag unusual amounts early for "Possible Structuring" (values ≤ $10,000).
- Address "Insufficient Balance" errors (123,552 occurrences) through proactive balance alerts.
- Reduce "Bad PIN" issues (32,110 occurrences) through enhanced user education.
- Resolve "Technical Glitch" problems (26,271 occurrences) by improving infrastructure reliability.
- Introduce newer point-of-sale systems to reduce swipe transaction errors (99,288 occurrences).

 


  
