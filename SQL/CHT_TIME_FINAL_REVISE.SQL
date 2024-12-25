WITH T0 AS (
    --選擇用到欄位(ID,OPSTATUS,EQPID,STIME,ETIME,DURATION)
    SELECT 
    --轉換ID為字串，以利後續與ID-GAP做結合
       CAST(T.ID AS VARCHAR) AS ID,
        T.EQPID,
        --OPSTATUS 為設備狀態
        T.OPSTATUS,
         -- 這邊加1也是因為 假資料的Duration加起來會比實際結束時間少一秒，所以做處理，若正式環境沒有此問題可以把+1 刪除
        T.DURATION + 1 AS DURATION,
        T.isDel,
        --STIME 為開始時間，形態為字串且格式為YYYYMMDDHHMMSS，轉換成日期格式 取名為STARTTime
        CAST(SUBSTRING(STIME, 1, 4) + '-' + 
             SUBSTRING(STIME, 5, 2) + '-' + 
             SUBSTRING(STIME, 7, 2) + ' ' + 
             SUBSTRING(STIME, 9, 2) + ':' + 
             SUBSTRING(STIME, 11, 2) + ':' + 
             SUBSTRING(STIME, 13, 2) AS DATETIME) AS STARTTIME,
        -- 處理結束時間(ETIME)的邏輯：
        -- 1. 當ETIME為NULL時：使用 開始時間(STARTTIME) + 持續時間(DURATION) 計算
        -- 2. 當ETIME有值時：直接使用ETIME
        -- 注意：目前使用 ETIME = 'NULL' 是因為測試資料從CSV匯入後，NULL值被轉為字串'NULL'
        -- TODO: 在正式環境中應改為使用 IS NULL 判斷
        CASE WHEN T.ETIME = 'NULL' 
        THEN 
        --使用DATEADD函數計算結束時間
        --註：在測試環境中，由於模擬數據的特性，Duration總和比實際結束時間少1秒，
        --TODO: 因此需要加1進行修正。正式環境如無此問題可移除"+1"
        DATEADD(SECOND,DURATION + 1,CAST(SUBSTRING(STIME, 1, 4) + '-' + SUBSTRING(STIME, 5, 2) + '-' + SUBSTRING(STIME, 7, 2) + ' ' + 
             SUBSTRING(STIME, 9, 2) + ':' + SUBSTRING(STIME, 11, 2) + ':' + SUBSTRING(STIME, 13, 2) AS DATETIME))
        ELSE
        CAST(SUBSTRING(ETIME, 1, 4) + '-' + SUBSTRING(ETIME, 5, 2) + '-' + SUBSTRING(ETIME, 7, 2) + ' ' + 
             SUBSTRING(ETIME, 9, 2) + ':' + SUBSTRING(ETIME, 11, 2) + ':' + SUBSTRING(ETIME, 13, 2) AS DATETIME) 
        END AS ENDTime
    FROM 
    -- 選擇資料表
        dbo.TMESEQPRUNTIME1 T
    WHERE 
    --查詢isDel 不等於TRUE
        isDel = '0'
    -- 取設備編號為3的資料
        AND EQPID = '3'
    --查詢日期參數當日的資料（STIME 格式為 YYYYMMDDHHMMSS 要轉換成 YYYY-MM-DD 格式，才會與P_DATE 格式一致）
        AND SUBSTRING(STIME, 1, 4) + '-' + 
            SUBSTRING(STIME, 5, 2) + '-' + 
            SUBSTRING(STIME, 7, 2) = '${P_DATE}'
),
-- CTE(T1): 找出下一筆開始時間
T1 AS (
    SELECT 
        T0.*,
        -- 使用 STARTTime 排序以確保 LEAD 函數能正確獲取時間序列中的下一筆開始時間
        LEAD(STARTTime) OVER(ORDER BY STARTTime) AS NEXT_STARTTime
    FROM 
        T0
)
--CTE(T2): 處理設備狀態記錄之間的時間間隔
--目的：填補設備狀態記錄之間的空白時間
--    1. 將間隔時間視為停機狀態(OPSTATUS = 0)
--    2. 用於確保時間序列的連續性
,T2 AS (
    SELECT 
        -- 將ID加上'gap'後綴作為停機時間區間的唯一標識符
        CAST(ID AS VARCHAR) + 'gap' AS ID, 
        EQPID,
        -- 將間隔時間視為停機狀態(OPSTATUS = 0)
        '0' AS OPSTATUS,
        -- 計算停機時間的秒數
        DATEDIFF(SECOND,ENDTime,NEXT_STARTTime) AS DURATION,
        isDel,
        -- 有GAP的資料，ENDTime 為停機時間的開始時間，NEXT_STARTTime為停機時間的結束時間
        ENDTime AS STARTTime,
        NEXT_STARTTime AS ENDTime
    FROM 
        T1
    -- 找出中間有GAP的資料，即兩筆記錄間的時間差大於0秒
    -- 通過比較 ENDTime 與 NEXT_STARTTime 的時間差來識別時間間隔
    WHERE 
    DATEDIFF(SECOND, ENDTime, NEXT_STARTTime) > 0
)
-- CTE(T3): 將正常資料與有GAP的資料合併
, T3 AS(
    SELECT * FROM T0
    UNION ALL 
    SELECT * FROM T2
)
-- CTE(TB1): 計算稼動、等待、異常 狀態的總時間
,TB1 AS(
    SELECT 
        -- 計算稼動、等待、異常 狀態的總時間
        SUM(CASE WHEN OPSTATUS = '1' THEN Duration ELSE 0 END) AS OperationTime, -- 稼動總時間
        SUM(CASE WHEN OPSTATUS = '2' THEN Duration ELSE 0 END) AS WaitingTime, -- 等待總時間
        SUM(CASE WHEN OPSTATUS = '3' THEN Duration ELSE 0 END) AS Downtime -- 異常總時間
    FROM 
        T3
) 
-- CTE(TB2): 計算稼動率（稼動率 = (稼動時間 + 等待時間) / (稼動時間 + 等待時間 + 異常時間)）
,TB2 AS(
    SELECT 
   --使用 NULLIF 防止除數為零，並使用 ROUND 函數取至小數點後2位
        ROUND((OperationTime + WaitingTime) * 1.0 / NULLIF((OperationTime + WaitingTime + Downtime), 0), 2) AS Availability
    FROM 
        TB1
)

