USE [DMES_TEST]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetEQPRuntimeGanttChart]    Script Date: 2024/10/24 下午 10:16:18 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[sp_GetEQPRuntimeGanttChart]
    @EQPID VARCHAR(50),    -- 設備ID
    @P_DATE CHAR(8)        -- 指定日期, 需與 帆軟報表 PMFR5018.fvs 的範本參數名稱相同
AS 
BEGIN
    SET NOCOUNT ON;

    -- 宣告變數
    DECLARE @curSTIME char(6), 
            @curETIME char(6), 
            @curDuration INT, 
            @curStatus varchar(5), 
            @id INT;

    -- 定義時間常數
    DECLARE @DayStart char(6)    = '080000';  -- 當日早上8點
    DECLARE @BreakStart1 char(6) = '100000';  -- 上午休息 10:00 開始
    DECLARE @BreakEnd1 char(6)   = '100500';  -- 上午休息 10:05 結束
    DECLARE @BreakStart2 char(6) = '120000';  -- 中午休息 12:00 開始
    DECLARE @BreakEnd2 char(6)   = '125000';  -- 中午休息 12:50 結束
    DECLARE @BreakStart3 char(6) = '150000';  -- 下午休息 15:00 開始
    DECLARE @BreakEnd3 char(6)   = '150500';  -- 下午休息 15:05 結束
    DECLARE @BreakStart4 char(6) = '170000';  -- 加班休息 17:00 開始
    DECLARE @BreakEnd4 char(6)   = '173000';  -- 加班休息 17:30 結束
    DECLARE @BreakStatus varchar(5) = '0';    -- 休息時間的 OPStatus

    -- 暫存表格存儲結果
    DECLARE @tmpRuntime TABLE (
        STIME char(6),
        ETIME char(6),
        DURATION INT,
        OPStatus varchar(5),
        id INT
    );
    
    DECLARE @cnt int = 0;
    -- 游標查詢，篩選出當日8點以後的紀錄 (ETIME >= 08:00) 並按時間排序
    DECLARE EQPCursor CURSOR FOR
        SELECT
            RIGHT(STIME,6),
            CASE
                WHEN ETIME IS NULL THEN dbo.fn_SubSecFromChar6Time(RIGHT(STIME,6), DURATION * -1)
                ELSE RIGHT(ETIME, 6)
            END,
            DURATION, 
            OPSTATUS,
            ID
        from TMESEQPRUNTIME
        WHERE EQPID = @EQPID
            AND LEFT(STIME,8) = @P_DATE
            AND ISNULL(RIGHT(ETIME,6),dbo.fn_SubSecFromChar6Time(RIGHT(STIME,6), DURATION * -1) ) >  @DayStart
            AND NOT ( STIME >= @P_DATE + @BreakStart1 and ISNULL(ETIME,'99999999999999') <= @P_DATE + @BreakEnd1) -- 排除整段紀錄時間在 上午休息 之間的紀錄
            AND NOT ( STIME >= @P_DATE + @BreakStart2 and ISNULL(ETIME,'99999999999999') <= @P_DATE + @BreakEnd2) -- 排除整段紀錄時間在 中午休息 之間的紀錄
            AND NOT ( STIME >= @P_DATE + @BreakStart3 and ISNULL(ETIME,'99999999999999') <= @P_DATE + @BreakEnd3) -- 排除整段紀錄時間在 下午休息 之間的紀錄
            AND NOT ( STIME >= @P_DATE + @BreakStart4 and ISNULL(ETIME,'99999999999999') <= @P_DATE + @BreakEnd4) -- 排除整段紀錄時間在 加班休息 之間的紀錄

            ORDER BY STIME;
    -- 開啟游標
    OPEN EQPCursor;
    FETCH NEXT FROM EQPCursor INTO @curSTIME, @curETIME, @curDuration, @curStatus, @id;

    WHILE @@FETCH_STATUS = 0

    BEGIN

 

        SET @cnt = @cnt+1;

        Print '======================================================================';
        Print concat('處裡紀錄 ',@cnt, ' : ', @curSTIME,',', @curETIME,',',@curDuration,',', @curStatus,',', @id);

 

        -- 1. 調整橫跨 08:00 點的紀錄

        IF @curSTIME < @DayStart AND @curETIME > @DayStart

        BEGIN
            -- 調整開始時間為 8 點，並更新 duration                               
            SET @curDuration = dbo.fn_Char6TimeDiffInSec(@curETIME, @DayStart);
            SET @curSTIME = @DayStart;
        END

 
        IF @curSTIME < @BreakEnd1

        BEGIN
            IF @curETIME <= @BreakStart1
            BEGIN
                INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                VALUES (@curSTIME, @curETIME, @curDuration, @curStatus, @id);

 
                SET @curSTIME = @BreakStart1;
                SET @curDuration = dbo.fn_Char6TimeDiffInSec( @curETIME, @curSTIME);
            END
            else -- @curETIME > @BreakStart1
            BEGIN
                -- 插入休息前的紀錄
                INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                VALUES (@curSTIME, @BreakStart1, dbo.fn_Char6TimeDiffInSec(@BreakStart1,@curSTIME), @curStatus, @id);

 

                                           -- 插入休息的紀錄
                INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                VALUES (@BreakStart1, @BreakEnd1, dbo.fn_Char6TimeDiffInSec(@BreakEnd1,@BreakStart1), @BreakStatus, @id);

 

                                           SET @curSTIME = @BreakEnd1;
                SET @curDuration = dbo.fn_Char6TimeDiffInSec(@curETIME,@curSTIME)
            END
        END
        IF @curSTIME < @BreakEnd2 and @curDuration > 0
                     BEGIN
            IF @curETIME <= @BreakStart2
            BEGIN
                INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                VALUES (@curSTIME, @curETIME, @curDuration, @curStatus, @id);

                SET @curSTIME = @BreakStart2;
                SET @curDuration = dbo.fn_Char6TimeDiffInSec( @curETIME, @curSTIME);
            END
            else -- @curETIME > @BreakStart2
            BEGIN
                -- 插入 @curSTIME 到休息開始的紀錄
                INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                VALUES (@curSTIME, @BreakStart2, dbo.fn_Char6TimeDiffInSec(@BreakStart2,@curSTIME), @curStatus, @id);

 

                                           -- 插入休息的紀錄
                INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                VALUES (@BreakStart2, @BreakEnd2, dbo.fn_Char6TimeDiffInSec(@BreakEnd2,@BreakStart2), @BreakStatus, @id);

 
                SET @curSTIME = @BreakEnd2;
                SET @curDuration = dbo.fn_Char6TimeDiffInSec(@curETIME,@curSTIME)
            END
        END

 

                   
        IF @curSTIME < @BreakEnd3 and @curDuration > 0
        BEGIN
            IF @curETIME <= @BreakStart3
            BEGIN
                INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                VALUES (@curSTIME, @curETIME, @curDuration, @curStatus, @id);

 
                SET @curSTIME = @BreakStart3;
                SET @curDuration = dbo.fn_Char6TimeDiffInSec( @curETIME, @curSTIME);
            END
            else -- @curETIME > @BreakStart3
            BEGIN
                -- 插入 @curSTIME 到休息開始的紀錄
                INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                VALUES (@curSTIME, @BreakStart3, dbo.fn_Char6TimeDiffInSec(@BreakStart3,@curSTIME), @curStatus, @id);

 
                -- 插入休息的紀錄
                INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                VALUES (@BreakStart3, @BreakEnd3, dbo.fn_Char6TimeDiffInSec(@BreakEnd3,@BreakStart3), @BreakStatus, @id);

 
                SET @curSTIME = @BreakEnd3;
                SET @curDuration = dbo.fn_Char6TimeDiffInSec(@curETIME,@curSTIME)
            END
        END

 

                   

                     IF @curSTIME < @BreakEnd4 and @curDuration > 0

                     BEGIN
            IF @curETIME <= @BreakStart4
            BEGIN

                                           INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)

                                           VALUES (@curSTIME, @curETIME, @curDuration, @curStatus, @id);

 

                                           SET @curSTIME = @BreakStart4;

                                           SET @curDuration = dbo.fn_Char6TimeDiffInSec( @curETIME, @curSTIME);
            END
            else -- @curETIME > @BreakStartr
                BEGIN
                    -- 插入 @curSTIME 到休息開始的紀錄
                    INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                    VALUES (@curSTIME, @BreakStart4, dbo.fn_Char6TimeDiffInSec(@BreakStart4,@curSTIME), @curStatus, @id);

 
                    -- 插入休息的紀錄
                    INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                    VALUES (@BreakStart4, @BreakEnd4, dbo.fn_Char6TimeDiffInSec(@BreakEnd4,@BreakStart4), @BreakStatus, @id);

 
                    SET @curSTIME = @BreakEnd4;
                    SET @curDuration = dbo.fn_Char6TimeDiffInSec(@curETIME,@curSTIME)
                END
            END
        END

 
        IF @curDuration > 0
            BEGIN
                -- 新增紀錄
                INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus, id)
                VALUES (@curSTIME, @curETIME, @curDuration, @curStatus, @id);

 
            END

        -- 更新上一筆紀錄的結束時間
        --SET @PrevETime = @curETIME;
        FETCH NEXT FROM EQPCursor INTO @curSTIME, @curETIME, @curDuration, @curStatus, @id;

    END
    -- 關閉游標並釋放資源

    CLOSE EQPCursor;

    DEALLOCATE EQPCursor;

 

           -- --------------------------------------------------------------------------------------

         

 

           -- 2. 補上不連續的時間

 

           --SET @PrevETime = ''

