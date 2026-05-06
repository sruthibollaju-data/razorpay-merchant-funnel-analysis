Use razorpay_analysis


SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

SELECT 
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'fmerchant_funnel'
ORDER BY ORDINAL_POSITION

select top 5 * from funnel.merchant_funnel

-- check your current compatibility level
SELECT name, compatibility_level 
FROM sys.databases
WHERE name = DB_NAME();

select top 5 * from funnel.merchant_funnel;
--Q1
--Overall merchant activation rate — what % reached each stage?
--BQ:"Out of all the merchants who visited our platform in 2024, how many actually went live and started transacting? What is our end-to-end conversion rate?"
select
    count(*) as total_merchant,
    count(case when ts_landing_page_view is not null then 1 end) Total_page_visit,
    count(case when ts_signup_complete is not null then 1 end) reached_signup,
    count(case when ts_kyc_started is not null then 1 end) reached_kyc_started,
    count(case when ts_kyc_submitted is not null then 1 end) reached_kyc_submitted,
    count(case when ts_kyc_verified is not null then 1 end) reached_Kyc_verified,
    count(case when ts_api_key_generated is not null then 1 end) reached_api_key,
    count(case when ts_first_test_txn is not null then 1 end) reached_first_test,
    count(case when ts_first_live_txn is not null then 1 end) reached_first_live,
    count(case when ts_active_merchant is not null then 1 end) reached_active_merchat,
    count(case when ts_premium_upgrade is not null then 1 end) reached_premium_upgrade,

    round(cast(count(case when ts_first_live_txn is not null then 1 end) * 100.0 / count(*) as decimal(10,2)),2)as converstion_rate

from funnel.merchant_funnel;

--Q2 "I need to know exactly where in the funnel we are bleeding merchants. Which single step has the worst drop-off and how bad is it compared to the step before?"
--Stage-by-stage drop-off — where do we lose the most merchants?

with funnel_count as (
    SELECT '1.Landing Page'      AS stage, 1  AS sort_order, COUNT(*) AS merchants FROM funnel.merchant_funnel
    UNION ALL
    SELECT '2.Signup Complete'   AS stage, 2  AS sort_order, COUNT(CASE WHEN ts_signup_complete   IS NOT NULL THEN 1 END) FROM funnel.merchant_funnel
    UNION ALL
    SELECT '3.KYC Started'       AS stage, 3  AS sort_order, COUNT(CASE WHEN ts_kyc_started       IS NOT NULL THEN 1 END) FROM funnel.merchant_funnel
    UNION ALL
    SELECT '4.KYC Submitted'     AS stage, 4  AS sort_order, COUNT(CASE WHEN ts_kyc_submitted     IS NOT NULL THEN 1 END) FROM funnel.merchant_funnel
    UNION ALL
    SELECT '5.KYC Verified'      AS stage, 5  AS sort_order, COUNT(CASE WHEN ts_kyc_verified      IS NOT NULL THEN 1 END) FROM funnel.merchant_funnel
    UNION ALL
    SELECT '6.API Key Generated' AS stage, 6  AS sort_order, COUNT(CASE WHEN ts_api_key_generated IS NOT NULL THEN 1 END) FROM funnel.merchant_funnel
    UNION ALL
    SELECT '7.First Test Txn'    AS stage, 7  AS sort_order, COUNT(CASE WHEN ts_first_test_txn    IS NOT NULL THEN 1 END) FROM funnel.merchant_funnel
    UNION ALL
    SELECT '8.First Live Txn'    AS stage, 8  AS sort_order, COUNT(CASE WHEN ts_first_live_txn    IS NOT NULL THEN 1 END) FROM funnel.merchant_funnel
    UNION ALL
    SELECT '9.Active Merchant'   AS stage, 9  AS sort_order, COUNT(CASE WHEN ts_active_merchant   IS NOT NULL THEN 1 END) FROM funnel.merchant_funnel
    UNION ALL
    SELECT '10.Premium Upgrade'  AS stage, 10 AS sort_order, COUNT(CASE WHEN ts_premium_upgrade   IS NOT NULL THEN 1 END) FROM funnel.merchant_funnel
)
select
    stage, merchants,
    lag(merchants) over(order by sort_order) as previous_stage,
    lag(merchants) over(order by sort_order) - merchants as mechant_lost,
   ROUND(
        CAST(LAG(merchants) OVER (ORDER BY sort_order) - merchants AS FLOAT)
        / LAG(merchants) OVER (ORDER BY sort_order) * 100, 2
    ) AS drop_off_pct
from funnel_count
order by sort_order

--Q3 Monthly signup trend — is merchant acquisition growing?
select
    format(ts_signup_complete, 'yyyy-MM') Month,
    count(*) as signup_month
from funnel.merchant_funnel
where format(ts_signup_complete, 'yyyy-MM') is not null
group by format(ts_signup_complete, 'yyyy-MM')
order by signup_month

--Q4 Average days from signup to first live transaction
--On average how many days does it take a merchant to go from signup to their first live transaction? And does this vary by merchant category?"
select top 5 * from funnel.merchant_funnel
select
    round(avg(cast(datediff(DAY,ts_signup_complete,ts_first_live_txn) as float)),1) as avg_days_to_live 
