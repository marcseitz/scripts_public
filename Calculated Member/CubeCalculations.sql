CALCULATE;
CREATE CELL CALCULATION CURRENTCUBE.[EUR_CUM_nach_EUR_SINGLE] FOR '({[DIM_GENERAL_CURRENCY].&[EUR]}, {[DIM_GENERAL_TIME_OPTION].&[single]})' AS '/* Sonderegelung für die [Total Tertial] und [1st tertial], die jeweils Vorgänger besitzen, und die Monate die noch nicht gefüllt sind */
 
 
Iif(
 
--[DIM_GENERAL_MONTH].currentmember is [DIM_GENERAL_MONTH].&[Total Tertial]
--or [DIM_GENERAL_MONTH].currentmember is [DIM_GENERAL_MONTH].[Quarter].&[1st tertial]
--or
isempty(([DIM_GENERAL_MONTH].currentmember,[DIM_GENERAL_TIME_OPTION].&[cum])),
 
/* Einfache Übernahme des CUM Wertes */
([DIM_GENERAL_MONTH].currentmember,[DIM_GENERAL_TIME_OPTION].&[cum]),
/* Differenzberechnung */
([DIM_GENERAL_MONTH].currentmember,[DIM_GENERAL_TIME_OPTION].&[cum])-([DIM_GENERAL_MONTH].prevmember,[DIM_GENERAL_TIME_OPTION].&[cum])
)
', SOLVE_ORDER = -5120, DESCRIPTION = 'Berechnung der Eur_Single Werte aus Eur_Cum Werten (auch für die Terziale) ; aktueller CumMonatswert- CumVormonat';
CREATE CELL CALCULATION CURRENTCUBE.[LOCAL_Aggregation_disable] FOR '({[DIM_GENERAL_CURRENCY].&[local]})' AS 'null', DESCRIPTION = 'Ausschalten (mit Null überschreiben) der Aggregation für lokale Währungen über mehrere TGs (Sub.sum, SICK Group)', CONDITION = '-- Wird nur für SICK Group und Sub.sum nicht ermittelt -> C-Rule berechnertes C-Element wird überblendet (kein Wert angezeigt)
--([DIM_GENERAL_COMPANY].CurrentMember is [DIM_GENERAL_COMPANY].&[SICK Group])or
 
([DIM_GENERAL_COMPANY_CSC].CurrentMember is [DIM_GENERAL_COMPANY_CSC].[Subs. Sum])';
CREATE CELL CALCULATION CURRENTCUBE.[CUM_MONTH_AllLevel_disable aggregation] FOR '([DIM_GENERAL_MONTH].[All].MEMBERS, {[DIM_GENERAL_TIME_OPTION].&[cum]})' AS '-- Sonderregelung zum Überschreiben der Standard-Aggreation für Total Year durch den CUM-Dezemberwert
[DIM_GENERAL_MONTH].[Quarter].&[4th Quarter].&[Dec]', DESCRIPTION = 'Überschreiben der Standardaggregation für Totel Year', CALCULATION_PASS_NUMBER = '2';
CREATE CELL CALCULATION CURRENTCUBE.[CUM_MONTH_Quarters_disable aggregation] FOR '(DESCENDANTS([DIM_GENERAL_MONTH].&[Total Year]), {[DIM_GENERAL_TIME_OPTION].&[cum]})' AS '-- Sonderregelung zum Überschreiben der Standard-Aggreation für die Quartale durch den jeweilig letzten kumulierten Monatswert des entsprechenden Quartals
DIM_GENERAL_month.currentmember.lastchild', DESCRIPTION = 'Überschreiben der Standardaggregation für die Quartale', CONDITION = 'not isleaf(DIM_GENERAL_month.currentmember)', CALCULATION_PASS_NUMBER = '2';
CREATE CELL CALCULATION CURRENTCUBE.[VERSION ACT BT in percent] FOR '({[DIM_GENERAL_VERSION].&[Act./.BT %]}
)' AS 'IIF(abs([DIM_GENERAL_VERSION].&[Budget])<0.00001,null,[DIM_GENERAL_VERSION].&[Act./.BT]/[DIM_GENERAL_VERSION].&[Budget]*100)
', DESCRIPTION = 'Berechnung des Prozentwertes der Abweichung Act/BT';
CREATE CELL CALCULATION CURRENTCUBE.[VERSION ACT FCII in percent] FOR '({[DIM_GENERAL_VERSION].&[Act./.FC II %]})' AS 'iif( [CONTRIB_CSC_ITEM].currentmember.Properties("Attr Item Type") = "cum" ,
 
IIF(abs([DIM_GENERAL_VERSION].&[FC II])<0.00001,NULL,[DIM_GENERAL_VERSION].&[Act./.FC II]/[DIM_GENERAL_VERSION].&[FC II]*100)
,
null
)', DESCRIPTION = 'Berechnung des Prozentwertes der Abweichung Act/FCII', CALCULATION_PASS_NUMBER = '2';
CREATE CELL CALCULATION CURRENTCUBE.[VERSION FCI BT in percent] FOR '({[DIM_GENERAL_VERSION].&[FC I./.BT %]})' AS 'iif( [CONTRIB_CSC_ITEM].currentmember.Properties("Attr Item Type") = "cum" ,
 
