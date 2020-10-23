/* --------------------------------------------------------------------------------------------------
Background of the report:

This is one of the first SQL script/report that I developed as an Inventory Analyst
The company that just recently replaced their ERP system (Microsoft Dynamics GP 10.0 to Microsoft Dynamics GP 2018 with a Third-party integration software) 
We did not have an adequate way to show inventory on hand for the sales team as well as the total amount of quantity being on ordered.
This limited the sales team's visibility when overselling and missed the opportunity of offering customers similar products (i.e. different package size). 
The chance of item bing backordered was high.
This report bridged the gap for the sales team to have visibility over available to promise, as well as excluding "phantom inventory" due to a process of temporary adding quantity in the system, 

This report is still being using today, and it is now in version 3 as of Oct 2020.

-------------------------------------------------------------------------------------------------- */

--------------------------------------------
-- Dropping and Creating temporary tables --
--------------------------------------------


IF OBJECT_ID('tempdb..#QOH102120201323') IS NOT NULL DROP TABLE #QOH102120201323
IF OBJECT_ID('tempdb..#QTYALC102120201325') IS NOT NULL DROP TABLE #QTYALC102120201325
IF OBJECT_ID('tempdb..#INT102320201326') IS NOT NULL DROP TABLE #INT102320201326

----------------------------
-- #QOH102120201323 (QOH) --
----------------------------

SELECT		ITMMAST.ITEMNMBR,
		ITMCAT.UserCatLongDescr, 
		SUM(ITMQTY.QTYRECVD - ITMQTY.QTYSOLD - ITMQTY.ATYALLOC) AS QOH,
		ITMMAST.UOMSCHDL
INTO		#QOH102120201323
FROM		FISH1.dbo.IV00101 AS ITMMAST  WITH (NOLOCK)
	JOIN	FISH1.dbo.IV40600 AS ITMCAT  WITH (NOLOCK)
		ON	ITMMAST.USCATVLS_5 = ITMCAT.USCATVAL
	JOIN	FISH1.dbo.IV00300 AS ITMQTY  WITH (NOLOCK)
		ON	ITMMAST.ITEMNMBR = ITMQTY.ITEMNMBR
WHERE		ITMCAT.USCATNUM = '5'
		AND ITMQTY.LOCNCODE IN ('PLANT')
		AND ITMQTY.LOTNUMBR NOT LIKE '%+' 
		AND ITMQTY.LOTNUMBR NOT LIKE '%SYS%'
		AND ITMQTY.QTYTYPE = '1'
		AND (ITMQTY.QTYRECVD - ITMQTY.QTYSOLD - ITMQTY.ATYALLOC) > 0
GROUP BY 	ITMCAT.UserCatLongDescr, ITMMAST.UOMSCHDL, ITMMAST.ITEMNMBR



/*----------------------------------------------------
The following line status 
are to be included as allocations

505	New
510	Approved
514	Partially Allocated
515	Allocated
520	Released
530	Picking In Progress
-------------------------------------------------------*/

---------------------------------------
-- #QTYALC102120201325 (Allocations) --
---------------------------------------
SELECT		ITMMAST.ITEMNMBR AS itemNum,
		CASE WHEN SH.ShipDate <= getdate()+1 THEN  SUM((SL.quantity - SL.qtyRcvd)*UCON.QTYBSUOM) 
		ELSE 0 END AS QTYALC,
		CASE WHEN SH.ShipDate > getdate()+1 THEN  SUM((SL.quantity - SL.qtyRcvd)*UCON.QTYBSUOM) 
		ELSE 0 END AS QTYALC_FUTURE,
		ITMMAST.UOMSCHDL,
		SH.siteID
INTO		#QTYALC102120201325
FROM		WebsanTimePortal..salesLine SL WITH (NOLOCK)
	JOIN	FISH1..IV00101 ITMMAST WITH (NOLOCK)	ON SL.itemNum = ITMMAST.ITEMNMBR
	JOIN	FISH1..IV00108 UCON  WITH (NOLOCK) ON ITMMAST.ITEMNMBR = UCON.ITEMNMBR AND SL.itemNum = UCON.ITEMNMBR AND SL.uofm = UCON.UOFM
	JOIN	WebsanTimePortal..salesHeader SH WITH (NOLOCK) ON SH.reqNum = SL.reqNum AND SH.interid = SL.interid