--   DECLARE tempCur CURSOR FOR

           --       SELECT *

           --       from @tmpRuntime

           --       ORDER BY STIME;

 

--   -- 開啟游標

--   OPEN tempCur;

 

--   FETCH NEXT FROM tempCur INTO @curSTIME, @curETIME, @curDuration, @curStatus;

 

--   WHILE @@FETCH_STATUS = 0

--   BEGIN

             

           --       -- 跳過第一筆紀錄

           --       IF (@PrevETime = '')

           --       BEGIN

           --                  SET @PrevETime = @curETIME;

           --                  CONTINUE;

           --       END

                   

           --       -- 有不連續的紀錄

           --       IF (@curSTIME > @PrevETime)

           --       BEGIN

           --                  -- 新增紀錄

           --                  INSERT INTO @tmpRuntime (STIME, ETIME, DURATION, OPStatus)

           --                  VALUES (@PrevETime, @curSTIME, dbo.fn_Char6TimeDiffInSec(@curSTIME,@PrevETime), '-2');

           --       END

 

--   END

 

--   -- 關閉游標並釋放資源

--   CLOSE tempCur;

--   DEALLOCATE tempCur;

 

           -- -----------------------------------------------------------------------------

 

         

    -- 返回結果

    SELECT *, concat(STIME,';',OPStatus) as SerialName FROM @tmpRuntime where DURATION <> 0 ORDER BY STIME;

 

 

           -- 清理暫存表

           --DROP TABLE @tmpRuntime;

END