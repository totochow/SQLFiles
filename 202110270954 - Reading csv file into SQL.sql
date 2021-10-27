SET NOCOUNT ON;
GO
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ole Automation Procedures', 1;
GO
RECONFIGURE;
GO


DROP TABLE IF EXISTS #temptable;
GO

-- rename "ColName" to your desired column names

create table #temptable  (	ID int IDENTITY, 
				ColName01 varchar(100), 
				ColName02 varchar(100), 
				ColName03 varchar(100), 
				ColName04 varchar(100), 
					-- ...
				ColNameN varchar(100))


BULK INSERT #temptable
    FROM 'C:\Test\20211026_csv_file.csv'
    WITH
    (
    FIRSTROW = 2, -- starting from row 2, since row 1 in csv is heading
    FIELDTERMINATOR = ',',  --CSV field delimiter
    ROWTERMINATOR = '\n'--,   --Use to shift the control to next row
--    ,TABLOCK
    )

-- DISPLAY the temptable

SELECT * FROM #temptable
ORDER BY ID

DROP TABLE #temptable