WHERE		SH.interid <> 'TFISH'
			AND	UCON.CURNCYID = 'Z-C$'
			AND	SH.salesStatus NOT IN ('500','540','550', '560') AND (SL.lineStatus IS NULL OR SL.lineStatus IN ('505','510','514','515','520')) 
			-- NOT INCLUDING Heading: 500 Cancelled, 540 Picking Completed, 550 Completed, 560 Delivered AND Line not greater than 530 (picking in progress)
			AND	SH.docID <> 'QTE'
			AND	SH.ShipDate > getdate()-1
			AND SH.siteID = ('PLANT')
GROUP BY	SH.SiteID, SH.ShipDate, ITMMAST.ITEMNMBR, ITMMAST.UOMSCHDL



------------------------------
------ #INT102320201326 ------
-- (In Transit allocations) --
------------------------------

SELECT		RTRIM(LV.ITEMNMBR) AS [ITEM NUM], 
		SUM(QTYFROM - QTYFULFI) AS ALLOCATED,
		RTRIM(LV.TRXLOCTN) [FROM]
INTO		#INT102320201326		
FROM		FISH1..IV00701V LV WITH (NOLOCK)
WHERE		RTRIM(TRXLOCTN)  IN ('PLANT')
		AND	(QTYFROM - QTYFULFI) > 0
GROUP BY	LV.TRXLOCTN, LV.ITEMNMBR




----------------------
-- Main Report Body -- 
----------------------

SELECT		RTRIM(ITMCAT.UserCatLongDescr) AS UserCatLongDescr,
		RTRIM(ITMMAST.ITEMNMBR) AS ITEMNMBR,
		RTRIM(ITMMAST.ITEMDESC) AS ITEMDESC,
		(ITMQTY.QOH) AS QTYAVA,
		RTRIM(ITMMAST.UOMSCHDL) AS UOMSCHDL,
		PRICE1.PSITMVAL AS 'LEVEL 1 PRICE',
		PRICE4.PSITMVAL AS 'LEVEL 4 PRICE',
		PRICE5.PSITMVAL AS 'LEVEL 5 PRICE',
		PRICE6.PSITMVAL AS 'LEVEL 6 PRICE',
		PRICE7.PSITMVAL AS 'LEVEL 7 PRICE',
		PRICEREG.PSITMVAL AS 'REG PRICE',
		PRICE1.UOFM AS 'PRCE LVL UoM',
		ROW_NUMBER() OVER(PARTITION BY ITMMAST.ITEMNMBR ORDER BY ITMMAST.ITEMNMBR DESC) AS rn,
		QTYALLOC.QTYALC,
		QTYALLOC.QTYALC_FUTURE,
		QTYALLOC.UOMSCHDL AS SOUM,
		ITMMAST.USCATVLS_5,
		INTRANSIT.ALLOCATED

FROM		FISH1.dbo.IV00101 AS ITMMAST  WITH (NOLOCK)
	JOIN	FISH1.dbo.IV40600 AS ITMCAT  WITH (NOLOCK)
		ON	ITMMAST.USCATVLS_5 = ITMCAT.USCATVAL
	JOIN	#QOH102120201323 AS ITMQTY ON ITMMAST.ITEMNMBR = ITMQTY.ITEMNMBR
	FULL OUTER JOIN	
		#QTYALC102120201325	AS QTYALLOC ON QTYALLOC.itemNum = ITMMAST.ITEMNMBR AND QTYALLOC.UOMSCHDL = ITMMAST.UOMSCHDL
	FULL OUTER JOIN 
		#INT102320201326 AS INTRANSIT ON INTRANSIT.[ITEM NUM] = ITMMAST.ITEMNMBR