from funnel.merchant_funnel
where ts_signup_complete is not null and ts_first_live_txn is not null

select
    merchant_category,
    round(avg(cast(datediff(DAY,ts_signup_complete,ts_first_live_txn) as float)),1) as avg_days_to_live 
from funnel.merchant_funnel
where ts_signup_complete is not null and ts_first_live_txn is not null
group by merchant_category
order by avg_days_to_live;
--Q5 "Which merchant categories are converting best from signup to live transaction? We are spending equal acquisition budget on all categories — should we shift budget towards the ones converting better?"
select top 5 * from funnel.merchant_funnel

select
    merchant_category,
    count(*) Total_merchant,
    count(case when ts_first_live_txn is not null then 1 end) went_live,
    round(cast(count(case when ts_first_live_txn is not null then 1 end) as float)/ count(*) * 100,2) converstion_rate_pct
from funnel.merchant_funnel
group by merchant_category
order by converstion_rate_pct desc

--Q6 "Are merchants who sign up on mobile converting at the same rate as desktop users? We are thinking of building a mobile-first onboarding experience — does the data support this investment?"
select
    device_type,
    count(*) Total_merchant,
    count(case when ts_first_live_txn is not null then 1 end) went_live,
    round(cast(count(case when ts_first_live_txn is not null then 1 end) as float)/ count(*) * 100,2) converstion_rate_pct
from funnel.merchant_funnel
group by device_type
order by converstion_rate_pct desc
--Q7:Which business type has the highest conversion rate?
select
    business_type,
    count(*) Total_merchant,
    count(case when ts_first_live_txn is not null then 1 end) went_live,
    round(cast(count(case when ts_first_live_txn is not null then 1 end) as float)/ count(*) * 100,2) converstion_rate_pct
from funnel.merchant_funnel
group by business_type
order by converstion_rate_pct desc

--****************************************************************************
--Q8 "Which cities are producing the most activated merchants and which cities have high signups but low activation? We want to deploy onboarding support teams on the ground — where should they go?"
select
    city,
    count(*) Total_merchants,
    count(case when ts_first_live_txn is not null then 1 end) went_live,
    count(case when ts_first_live_txn is null and ts_signup_complete is not null then 1 end) stuck_merchants,
    round(cast(count(case when ts_first_live_txn is not null then 1 end) as float)/ count(*) * 100,2) converstion_rate_pct
from funnel.merchant_funnel
where city != 'Unknown'
group by city
order by stuck_merchants desc
--Q9 "How much total GMV is sitting with merchants who signed up but never went live? These merchants have payment 
--volume but we are not processing it — what is the revenue opportunity if we re-engage them?"
select
    count(*) as total_merchant,
    round(sum(monthly_gmv_inr),0) as total_gmv,
    round(avg(monthly_gmv_inr),0) as avg_gmv_per_stuck_merchant
from funnel.merchant_funnel
where  ts_first_live_txn is null and monthly_gmv_inr is not null
-- Part B: Locked GMV by funnel stage
select
    final_stage_reached,
    count(*) as total_merchant,
    round(sum(monthly_gmv_inr),0) as locked_gmv
from funnel.merchant_funnel
where  ts_first_live_txn is null and monthly_gmv_inr is not null
group by final_stage_reached
order by locked_gmv desc

--Q10 "What are the top reasons merchants are failing KYC? And how many merchants are blocked by each reason? 
--We want to fix the most impactful issue first."
select
    failure_reason,
    count(*) as mechant_blocked,
    round(cast(count(*) as float)/ (select count(*) from funnel.merchant_funnel where failure_reason is not null) * 100  ,2) pct_of_total_failure
from funnel.merchant_funnel
where failure_reason is not null
group by failure_reason
order by mechant_blocked desc


--Q11 "For each failure reason — how much total GMV are those blocked merchants carrying? We want to prioritize 
--fixes not just by merchant count but by revenue impact."
select
    failure_reason,
    count(*) merchant_blocked,
    round(sum(monthly_gmv_inr),2) total_locked_gmv,
    round(avg(monthly_gmv_inr),0) as avg_gmv_per_merchant
from funnel.merchant_funnel
where failure_reason is not null and monthly_gmv_inr is not null
group by failure_reason
order by total_locked_gmv desc;

--Q12 "Which type of merchant — by category, city and business type — is most likely to upgrade to premium? 
--We are launching a targeted upsell campaign next quarter and need to know exactly who to call."
select
    merchant_category,
    city,
    business_type,
    count(case when is_active_merchant = 1 then 1 end) as active_merchant,
    count(case when is_premium = 1 then 1 end) as premium_merchant,
     ROUND(
        CAST(COUNT(CASE WHEN is_premium = 1 THEN 1 END) AS FLOAT)
        / NULLIF(COUNT(CASE WHEN is_active_merchant = 1 THEN 1 END), 0) * 100, 2
    ) AS premium_upgrade_rate_pct
from funnel.merchant_funnel
where city!='Unknown'
group by 
    merchant_category,
    city,
    business_type
HAVING COUNT(CASE WHEN is_active_merchant = 1 THEN 1 END) >= 10
ORDER BY premium_upgrade_rate_pct DESC;