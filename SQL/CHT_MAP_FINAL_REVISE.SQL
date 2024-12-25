SELECT 
    --目前只挑有用到欄位
    T0.ID,
    T0.EQPID,
    T0.STIME,
    T0.OPSTATUS,
    T1.REMARK1,
    T2.EQUIPNAME
FROM 
    dbo.TMESEQPRUNTIME1 T0
    LEFT JOIN TMIMDCDE T1 ON T0.OPSTATUS = T1.CODE 
    LEFT JOIN TMIMEQUIP T2 ON T0.EQPID = T2.ASSETNO 
--查詢isDel 不等於false
WHERE 
    isDel = '0'
    AND EQPID IN ('1', '3')
--查詢日期參數當日的資料
    AND SUBSTRING(STIME, 1, 4) + '-' + 
        SUBSTRING(STIME, 5, 2) + '-' + 
        SUBSTRING(STIME, 7, 2) = '${P_DATE}'
    AND STIME IN (
        -- 根據不同的EQPID 查詢每個設備的最新資料
        SELECT MAX(STIME)
        FROM dbo.TMESEQPRUNTIME1
        GROUP BY EQPID
    )