------------------------------
--Price Sheets1,4,5,6REG & 7--
------------------------------

			LEFT JOIN (SELECT  DISTINCT A.PRCSHID, A.ITEMNMBR, B.UOMSCHDL AS UOFM, A.PSITMVAL/C.QTYBSUOM AS PSITMVAL FROM FISH1..IV10402 A WITH (NOLOCK)
						JOIN FISH1..IV00101 B  WITH (NOLOCK) ON B.ITEMNMBR = A.ITEMNMBR
						JOIN FISH1..IV00108 C WITH (NOLOCK) ON A.UOFM = C.UOFM AND A.ITEMNMBR = C.ITEMNMBR
						WHERE PRCSHID = '1') AS PRICE1 ON ITMMAST.ITEMNMBR = PRICE1.ITEMNMBR AND ITMMAST.UOMSCHDL = PRICE1.UOFM
			LEFT JOIN (SELECT  DISTINCT A.PRCSHID, A.ITEMNMBR, B.UOMSCHDL AS UOFM, A.PSITMVAL/C.QTYBSUOM AS PSITMVAL FROM FISH1..IV10402 A WITH (NOLOCK)
						JOIN FISH1..IV00101 B WITH (NOLOCK) ON B.ITEMNMBR = A.ITEMNMBR
						JOIN FISH1..IV00108 C WITH (NOLOCK) ON A.UOFM = C.UOFM AND A.ITEMNMBR = C.ITEMNMBR
						WHERE PRCSHID = '4') AS PRICE4 ON ITMMAST.ITEMNMBR = PRICE4.ITEMNMBR AND ITMMAST.UOMSCHDL = PRICE4.UOFM
			LEFT JOIN (SELECT  DISTINCT A.PRCSHID, A.ITEMNMBR, B.UOMSCHDL AS UOFM, A.PSITMVAL/C.QTYBSUOM AS PSITMVAL FROM FISH1..IV10402 A WITH (NOLOCK)
						JOIN FISH1..IV00101 B WITH (NOLOCK) ON B.ITEMNMBR = A.ITEMNMBR
						JOIN FISH1..IV00108 C WITH (NOLOCK) ON A.UOFM = C.UOFM AND A.ITEMNMBR = C.ITEMNMBR
						WHERE PRCSHID = '5') AS PRICE5 ON ITMMAST.ITEMNMBR = PRICE5.ITEMNMBR AND ITMMAST.UOMSCHDL = PRICE5.UOFM
			LEFT JOIN (SELECT  DISTINCT A.PRCSHID, A.ITEMNMBR, B.UOMSCHDL AS UOFM, A.PSITMVAL/C.QTYBSUOM AS PSITMVAL FROM FISH1..IV10402 A WITH (NOLOCK)
						JOIN FISH1..IV00101 B WITH (NOLOCK) ON B.ITEMNMBR = A.ITEMNMBR
						JOIN FISH1..IV00108 C WITH (NOLOCK) ON A.UOFM = C.UOFM AND A.ITEMNMBR = C.ITEMNMBR
						WHERE PRCSHID = '6') AS PRICE6 ON ITMMAST.ITEMNMBR = PRICE6.ITEMNMBR AND ITMMAST.UOMSCHDL = PRICE6.UOFM
			LEFT JOIN (SELECT  DISTINCT A.PRCSHID, A.ITEMNMBR, B.UOMSCHDL AS UOFM, A.PSITMVAL/C.QTYBSUOM AS PSITMVAL FROM FISH1..IV10402 A WITH (NOLOCK)
						JOIN FISH1..IV00101 B WITH (NOLOCK) ON B.ITEMNMBR = A.ITEMNMBR
						JOIN FISH1..IV00108 C WITH (NOLOCK) ON A.UOFM = C.UOFM AND A.ITEMNMBR = C.ITEMNMBR
						WHERE PRCSHID = 'REG') AS PRICEREG ON ITMMAST.ITEMNMBR = PRICEREG.ITEMNMBR AND ITMMAST.UOMSCHDL = PRICEREG.UOFM
			LEFT JOIN (SELECT  DISTINCT A.PRCSHID, A.ITEMNMBR, B.UOMSCHDL AS UOFM, A.PSITMVAL/C.QTYBSUOM AS PSITMVAL FROM FISH1..IV10402 A WITH (NOLOCK)
						JOIN FISH1..IV00101 B WITH (NOLOCK) ON B.ITEMNMBR = A.ITEMNMBR
						JOIN FISH1..IV00108 C WITH (NOLOCK) ON A.UOFM = C.UOFM AND A.ITEMNMBR = C.ITEMNMBR
						WHERE PRCSHID = '7') AS PRICE7 ON ITMMAST.ITEMNMBR = PRICE7.ITEMNMBR AND ITMMAST.UOMSCHDL = PRICE7.UOFM

				WHERE			ITMCAT.USCATNUM = '5'
							AND ITMMAST.USCATVLS_5 IN('1','2','3') -- item type 1 = fresh, 2 = frozen, 3 = live


ORDER BY		ITMCAT.UserCatLongDescr, ITMMAST.ITEMDESC
