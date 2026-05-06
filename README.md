# Razorpay Merchant Onboarding Funnel Analysis

## Project Overview
End-to-end data analysis of 49,357 merchant onboarding journeys 
across a 10-stage activation funnel for Razorpay — India's leading 
payment gateway. The project identifies revenue leakage, activation 
bottlenecks, and actionable recommendations for the Growth, Product, 
and Finance teams.

##Problem Statement
Razorpay generates revenue only when merchants complete onboarding and start processing live transactions.
Even though the platform was acquiring around 2,900 new merchants every month, many of them were not converting into active users. 
There was limited visibility into:
Where merchants were dropping off?
Why they were not completing onboarding?
How much potential revenue was being lost?
This project focuses on answering these questions and turning the findings into actionable insights.

## Tools Used
| Tool                        | Purpose                                      |
| --------------------------- | -------------------------------------------- |
| Python (Pandas, Matplotlib) | Data cleaning and initial exploration        |
| SQL Server                  | Writing business queries and funnel analysis |
| Power BI (DAX)              | Building dashboards and visualizing insights |

## Dataset
- 50,752 raw merchant records
- 26 columns including 10 timestamp columns
- Jan–Dec 2024
- Columns: merchant_id, merchant_category, business_type, 
  payment_method, city, kyc_status, monthly_gmv_inr, 
  10 funnel stage timestamps

##Project Structure
The project is divided into three main parts:

## Phase 1 — Data Cleaning (Python)
Performed 6-step structured cleaning on 50,752 raw records:

- **Step 1:** Data inspection — shape, dtypes, null audit
- **Step 2:** Missing values — dropped 254 null merchant_id rows, 
  filled city and upi_app nulls with meaningful labels
- **Step 3:** Categorical standardization — fixed 28 payment method 
  variants, 18 KYC status variants, 41 city name variants using 
  contains-based cleaning functions
- **Step 4:** Deduplication — removed 279 fully duplicate rows, 
  deduplicated by merchant_id keeping most advanced funnel stage
- **Step 5:** Data types — converted GMV to float, all 10 timestamps 
  to datetime, removed future-dated timestamps using 
  pd.Timestamp.now()
- **Step 6:** Outliers — fixed 84 negative GMV values, capped 84 
  extreme outliers using IQR Winsorization

## Phase 2 — SQL Analysis (MS SQL Server)
Wrote 12 business queries across 2 dashboards answering real 
stakeholder questions:

**Dashboard 1 — Funnel & Growth**
- Q1: Overall merchant activation rate at each funnel stage
- Q2: Stage-by-stage drop-off % using LAG() window function
- Q3: Monthly signup trend — is acquisition growing?
- Q4: Average days from signup to first live transaction
- Q5: Conversion rate by merchant category
- Q6: Conversion rate by device type
- Q7: Conversion rate by business type

**Dashboard 2 — Revenue & Failure**
- Q8: City-wise activation rate and stuck merchant count
- Q9: Total GMV locked in incomplete merchants by stage
- Q10: KYC failure reasons ranked by merchant count
- Q11: Revenue impact per failure reason
- Q12: Premium upgrade profile — top segments for upsell

## Key Findings

| Finding | Value |
|---------|-------|
| End-to-end conversion rate | 18% |
| Biggest single drop-off | 31.57% (Signup → KYC Start) |
| Merchants lost per month at one step | ~916 |
| Total locked GMV | ₹9,649 crore |
| Active merchants not on premium | 60.18% |
| Worst city activation | Mumbai — 16.21% |
| Top KYC failure reason | GST Mismatch — 247 merchants |

## Recommendations

1. **Fix post-signup guidance** — add onboarding checklist after 
   signup to recover ~900 merchants/month (₹2,646 Cr GMV)
2. **Re-engagement campaign** — target 13,133 landing page 
   drop-offs carrying ₹3,311 Cr locked GMV
3. **Fix top 3 KYC failures in one sprint** — GST mismatch, 
   Document mismatch, Bank account invalid — unblocks 720 
   merchants and ₹177 Cr GMV
4. **Deploy field support to Mumbai and Chennai** — highest 
   stuck merchant counts (1,860 and 1,853 respectively)
5. **Target SaaS/Bengaluru/Individual for premium upsell** — 
   76.92% upgrade rate, highest in dataset

## SQL Concepts Used
CTEs · LAG() Window Function · DATEDIFF · CASE WHEN · 
GROUP BY · HAVING · NULLIF · Subqueries · UNION ALL · 
Multi-column segmentation

## Python Concepts Used
Pandas · pd.to_datetime · pd.to_numeric · dropna · 
drop_duplicates · str.strip().str.lower() · apply() · 
IQR Winsorization

