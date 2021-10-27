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

create table #temptable  (	ID int IDENTITY, 
						ColName01 varchar(100), 
						ColName02 varchar(100), 
						ColName03 varchar(100), 
						ColName04 varchar(100), 
						ColName05 varchar(100), 
						ColName06 varchar(100), 
						ColName07 varchar(100), 
						ColName08 varchar(100), 
						ColName09 varchar(100), 
						ColName10 varchar(100), 
						ColName11 varchar(100), 
						ColName12 varchar(100), 
						ColName13 varchar(100), 
						ColName14 varchar(100), 
						ColName15 varchar(100), 
						ColName16 varchar(100), 
						ColName17 varchar(100), 
						ColName18 varchar(100), 
						ColName19 varchar(100), 
						ColName20 varchar(100), 
						ColName21 varchar(100), 
						ColName22 varchar(100), 
						ColName23 varchar(100), 
						ColName24 varchar(100), 
						ColName25 varchar(100), 
						ColName26 varchar(100), 
						ColName27 varchar(100), 
						ColName28 varchar(100), 
						ColName29 varchar(100), 
						ColName30 varchar(100), 
						ColName31 varchar(100), 
						ColName32 varchar(100), 
						ColName33 varchar(100), 
						ColName34 varchar(100), 
						ColName35 varchar(100), 
						ColName36 varchar(100), 
						ColName37 varchar(100), 
						ColName38 varchar(100), 
						ColName39 varchar(100), 
						ColName40 varchar(100), 
						ColName41 varchar(100), 
						ColName42 varchar(100), 
						ColName43 varchar(100), 
						ColName44 varchar(100), 
						ColName45 varchar(100), 
						ColName46 varchar(100), 
						ColName47 varchar(100), 
						ColName48 varchar(100))


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