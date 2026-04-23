USE game_project;

----------------------------------------
-- B1: Kiểm tra kiểu dữ liệu
----------------------------------------

SELECT 
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.tables t
JOIN sys.columns c 
    ON t.object_id = c.object_id
JOIN sys.types ty 
    ON c.user_type_id = ty.user_type_id
WHERE t.name IN (
    'install_logs',
    'login_logs',
    'session_logs',
    'transaction_logs',
    'progression_logs'
)
ORDER BY t.name, c.column_id;
/* Note : trans_user_id  data_type: float
		  event_timestamp data_type:nvarchar
*/

SELECT TOP 20 * FROM install_logs;
SELECT TOP 20 * FROM login_logs;
SELECT TOP 20 * FROM session_logs;
SELECT TOP 20 * FROM transaction_logs;
SELECT TOP 20 * FROM progression_logs;

----------------------------------------
-- B2: Check lỗi dữ liệu
----------------------------------------

--2.1 Kiểm tra format các cột datetime

-- bảng install_logs
SELECT TOP 50 event_date
FROM install_logs
WHERE event_date IS NOT NULL
  AND TRY_CONVERT(date, event_date) IS NULL;

-- bảng login_logs
SELECT TOP 50 event_date, first_login_date
FROM login_logs
WHERE (TRY_CONVERT(date, event_date) IS NULL AND event_date IS NOT NULL)
   OR (TRY_CONVERT(date, first_login_date) IS NULL AND first_login_date IS NOT NULL);

-- bảng sesion_logs
SELECT TOP 50 event_date
FROM session_logs
WHERE event_date IS NOT NULL
  AND TRY_CONVERT(DATE, event_date) IS NULL;

-- bảng transaction_logs
SELECT TOP 50 transaction_date
FROM transaction_logs
WHERE transaction_date IS NOT NULL
  AND TRY_CONVERT(DATE, transaction_date) IS NULL;

-- bảng progression_logs
SELECT TOP 50 event_date, event_timestamp
FROM progression_logs
WHERE (TRY_CONVERT(date, event_date) IS NULL AND event_date IS NOT NULL)
   OR (TRY_CONVERT(datetimeoffset, event_timestamp) IS NULL AND event_timestamp IS NOT NULL);

--=> các cột datetime không có lỗi format date

--2.2 Kiểm tra các cột số có convert đc ko:

SELECT TOP 50 transaction_amount
FROM transaction_logs
WHERE TRY_CONVERT(decimal(18,2), transaction_amount) IS NULL
  AND transaction_amount IS NOT NULL;

SELECT TOP 50 transaction_amount
FROM transaction_logs
WHERE TRY_CONVERT(decimal(18,2), transaction_amount) IS NULL
  AND transaction_amount IS NOT NULL;

SELECT TOP 50 session_number
FROM session_logs
WHERE TRY_CONVERT(int, session_number) IS NULL
  AND session_number IS NOT NULL;

SELECT TOP 50 level
FROM progression_logs
WHERE TRY_CONVERT(int, level) IS NULL
  AND level IS NOT NULL;

--=> các cột số không có lỗi format

--2.3 Kiểm tra thông tin các bảng (quy mô dữ liệu, khoảng thời gian,số user/session/transaction unique)

-- bảng install
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT [user_id]) AS distinct_users,
    MIN(TRY_CONVERT(date, event_date)) AS min_date,
    MAX(TRY_CONVERT(date, event_date)) AS max_date
FROM install_logs;

-- bảng login
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT [user_id]) AS distinct_users,
    MIN(TRY_CONVERT(date, event_date)) AS min_date,
    MAX(TRY_CONVERT(date, event_date)) AS max_date,
	MIN(TRY_CONVERT(date, first_login_date)) AS min_first_login_date,
    MAX(TRY_CONVERT(date, first_login_date)) AS max_first_login_date
FROM login_logs;

-- bảng	session

SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT [user_id]) AS distinct_users,
	COUNT(DISTINCT [session_id]) AS distinct_session,
    MIN(TRY_CONVERT(date, event_date)) AS min_date,
    MAX(TRY_CONVERT(date, event_date)) AS max_date
FROM session_logs;

-- bảng	transaction

SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT transaction_id) AS distinct_transactions,
    COUNT(DISTINCT trans_user_id) AS distinct_payers,
    SUM(TRY_CONVERT(decimal(18,2), transaction_amount)) AS total_revenue,
    MIN(TRY_CONVERT(date, transaction_date)) AS min_date,
    MAX(TRY_CONVERT(date, transaction_date)) AS max_date
FROM transaction_logs;

-- bảng progression

SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT [user_id]) AS distinct_users,
    MIN(TRY_CONVERT(date, event_date)) AS min_date,
    MAX(TRY_CONVERT(date, event_date)) AS max_date,
	MIN(TRY_CONVERT(date, event_timestamp)) AS min_event_date,
    MAX(TRY_CONVERT(date, event_timestamp)) AS max_event_date
FROM progression_logs;

/* Tổng quan:
- 1440 users install từ 29/1 - 23/1
- 1002 users login từ 23/1 - 17/3
- 1440 users với 12758 session từ 23/1 - 17/3
- 713 transaction, 112 payers, ~75tr từ 23/1 - 17/3
- 916 user tham gia event từ 23/1 - 17/3
*/

-- 2.4 Check null ở một số cột quan trọng:

SELECT
    SUM(CASE WHEN [user_id] IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN event_date IS NULL THEN 1 ELSE 0 END) AS null_event_date,
    SUM(CASE WHEN [platform] IS NULL THEN 1 ELSE 0 END) AS null_platform,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country,
    SUM(CASE WHEN app_version IS NULL THEN 1 ELSE 0 END) AS null_app_version
FROM install_logs;

SELECT
    SUM(CASE WHEN [user_id] IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN trans_user_id IS NULL THEN 1 ELSE 0 END) AS null_trans_user_id,
    SUM(CASE WHEN event_date IS NULL THEN 1 ELSE 0 END) AS null_event_date,
    SUM(CASE WHEN first_login_date IS NULL THEN 1 ELSE 0 END) AS null_first_login_date
FROM login_logs;

SELECT
    SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS null_user_id,
    SUM(CASE WHEN session_id IS NULL THEN 1 ELSE 0 END) AS null_session_id,
    SUM(CASE WHEN event_date IS NULL THEN 1 ELSE 0 END) AS null_event_date,
    SUM(CASE WHEN engagement_time_sec IS NULL THEN 1 ELSE 0 END) AS null_engagement_time_sec
FROM session_logs;

SELECT
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN trans_user_id IS NULL THEN 1 ELSE 0 END) AS null_trans_user_id,
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) AS null_transaction_date,
    SUM(CASE WHEN transaction_amount IS NULL THEN 1 ELSE 0 END) AS null_transaction_amount
FROM transaction_logs;

SELECT
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN trans_user_id IS NULL THEN 1 ELSE 0 END) AS null_trans_user_id,
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) AS null_transaction_date,
    SUM(CASE WHEN transaction_amount IS NULL THEN 1 ELSE 0 END) AS null_transaction_amount
FROM transaction_logs;

--=> Bảng install input thừa 1063 dòng dữ liệu null vào (các cột đều null)

-- 2.4 Check dup

-- bảng install: với mỗi user chỉ có duy nhất 1 install

SELECT [user_id],
	  COUNT(*) AS count_id
FROM install_logs
GROUP BY [user_id]
HAVING COUNT(*) >1 
--> xuất hiện dup do các dòng null input thừa

-- bảng login: trùng hoàn toàn, logic ko có userid nào login cùng lúc.
SELECT [user_id], trans_user_id,
		event_date,[login_type],
		app_version,first_login_date,
		COUNT(*) AS count_row
FROM  login_logs
GROUP BY [user_id], trans_user_id,
		event_date,[login_type],
		app_version,first_login_date
