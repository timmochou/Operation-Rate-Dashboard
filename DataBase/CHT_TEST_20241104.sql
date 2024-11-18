-- T1 查詢兩張圖表會用到的欄位
WITH T1 AS (
    SELECT 
        --目前只挑有用到欄位
        T.ID,
        T.EQPID,
        T.STIME,
        T.ETIME,
        T.OPSTATUS,
        T.DURATION,
        T.isDel,
        --將STIME 以及 ETIME 的HHMMSS substring 出來以利後續CTE(T2)用來轉換成秒數形式
        CAST(SUBSTRING(T.STIME, 9, 2) + SUBSTRING(T.STIME, 11, 2) + SUBSTRING(T.STIME, 13, 2) AS VARCHAR) AS STIME1,
        CAST(SUBSTRING(T.ETIME, 9, 2) + SUBSTRING(T.ETIME, 11, 2) + SUBSTRING(T.ETIME, 13, 2) AS VARCHAR) AS ETIME1
    FROM dbo.TMESEQPRUNTIME T
    --查詢isDel 不等於false
    WHERE isDel = 'false'
    --查詢日期參數當日的資料
    AND SUBSTRING(STIME, 1, 4) + '-' + SUBSTRING(STIME, 5, 2) + '-' + SUBSTRING(STIME, 7, 2) = '2024-10-01'
), 
--T2 是用於將HHMMSS格式轉換成秒數格式，以利於堆積圖判斷時間軸順序
T2 AS (
    SELECT  
        ID, EQPID, STIME, ETIME, OPSTATUS, DURATION, isDel,
        --將HHMMSS格式，轉換成秒數格式
        SUBSTRING(STIME1,1,2)*60*60 + SUBSTRING(STIME1,3,2)*60 + SUBSTRING(STIME1,5,2) AS STIME_SEC,
        SUBSTRING(ETIME1,1,2)*60*60 + SUBSTRING(ETIME1,3,2)*60 + SUBSTRING(ETIME1,5,2) AS ETIME_SEC,
        --STIME字串轉換成日期格式
        CAST(SUBSTRING(STIME, 1, 4) + '-' + SUBSTRING(STIME, 5, 2) + '-' + SUBSTRING(STIME, 7, 2) + ' ' + 
             SUBSTRING(STIME, 9, 2) + ':' + SUBSTRING(STIME, 11, 2) + ':' + SUBSTRING(STIME, 13, 2) AS DATETIME) AS STARTTime,
        --ETIME字串轉換成日期格式
        CAST(SUBSTRING(ETIME, 1, 4) + '-' + SUBSTRING(ETIME, 5, 2) + '-' + SUBSTRING(ETIME, 7, 2) + ' ' + 
             SUBSTRING(ETIME, 9, 2) + ':' + SUBSTRING(ETIME, 11, 2) + ':' + SUBSTRING(ETIME, 13, 2) AS DATETIME) AS ENDTime
    FROM T1
),
-- 列出下一筆的starttime，此時最後一個NEXT_STARTTime為空，後續CTE(T4)會加以處理
T3 AS (
    SELECT 
        T2.*,
        LEAD(STIME_SEC) OVER (ORDER BY STIME_SEC) AS NEXT_STIME_SEC,
        LEAD(STIME) OVER (ORDER BY STIME) AS NEXT_STIME,
        LEAD(STARTTime) OVER (ORDER BY STARTTime) AS NEXT_STARTTime
    FROM T2
),
--CTE(T4):用於填補設備狀態紀錄之間的空白時間，將其標記為停機時間
T4 AS (
    SELECT 
        T3.ID, T3.EQPID,
        --將E
        T3.ETIME AS STIME,
        -- 來補滿兩筆資料結束時間以及下一筆的開始時間，若>0則將NEXT_STIME 為ETIME
        CASE 
            WHEN DATEDIFF(SECOND, T3.ENDTime, T3.NEXT_STARTTime) > 0 THEN 
            T3.NEXT_STIME    
            ELSE NULL 
        END AS ETIME,
        '03' AS OPSTATUS,
        T3.isDel,
        T3.ETIME_SEC AS STIME_SEC,
        T3.NEXT_STIME_SEC AS ETIME_SEC,
        T3.ENDTime AS STARTTime,
        CASE 
            WHEN DATEDIFF(SECOND, T3.ENDTime, T3.NEXT_STARTTime) > 0 THEN 
                DATEADD(SECOND, DATEDIFF(SECOND, T3.ENDTime, T3.NEXT_STARTTime), T3.ENDTime)
            ELSE NULL 
        END AS ENDTime
    FROM T3
), 
-- CTE(T5) 整理T4的欄位，後續T6與T2(原始數據）UNION
T5 AS (
    SELECT 
        -- 為每一行分配一個唯一的ID，從13開始
        (SELECT MAX(ID) FROM T2) + ROW_NUMBER() OVER (ORDER BY T4.STIME) AS ID,  
        T4.EQPID,
        T4.STIME, 
        -- 如果ETIME不為空，則使用ETIME，否則使用STIME的前8位加上'200000'（表示當天20:00:00）
        CASE WHEN T4.ETIME != '' THEN T4.ETIME
        ELSE LEFT(T4.STIME,8)+'200000' 
        END AS ETIME,
        T4.OPSTATUS, 
        -- 計算持續時間：如果ENDTime不為空，計算實際持續時間；否則計算到當天20:00:00的時間
        CASE WHEN T4.ENDTime != '' THEN DATEDIFF(SECOND,T4.STARTTime,T4.ENDTime) 
        ELSE 72000 - T4.STIME_SEC  -- 72000秒 = 20小時，減去開始時間的秒數
        END AS DURATION,
        T4.isDel,
        T4.STIME_SEC,
        -- 如果ETIME不為空，使用ETIME_SEC；否則使用72000（晚上8點的秒數）
        CASE WHEN T4.ETIME != '' THEN T4.ETIME_SEC
            ELSE 72000
            END AS ETIME_SEC,
        T4.STARTTime, 
        -- 如果ENDTime不為空，使用ENDTime；否則設置為當天的20:00:00
        CASE WHEN T4.ENDTime != '' THEN T4.ENDTime
        ELSE CAST(SUBSTRING(T4.STIME, 1, 4) + '-' + SUBSTRING(T4.STIME, 5, 2) + '-' + SUBSTRING(T4.STIME, 7, 2) + ' ' + 
            '20' + ':' + '00' + ':' + '00' AS DATETIME) END AS ENDTime
    FROM T4
)
SELECT * FROM T2
UNION ALL 
SELECT * FROM T5