,TB4(ID,EQPID,OPSTATUS,DURATION,isDel,STARTTime,ENDTime,REMARK1,EQUIP,EQUIPNAME,OPSTATUS1,Availability) 
AS (
    --插入預設記錄用於圓餅圖展示
    --目的：確保圖表顯示固定順序的設備狀態
    SELECT NULL,'3','1',0,NULL,NULL,NULL,N'運轉',NULL,NULL,NULL,TB2.Availability
    FROM TB2
    UNION ALL
    SELECT NULL,'3','2',0,NULL,NULL,NULL,N'等待',NULL,NULL,NULL,TB2.Availability
    FROM TB2
    UNION ALL
    SELECT NULL,'3','3',0,NULL,NULL,NULL,N'異常',NULL,NULL,NULL,TB2.Availability
    FROM TB2
    UNION ALL
    SELECT NULL,'3','0',0,NULL,NULL,NULL,N'未開機',NULL,NULL,NULL,TB2.Availability
    FROM TB2
    UNION ALL
    SELECT NULL,'3','-1',0,NULL,NULL,NULL,N'未定義',NULL,NULL,NULL,TB2.Availability
    FROM TB2
)
-- 合併所有資料：
-- 1. 包含圓餅圖的預設記錄（來自 TB4）
-- 2. 包含實際設備運行記錄（來自 T3）
-- 3. 關聯設備和代碼表獲取額外資訊
SELECT * FROM TB4
UNION ALL 
SELECT 
    T3.*, 
    T4.REMARK1, 
    T5.EQUIP, 
    T5.EQUIPNAME, 
    -- 為解決條形圖系列自動合併的問題，將 OPSTATUS 與 ID 組合作為獨立系列。
    -- 1. 確保依時間順序正確顯示每個狀態
    -- 2. 保持相同狀態使用相同顏色
    -- 3. 避免相同狀態被合併顯示
    T3.OPSTATUS + '-' + ID AS OPSTATUS1 ,
    TB2.Availability
FROM T3
LEFT JOIN TMIMDCDE T4 ON T3.OPSTATUS = T4.CODE 
LEFT JOIN TMIMEQUIP T5 ON T3.[EQPID] = T5.ASSETNO
-- TB2 的稼動率 直接帶入每一筆資料當中
,TB2
ORDER BY STARTTime ASC