HAVING COUNT(*)> 1;


-- bảng session: một userid ko thể trùng session_id trong cùng 1 event_date
SELECT [user_id], event_date
	   [session_id],
	   COUNT(*) AS count_id
FROM session_logs
GROUP BY [user_id],[session_id], event_date
HAVING COUNT(*) >1 


-- bảng transaction: check trùng transaction_id
SELECT
    transaction_id,
    COUNT(*) AS cnt
FROM transaction_logs
GROUP BY transaction_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- bảng progression_logs : check trùng dòng ( trùng tất cả các cột)

SELECT
    [user_id],
    event_date,
    event_timestamp,
    event_name,
    [level],
    COUNT(*) AS cnt
FROM progression_logs
GROUP BY user_id, event_date, event_timestamp, event_name, [level]
HAVING COUNT(*) > 1
ORDER BY cnt DESC, [user_id] ;
 ---> ghi nhận dup 

--> dup dòng null bảng install, dup bảng progression_logs

--2.5 Kiểm tra giá trị outlier

-- bảng session
SELECT
    MIN(TRY_CONVERT(bigint, engagement_time_sec)) AS min_engagement,
    MAX(TRY_CONVERT(bigint, engagement_time_sec)) AS max_engagement,
    AVG(TRY_CONVERT(float, engagement_time_sec)) AS avg_engagement
FROM session_logs;

SELECT *
FROM session_logs
WHERE TRY_CONVERT(bigint, engagement_time_sec) < 0
   OR TRY_CONVERT(bigint, engagement_time_sec) > 86400; --số sec trong 24h

-- bảng transaction
SELECT
    MIN(TRY_CONVERT(decimal(18,2), transaction_amount)) AS min_amount,
    MAX(TRY_CONVERT(decimal(18,2), transaction_amount)) AS max_amount,
    AVG(TRY_CONVERT(float, transaction_amount)) AS avg_amount
FROM transaction_logs;

SELECT *
FROM transaction_logs
WHERE TRY_CONVERT(decimal(18,2), transaction_amount) <= 0;

-- bảng 
SELECT *
FROM progression_logs
WHERE TRY_CONVERT(int, level) <= 0;

--> logic giá trị ko âm, bảng session có giá trị engagement > 24h

-- 2.6 Kiểm tra  mapping 

-- check 1 user_id map với bn trans_user_id

SELECT [user_id],
	   COUNT(DISTINCT trans_user_id) AS count_trans
FROM login_logs
WHERE trans_user_id IS NOT NULL
GROUP BY [user_id]
HAVING COUNT(DISTINCT trans_user_id) > 1

-- check 1 trans_user_id map với bn user_id

SELECT trans_user_id,
	   COUNT(DISTINCT [user_id]) AS count_users
FROM login_logs
WHERE [user_id] IS NOT NULL
GROUP BY trans_user_id
HAVING COUNT(DISTINCT [user_id]) > 1

--> một users có thể có nhiều tài khoản trans_user_id ( nhiều lượt tải)
--> một trans_user_id có thể có nhiều users (đăng nhập nhiều tk trên 1 thiết bị)

-- Check logic về first_login date, ngày first login = ngày event_date sớm nhất
SELECT
    [user_id],
    MIN(TRY_CONVERT(date, event_date)) AS actual_first_login_date,
    MIN(TRY_CONVERT(date, first_login_date)) AS recorded_first_login_date
FROM login_logs
GROUP BY user_id
HAVING MIN(TRY_CONVERT(date, event_date)) <> MIN(TRY_CONVERT(date, first_login_date));

/* Tổng kết
- Bảng install input thừa dòng dữ liệu null vào (các cột đều null) => xóa
- Dup bảng progression_logs ( dup các dòng giống nhau) => bỏ dup
- session có giá trị engagement > 24h => flag
- user_id map nhiều trans_user_id và ngược lại 
*/

--- 2.7 Make a copy các bảng

