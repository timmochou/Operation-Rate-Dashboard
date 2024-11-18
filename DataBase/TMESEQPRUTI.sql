CREATE TABLE TMESEQPRUNTI (
 ID INT IDENTITY(1,1) NOT NULL, -- 自增主鍵(作為唯一標識)
 DEPT CHAR(1) NOT NULL,
 LINEID VARCHAR(20) NOT NULL,
 STATIONID NVARCHAR(20) NOT NULL, -- 站別
 EQPID NVARCHAR(20) NOT NULL,
 STIME CHAR(14) NOT NULL,
-- 設備 ID -- 稼動開始時間
 ETIME CHAR(14) NULL,
-- 稼動結束時間 (可以為 NULL 表示設備還在運行)
-- 自增主鍵(作為唯一標識) -- 事業處代號
-- 產線 ID，對應產線主檔 TMIMLINE 的 LINE 欄位

 MSTATUS NVARCHAR(10) NULL,
 OPSTATUS NVARCHAR(10) NOT NULL, -- 轉換後的狀態 (對應業務邏輯的狀態，例如運行中、維護等)
 Duration INT NOT NULL, -- 狀態持續時間，單位:秒
 Memo NVARCHAR(50) NULL, -- 備註

 MODU NVARCHAR(20) NOT NULL DEFAULT '', -- 資料維護人員
 MDATE CHAR(14) DEFAULT
FORMAT(GETDATE(), 'yyyyMMddHHmmss'), -- 記錄更新時間

 CREATEAT CHAR(14) DEFAULT
 FORMAT(GETDATE(), 'yyyyMMddHHmmss'), -- 記錄建立時間
 isDel Bit DEFAULT 0 -- 紀錄是否已被刪除

-- 設定複合主鍵
 PRIMARY KEY (DEPT, EQPID, STIME)
 );

 -- 創建索引，將 isDel(倒序), EQPID、STIME (倒序)、ETIME (倒序) 設為索引
 CREATE INDEX IDX_EQPID_STIME_ETIME_Desc
 ON TMESEQPRUNTIME (DEPT, LINEID, isDel DESC, EQPID, STIME DESC, ETIME DESC);



 -- 為每個欄位添加描述(Description) 35
 -- ID 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'自增主鍵(唯一標識符)',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'ID';
-- 原始狀態，燈號組合的狀態或原始設備狀態代碼

 -- DEPT 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'事業處代碼',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'DEPT';

 -- LINEID 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'產線 ID，對應產線主檔 TMIMLINE.LINE',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'LINEID';

 -- STATIONID 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'站別',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'STATIONID';

 -- EQPID 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'設備 ID，請對應設備主檔',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'EQPID';

 -- STIME 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'稼動開始時間，格式為 yyyyMMddHHmmss',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'STIME';

 -- ETIME 欄位描述
 EXEC sp_addextendedproperty
  @name = N'MS_Description',
 @value = N'稼動結束時間，格式為 yyyyMMddHHmmss，NULL 表示設備仍在運行',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'ETIME';

 -- ORGSTATUS 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'原始狀態，燈號組合的狀態或原始設備狀態代碼',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'MSTATUS';

 -- OPSTATUS 欄位描述
 
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'顯示的狀態，對應紅黃綠三種狀態',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'OPSTATUS';

 -- Duration 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'狀態持續時間，單位:秒',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'Duration';

 -- Memo 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'備註欄位，可記錄其他補充信息',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'Memo';

 -- MODU 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'資料維護人員',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'MODU';

 -- MDATE 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'記錄建立時間，格式為 yyyyMMddHHmmss',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'MDATE';

 -- UDATE 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'記錄更新時間，格式為 yyyyMMddHHmmss',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'CREATEAT';

 -- isDel 欄位描述
 EXEC sp_addextendedproperty
 @name = N'MS_Description',
 @value = N'紀錄是否已被刪除 (1=被刪除)',
 @level0type = N'SCHEMA', @level0name = 'dbo',
 @level1type = N'TABLE', @level1name = 'TMESEQPRUNTIME',
 @level2type = N'COLUMN', @level2name = 'isDel';