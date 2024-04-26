SELECT 
     o.name AS trigger_name 
    ,'x' AS trigger_owner 
    /*USER_NAME(o.uid)*/ 
    ,s.name AS table_schema 
    ,OBJECT_NAME(o.parent_obj) AS table_name 
    ,OBJECTPROPERTY(o.id, 'ExecIsUpdateTrigger') AS isupdate 
    ,OBJECTPROPERTY(o.id, 'ExecIsDeleteTrigger') AS isdelete 
    ,OBJECTPROPERTY(o.id, 'ExecIsInsertTrigger') AS isinsert 
    ,OBJECTPROPERTY(o.id, 'ExecIsAfterTrigger') AS isafter 
    ,OBJECTPROPERTY(o.id, 'ExecIsInsteadOfTrigger') AS isinsteadof 
    ,OBJECTPROPERTY(o.id, 'ExecIsTriggerDisabled') AS [disabled] 
FROM sysobjects AS o 
/*
INNER JOIN sysusers 
    ON sysobjects.uid = sysusers.uid 
*/  
INNER JOIN sysobjects AS o2 
    ON o.parent_obj = o2.id 

INNER JOIN sysusers AS s 
    ON o2.uid = s.uid 

WHERE o.type IN ('TR', 'V', 'P')

/*--------
Object type:

AF = Aggregate function (CLR)
C = CHECK constraint
D = DEFAULT (constraint or stand-alone)
F = FOREIGN KEY constraint
FN = SQL scalar function
FS = Assembly (CLR) scalar-function
FT = Assembly (CLR) table-valued function
IF = SQL inline table-valued function
IT = Internal table
P = SQL Stored Procedure
PC = Assembly (CLR) stored-procedure
PG = Plan guide
PK = PRIMARY KEY constraint
R = Rule (old-style, stand-alone)
RF = Replication-filter-procedure
S = System base table
SN = Synonym
SO = Sequence object
U = Table (user-defined)
V = View

Applies to: SQL Server 2012 (11.x) and later.

SQ = Service queue
TA = Assembly (CLR) DML trigger
TF = SQL table-valued-function
TR = SQL DML trigger
TT = Table type
UQ = UNIQUE constraint
X = Extended stored procedure

Applies to: SQL Server 2014 (12.x) and later, Azure SQL Database, Azure Synapse Analytics, Analytics Platform System (PDW).

ST = STATS_TREE

Applies to: SQL Server 2016 (13.x) and later, Azure SQL Database, Azure Synapse Analytics, Analytics Platform System (PDW).

ET = External Table

Applies to: SQL Server 2017 (14.x) and later, Azure SQL Database, Azure Synapse Analytics, Analytics Platform System (PDW).

EC = Edge constraint
----------*/