DROP TABLE IF EXISTS install_backup;
SELECT * INTO install_backup FROM install_logs;

DROP TABLE IF EXISTS login_backup;
SELECT * INTO login_backup FROM login_logs;

DROP TABLE IF EXISTS session_backup;
SELECT * INTO session_backup FROM session_logs;

DROP TABLE IF EXISTS transaction_backup;
SELECT * INTO transaction_backup FROM transaction_logs;

DROP TABLE IF EXISTS progression_backup;
SELECT * INTO progression_backup FROM progression_logs;

----------------------------------------
-- B3: LÀM SẠCH DỮ LIỆU
----------------------------------------

-- Bảng install_logs

DROP TABLE IF EXISTS stg_install_logs;
SELECT
    CAST([user_id] AS NVARCHAR(50)) AS [user_id],
    TRY_CONVERT(date, event_date) AS event_date,
    CAST(app_version AS NVARCHAR(50)) AS app_version,
    CAST([platform] AS NVARCHAR(50)) AS [platform],
    CAST(device_brand AS NVARCHAR(100)) AS device_brand,
    CAST(device_model AS NVARCHAR(100)) AS device_model,
    CAST(country AS NVARCHAR(100)) AS country,
    CAST(os_version AS NVARCHAR(50)) AS os_version,
    CAST(network AS NVARCHAR(100)) AS network
INTO stg_install_logs
FROM install_backup
WHERE NOT (
    user_id IS NULL
    AND event_date IS NULL
    AND app_version IS NULL
    AND platform IS NULL
    AND device_brand IS NULL
    AND device_model IS NULL
    AND country IS NULL
    AND os_version IS NULL
    AND network IS NULL
);
SELECT * FROM stg_install_logs;

-- bảng login_logs

DROP TABLE IF EXISTS stg_login_logs;
SELECT
    CAST([user_id] AS NVARCHAR(50)) AS [user_id],
    CAST(TRY_CONVERT(BIGINT, trans_user_id) AS NVARCHAR(50)) AS trans_user_id,
    TRY_CONVERT(date, event_date) AS event_date,
    CAST([login_type] AS NVARCHAR(50)) AS login_type,
    CAST(app_version AS NVARCHAR(50)) AS app_version,
    TRY_CONVERT(date, first_login_date) AS first_login_date
INTO stg_login_logs
FROM login_backup;

SELECT * FROM stg_login_logs

-- bảng session_logs

DROP TABLE IF EXISTS stg_session_logs;
SELECT
    CAST([user_id] AS NVARCHAR(50)) AS [user_id],
    CAST([session_id] AS NVARCHAR(50)) AS [session_id],
    TRY_CONVERT(int, session_number) AS session_number,
    TRY_CONVERT(date, event_date) AS event_date,
    CAST(app_version AS NVARCHAR(50)) AS app_version,
    TRY_CONVERT(bigint, engagement_time_sec) AS engagement_time_sec,
    CASE 
        WHEN TRY_CONVERT(bigint, engagement_time_sec) IS NULL THEN 1
        WHEN TRY_CONVERT(bigint, engagement_time_sec) < 0 THEN 1
        WHEN TRY_CONVERT(bigint, engagement_time_sec) > 86400 THEN 1
        ELSE 0
    END AS is_invalid_engagement
INTO stg_session_logs
FROM session_logs
WHERE [user_id] IS NOT NULL;

SELECT * FROM stg_session_logs

-- bảng transaction_login

DROP TABLE IF EXISTS stg_transaction_logs;
SELECT
    TRY_CONVERT(date, transaction_date) AS transaction_date,
    CAST(transaction_id AS NVARCHAR(100)) AS transaction_id,
    CAST(TRY_CONVERT(BIGINT, trans_user_id) AS NVARCHAR(50)) AS trans_user_id,
    CAST(package_id AS NVARCHAR(100)) AS package_id,
    CAST(transaction_type AS NVARCHAR(50)) AS transaction_type,
    TRY_CONVERT(decimal(18,2), transaction_amount) AS transaction_amount
