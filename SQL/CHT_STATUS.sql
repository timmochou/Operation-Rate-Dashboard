WITH TB1 AS (
    SELECT 
    -- 計算稼動、等待、異常 狀態的總時間
        SUM(CASE WHEN REMARK1 = N'稼動' THEN Duration ELSE 0 END) AS OperationTime,
        SUM(CASE WHEN REMARK1 = N'等待' THEN Duration ELSE 0 END) AS WaitingTime,
        SUM(CASE WHEN REMARK1 = N'異常' THEN Duration ELSE 0 END) AS Downtime
    FROM [dbo].[TMESEQPRUNTIME] T1 
    LEFT JOIN [dbo].[TMIMDCDE] T2 
        ON T1.[OPSTATUS] = REVERSE(T2.[CODE])
    LEFT JOIN [dbo].[TMIMEQUIP] T3
        ON T1.[EQPID] = T3.[ASSETNO]
    WHERE isDel = 'false'
    AND SUBSTRING(STIME, 1, 4) + '-' + SUBSTRING(STIME, 5, 2) + '-' + SUBSTRING(STIME, 7, 2) = '${P_DATE}'
),TB2 AS(
    -- 計算稼動率
SELECT 
    (OperationTime + WaitingTime) * 1.0 / NULLIF((OperationTime + WaitingTime + Downtime), 0) AS Availability
FROM TB1),TB3 AS (
SELECT 
    -- 根據不同狀態，計算總時間以及佔比
    SUM(T1.Duration) AS Total_duration,
    SUM(T1.Duration) * 1.0 / SUM(SUM(T1.Duration)) OVER () AS DurationPercentage,
    REMARK1
FROM [dbo].[TMESEQPRUNTIME] T1
LEFT JOIN [dbo].[TMIMDCDE] T2 
    ON T1.[OPSTATUS] = REVERSE(T2.[CODE])
LEFT JOIN [dbo].[TMIMEQUIP] T3
    ON T1.[EQPID] = T3.[ASSETNO]
WHERE 
    isDel = 'false'
    AND SUBSTRING(STIME, 1, 4) + '-' + SUBSTRING(STIME, 5, 2) + '-' + SUBSTRING(STIME, 7, 2) = '${P_DATE}'
GROUP BY REMARK1)
SELECT * FROM TB3,TB2