IIF(abs([DIM_GENERAL_VERSION].&[Budget])<0.00001,null,[DIM_GENERAL_VERSION].&[FC I./.BT]/[DIM_GENERAL_VERSION].&[Budget]*100)
,
null
)', DESCRIPTION = 'Berechnung des Prozentwertes der Abweichung FCI/BT', CALCULATION_PASS_NUMBER = '2';
CREATE CELL CALCULATION CURRENTCUBE.[VERSION FCII BT in percent] FOR '({[DIM_GENERAL_VERSION].&[FC II./.BT %]})' AS 'iif( [CONTRIB_CSC_ITEM].currentmember.Properties("Attr Item Type") = "cum" ,
 
IIF(abs([DIM_GENERAL_VERSION].&[Budget])<0.00001,null,[DIM_GENERAL_VERSION].&[FC II./.BT]/[DIM_GENERAL_VERSION].&[Budget]*100)
,
null
)
 
 
 
 
 
', DESCRIPTION = 'Berechnung des Prozentwertes der Abweichung FCII/BT', CALCULATION_PASS_NUMBER = '2';
CREATE CELL CALCULATION CURRENTCUBE.[VERSION ACT PY in percent] FOR '({[DIM_GENERAL_VERSION].&[Act./.PY %]})' AS 'iif( [CONTRIB_CSC_ITEM].currentmember.Properties("Attr Item Type") = "cum" ,
 
IIF(abs(([DIM_GENERAL_YEAR].prevmember,[DIM_GENERAL_VERSION].&[Actual]))<0.00001,NULL,[DIM_GENERAL_VERSION].&[Act./.PY]/  ([DIM_GENERAL_YEAR].prevmember,[DIM_GENERAL_VERSION].&[Actual])*100)
 
,
null
)
 
', DESCRIPTION = 'Berechnung des Prozentwertes der Abweichung Act/PY', CALCULATION_PASS_NUMBER = '2';
CREATE CELL CALCULATION CURRENTCUBE.[VERSION BT FCII in percent] FOR '({[DIM_GENERAL_VERSION].&[BT./.FC II %]})' AS '
iif( [CONTRIB_CSC_ITEM].currentmember.Properties("Attr Item Type") = "cum" ,
 
IIF(abs(([DIM_GENERAL_YEAR].prevmember,[DIM_GENERAL_VERSION].&[FC II]))<0.00001,null,[DIM_GENERAL_VERSION].&[BT./.FC II]/([DIM_GENERAL_YEAR].prevmember,[DIM_GENERAL_VERSION].&[FC II])*100)
 
 
,
null
)
 
 
 
 
 
 
 
', DESCRIPTION = 'Berechnung des Prozentwertes der Abweichung BT/FCII', CALCULATION_PASS_NUMBER = '2';
CREATE CELL CALCULATION CURRENTCUBE.[FCI_dec_cum_only] FOR '({[DIM_GENERAL_VERSION].&[FC I]})' AS 'null', CONDITION = '[DIM_GENERAL_TIME_OPTION].currentmember is [DIM_GENERAL_TIME_OPTION].&[single]
or ([DIM_GENERAL_TIME_OPTION].currentmember is [DIM_GENERAL_TIME_OPTION].&[cum]
and not [DIM_GENERAL_MONTH].currentmember is [DIM_GENERAL_MONTH].[Dec]
)
';
CREATE CELL CALCULATION CURRENTCUBE.[FCII_dec_cum_only] FOR '({[DIM_GENERAL_VERSION].&[FC II]})' AS 'null
', CONDITION = '[DIM_GENERAL_TIME_OPTION].currentmember is [DIM_GENERAL_TIME_OPTION].&[single]
or ([DIM_GENERAL_TIME_OPTION].currentmember is [DIM_GENERAL_TIME_OPTION].&[cum]
and not [DIM_GENERAL_MONTH].currentmember is [DIM_GENERAL_MONTH].[Dec]
)
 
';
ALTER CUBE [CONTRIB_CSC]
UPDATE DIMENSION [DIM_GENERAL_CURRENCY], DEFAULT_MEMBER='[CURRENCY].&[EUR]';
ALTER CUBE [CONTRIB_CSC]
UPDATE DIMENSION [DIM_GENERAL_MONTH], DEFAULT_MEMBER='[MONTH].&[Total Year]';
ALTER CUBE [CONTRIB_CSC]
UPDATE DIMENSION [DIM_GENERAL_TIME_OPTION], DEFAULT_MEMBER='[TIME_OPTION].&[single]';
ALTER CUBE [CONTRIB_CSC]
UPDATE DIMENSION [DIM_GENERAL_VERSION], DEFAULT_MEMBER='[VERSION].&[Actual]';
ALTER CUBE [CONTRIB_CSC]
UPDATE DIMENSION [DIM_GENERAL_YEAR], DEFAULT_MEMBER='strtomember("["+cstr(year(now()))+"]")';