INTO stg_transaction_logs
FROM transaction_backup;
SELECT * FROM stg_transaction_logs

-- bảng progression_logs

DROP TABLE IF EXISTS stg_progression_logs;
WITH cte AS (
    SELECT
        CAST([user_id] AS NVARCHAR(50)) AS user_id,
        TRY_CONVERT(date, event_date) AS event_date,
        TRY_CONVERT(datetimeoffset, event_timestamp) AS event_timestamp_utc,
        DATEADD(HOUR, 7, CAST(TRY_CONVERT(datetimeoffset, event_timestamp) AS datetime2)) AS event_timestamp_gmt7,
        CAST(event_name AS NVARCHAR(100)) AS event_name,
        TRY_CONVERT(int, level) AS level,
        CAST(platform AS NVARCHAR(50)) AS platform,
        CAST(version AS NVARCHAR(50)) AS version,
        ROW_NUMBER() OVER (
            PARTITION BY 
                CAST(user_id AS NVARCHAR(50)),
                TRY_CONVERT(date, event_date),
                TRY_CONVERT(datetimeoffset, event_timestamp),
                CAST(event_name AS NVARCHAR(100)),
                TRY_CONVERT(int, level),
                CAST(platform AS NVARCHAR(50)),
                CAST(version AS NVARCHAR(50))
            ORDER BY (SELECT NULL)
        ) AS rn
    FROM progression_backup
)
SELECT
    [user_id],
    event_date,
    event_timestamp_utc,
    event_timestamp_gmt7,
    event_name,
    [level],
    [platform],
    [version]
INTO stg_progression_logs
FROM cte
WHERE rn = 1;

SELECT * FROM stg_progression_logs

----------------------------------------
-- B3: Tạo bảng tính toán
----------------------------------------

-----------------------------------
-- bảng bridge_user_account
-- map user_id với trans_user_id
-----------------------------------

DROP TABLE IF EXISTS bridge_user_account;

WITH mapping_base AS (
    SELECT DISTINCT
        l.[user_id],
        l.trans_user_id,
        MIN(l.first_login_date) OVER (PARTITION BY l.[user_id], l.trans_user_id) AS first_login_date,
        MIN(l.event_date) OVER (PARTITION BY l.[user_id], l.trans_user_id) AS first_seen_date,
        MAX(l.event_date) OVER (PARTITION BY l.[user_id], l.trans_user_id) AS last_seen_date
    FROM stg_login_logs l
    WHERE l.[user_id] IS NOT NULL
      AND l.trans_user_id IS NOT NULL
)
SELECT DISTINCT
    [user_id],
    trans_user_id,
    first_login_date,
    first_seen_date,
    last_seen_date
INTO bridge_user_account
FROM mapping_base;

SELECT  * FROM bridge_user_account

/*---------------------------------------
-- dim_users_infor
-- Thông tin của users
----------------------------------------*/
DROP TABLE IF EXISTS dim_users_info;
WITH install_ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY [user_id] ORDER BY event_date) AS rn
    FROM stg_install_logs
),
install AS (
    SELECT 
        [user_id],
        event_date AS install_date,
        app_version,
        [platform],
        device_brand,
        device_model,
        country,
        os_version,
        network
    FROM install_ranked
    WHERE rn = 1
),
first_login AS (
    SELECT 
        [user_id],
        MIN(first_login_date) AS first_login_date
    FROM stg_login_logs
    GROUP BY [user_id]
),
payer_users AS (
    SELECT DISTINCT l.[user_id]
    FROM stg_login_logs l
    INNER JOIN stg_transaction_logs t
        ON l.trans_user_id = t.trans_user_id
)
SELECT 
    i.[user_id],
    i.install_date,
    l.first_login_date,
    i.app_version,
    i.[platform],
    i.device_brand,
    i.device_model,
    i.country,
    i.os_version,
    i.network,
    CASE WHEN l.first_login_date IS NOT NULL THEN 1 ELSE 0 END AS is_logged_in,
    CASE WHEN p.[user_id]IS NOT NULL THEN 1 ELSE 0 END AS is_payer,
    CASE WHEN l.first_login_date >= i.install_date THEN DATEDIFF(day, i.install_date, l.first_login_date) ELSE NULL
    END AS days_to_first_login,
    DATEFROMPARTS(YEAR(i.install_date), MONTH(i.install_date), 1) AS install_month,
    DATEADD(day, 1 - DATEPART(weekday, i.install_date), i.install_date) AS install_week
