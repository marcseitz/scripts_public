-- Here are 4 calculated members you might find useful (you'll have to change the measure to what is currently being used in your cube the measure I use is Units in the example):
 
-- Percenct of Total for Column:
 
CREATE MEMBER CURRENTCUBE.[MEASURES].[Mkt Shr Col]
AS
Case when isempty([Measures].[Units])
then 0
else iif(isempty(Axis(1).Item(0).Item(0).Dimension.CurrentMember.Parent),1,[Measures].[Units]/(Axis(1).Item(0).Item(0).Dimension.CurrentMember.Parent,Measures.Units))
End
 
-- Percent of Total for Row:
 
CREATE MEMBER CURRENTCUBE.[MEASURES].[Mkt Shr Row]
AS
Case when isempty([Measures].[Units])
then 0
else iif(isempty(Axis(1).Item(0).Item(0).Dimension.CurrentMember.Parent),1,[Measures].[Units]/(Axis(1).Item(0).Item(0).Dimension.CurrentMember.Parent,Measures.Units))
End
 
-- The next two give the Percent of Total for a multi-tiered columns or rows based on the top most tier (these only work if more than one column or row are used by definition and your best bet for understanding what they do is to actually play around with them but they can be quite useful)
-- Percent of Column Total:
 
CREATE MEMBER CURRENTCUBE.[MEASURES].[Pct of Col Total]
AS
Case when Axis(1).Item(0).Count=1 --'(depending on how this is used you might need to add or Axis(1).Item(0).Count=2)'
then 0
else iif(Not(Measures.Units) =0,iif(isempty(((Axis(1).Item(0).Item(1).Dimension.DefaultMember))),1,[Measures].[Units]/(Axis(1).Item(0).Item(1).Dimension.DefaultMember,Measures.Units)),0)
End 
--Percent of Row Total:
 
CREATE MEMBER CURRENTCUBE.[MEASURES].[Pct of Row Total]
AS
Case when Axis(0).Item(0).Count=1 --'(depending on how this is used you might need to add or Axis(0).Item(0).Count=2)'
then 0
else iif(Not(Measures.Units) =0,iif(isempty(((Axis(0).Item(0).Item(1).Dimension.DefaultMember))),1,[Measures].[Units]/(Axis(0).Item(0).Item(1).Dimension.DefaultMember,Measures.Units)),0)
End


With
Set RootSet as {Root()}
Member [Measures].[OrderFraction] as
[Measures].[Order Quantity] /
Sum(RootSet, [Measures].[Order Quantity]),
FORMAT_STRING = 'Percent'
select [Date].[Calendar Year].Members on 0,
[Product].[Category].Members on 1
from [Adventure Works]
where [Measures].[OrderFraction]