INTO dim_users_info
FROM install i
LEFT JOIN first_login l
    ON i.[user_id] = l.[user_id]
LEFT JOIN payer_users p
    ON i.[user_id] = p.[user_id];

SELECT  * FROM dim_users_info

USE game_project;
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE '%dim_users%';
-----------------------------------
-- bảng fact_daily_metrics
-----------------------------------

DROP TABLE IF EXISTS fact_daily_metrics;
WITH active_users AS (
    SELECT 
        event_date,
        COUNT(DISTINCT [user_id]) AS daily_active_users
    FROM stg_session_logs
    GROUP BY event_date
),
new_users AS (
    SELECT 
        event_date,
        COUNT(DISTINCT [user_id]) AS new_users_install
    FROM stg_install_logs
    GROUP BY event_date
),
login_user AS(
	SELECT
		event_date,
		COUNT(DISTINCT [user_id]) AS daily_login_users
	FROM stg_login_logs
	GROUP BY event_date
),
revenue AS (
    SELECT 
        transaction_date AS event_date,
        SUM(transaction_amount) AS revenue,
        COUNT(DISTINCT trans_user_id) AS payers,
		COUNT(DISTINCT transaction_id) AS distinct_transactions
    FROM stg_transaction_logs
    GROUP BY transaction_date
)
SELECT 
    a.event_date,
    a.daily_active_users,
	l.daily_login_users,
    n.new_users_install,
    r.revenue,
    r.payers,
	r.distinct_transactions
INTO fact_daily_metrics
FROM active_users AS a
LEFT JOIN new_users AS n ON a.event_date = n.event_date
LEFT JOIN login_user AS l ON a.event_date = l.event_date
LEFT JOIN revenue AS r ON a.event_date = r.event_date
ORDER BY a.event_date

SELECT * FROM fact_daily_metrics;
-------------------------
--fact_daily_engagement
-------------------------
DROP TABLE IF EXISTS fact_daily_engagement;

WITH user_daily AS (
    SELECT
        user_id,
        event_date,
        COUNT([session_id]) AS session_count,
        SUM(CASE WHEN engagement_time_sec > 86400 THEN 0 ELSE engagement_time_sec END) AS playtime_sec,
        SUM(CASE WHEN engagement_time_sec > 86400 THEN 1 ELSE 0 END) AS invalid_session_count
    FROM stg_session_logs
	WHERE [user_id] IS NOT NULL
	AND event_date IS NOT NULL
    GROUP BY user_id, event_date
),
daily_agg AS (
    SELECT
        event_date,
        COUNT(DISTINCT user_id) AS daily_active_users,
        SUM(session_count) AS num_sessions,
        SUM(playtime_sec) AS total_playtime_sec,
        AVG(session_count * 1.0) AS avg_session_per_user,
        AVG(playtime_sec * 1.0) AS avg_playtime_per_user,
        SUM(invalid_session_count) AS invalid_session_count
    FROM user_daily
    GROUP BY event_date
)
SELECT
    event_date,
    daily_active_users,
    num_sessions,
    total_playtime_sec,
    avg_session_per_user,
    avg_playtime_per_user,
    invalid_session_count,
    num_sessions * 1.0 / NULLIF(daily_active_users, 0) AS sessions_per_dau,
    total_playtime_sec * 1.0 / NULLIF(daily_active_users, 0) AS playtime_per_dau,
    total_playtime_sec * 1.0 / NULLIF(num_sessions, 0) AS avg_session_length_sec
INTO fact_daily_engagement
FROM daily_agg;

SELECT * FROM fact_daily_engagement

---------------------------------------------
---funnel
-- lấy các user đã install->login->play-> pay
---------------------------------------------

-- check user pay nhưng không login?
SELECT DISTINCT t.trans_user_id
FROM stg_transaction_logs t
LEFT JOIN stg_login_logs l 
    ON t.trans_user_id = l.trans_user_id
WHERE l.trans_user_id IS NULL
--> ko có user nào pay mà ko login

-- users install
DROP TABLE IF EXISTS fact_funnel;

WITH install_users AS (
    SELECT DISTINCT 
        [user_id],
        event_date AS install_date
    FROM stg_install_logs
),

-- users login
login_users AS (
    SELECT DISTINCT [user_id]
    FROM stg_login_logs
),

-- users play
player_users AS (
    SELECT DISTINCT s.[user_id]
    FROM stg_session_logs s
    JOIN stg_install_logs i
        ON s.user_id = i.user_id
    WHERE s.event_date >= i.event_date
),

-- user pay + login
payer_users AS (
    SELECT DISTINCT l.[user_id]
    FROM stg_login_logs l
    JOIN stg_transaction_logs t 
        ON l.trans_user_id = t.trans_user_id
)
SELECT 
    i.install_date,   
    COUNT(*) AS installs,   
    SUM(CASE WHEN l.[user_id] IS NOT NULL THEN 1 ELSE 0 END) AS login_users,
    SUM(CASE WHEN p.[user_id] IS NOT NULL THEN 1 ELSE 0 END) AS players,
    SUM(CASE WHEN pay.[user_id] IS NOT NULL THEN 1 ELSE 0 END) AS payers
INTO fact_funnel
FROM install_users AS i
LEFT JOIN login_users l ON i.[user_id] = l.[user_id]
LEFT JOIN player_users p ON i.[user_id] = p.[user_id]
LEFT JOIN payer_users pay ON i.[user_id] = pay.[user_id]
GROUP BY i.install_date
ORDER BY i.install_date;

SELECT * FROM fact_funnel;

-------------------------
--- cohort week
-------------------------

DROP TABLE IF EXISTS fact_cohort_retention;

WITH first_install AS (
    SELECT 
        user_id,
        MIN(CAST(event_date AS DATE)) AS install_date
    FROM stg_install_logs
    GROUP BY user_id
),

activity AS (
    SELECT DISTINCT
        user_id,
        CAST(event_date AS DATE) AS activity_date
    FROM stg_session_logs
),

cohort AS (
    SELECT 
        f.user_id,
        f.install_date,
        a.activity_date,
        DATEDIFF(WEEK, f.install_date, a.activity_date) AS cohort_week
    FROM first_install AS f
    INNER JOIN activity AS a 
        ON f.user_id = a.user_id
       AND a.activity_date >= f.install_date
)

SELECT 
    install_date,
    cohort_week,
    COUNT(DISTINCT user_id) AS users
INTO fact_cohort_retention
FROM cohort
GROUP BY install_date, cohort_week
ORDER BY install_date, cohort_week;

SELECT * FROM fact_cohort_retention;

-------------------------
---fact_daily_transaction
-------------------------
DROP TABLE IF EXISTS fact_daily_transaction;
SELECT
    CAST(t.transaction_date AS DATE) AS transaction_date,
    t.transaction_id,
    t.trans_user_id,
    b.[user_id],
    t.package_id,
    t.transaction_type,
    t.transaction_amount
INTO fact_daily_transaction
FROM transaction_logs t
left join bridge_user_account AS b
    ON t.trans_user_id = b.trans_user_id;

SELECT * FROM fact_daily_transaction;

SELECT *
FROM fact_daily_metrics
WHERE event_date IS NULL;