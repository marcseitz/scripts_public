USE [Reporting]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_Wochentag]    Script Date: 07/04/2013 17:09:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER Function [dbo].[fn_Wochentag] (@FuerDatum datetime )


-- Hinweis:
-- Der Wochenstart muss je nach System ggf. angepasst werden.
-- Hierzu sind die Variablen @SA und @SO zu setzen
-- Standardwert = 1 für Sonntag und
--                7 für Samstag
returns varchar (50)
As


Begin


    Declare @M                   As Integer
    Declare @N                   As Integer
    Declare @A                   As Integer
    Declare @B                   As Integer
    Declare @C                   As Integer
    Declare @D                   As Integer
    Declare @E                   As Integer


    Declare @Tag                 As Integer
    Declare @Monat               As Integer
    Declare @Jahr                as Integer
    Declare @TdW                 As Integer
    Declare @strJahr        As char(4 )
    Declare @Datum               As Datetime
    Declare @OsterSonntag   As Datetime
    Declare @BBTag               As Datetime


    Declare @SA                  as integer
    Declare @SO                  as integer


    Declare @RetWert        as varchar(50 )


    set @SA     = 7
    set @SO     = 1
    set @RetWert      = 'AT'
    set @Jahr         = year(@FuerDatum )
    set @strJahr      = convert(char (4), @Jahr)


    -- --------------------------------------------------------------------------------
    -- Gauss'sche Formel zur Berechnung des Osterdatums
    --  Es sei:


    -- J die Jahreszahl                                                         (@Jahr)
    -- a der Divisionsrest von J/19                                        (@A)
    -- b der Divisionsrest von J/4                                         (@B)
    -- c der Divisionsrest von J/7                                         (@C)
    -- d der Divisionsrest von (19*a + M)/30                   (@D)
    -- e der Divisionsrest von (2*b + 4*c + 6*d + N)/7         (@E)


    -- wobei M und N folgende Werte annehmen:                        (@M und @N)


    -- für die Jahre  M     N
    -- 1700-1799            23    3
    -- 1800-1899            23    4
    -- 1900-2099            24    5
    -- 2100-2199            24    6


    -- Dann fällt Ostern auf den (22 + d + e)ten März


    -- oder den (d + e - 9)ten April


    -- Beachte:
    -- Anstelle des 26. Aprils ist immer der 19. April zu setzen,
    -- anstelle des 25. Aprils immer dann der 18. April, wenn d=28 und a>10.
    -- --------------------------------------------------------------------------------


    -- Die Berechnung ist nur für die Jahre 1700 bis 2199 gültig.
    -- Rückgabewert ist im Fehlerfall NULL


    if @Jahr not between 1700 and 2199
      begin
        set @RetWert = NULL
    end
      else
      begin
        set @RetWert = case datepart(weekday ,@FuerDatum)
                                     when @SA then 'Samstag'
                                     when @SO then 'Sonntag'
                                     else @RetWert
                                end


        -- Berechnung der Werte nach Gauss


        set @M = case
                             when @Jahr between 1700 and 1899 then 23
                             when @Jahr between 1900 and 2199 then 24
                             else 0
                        end


        set @N = case
                             when @Jahr between 1700 and 1799 then 3
                             when @Jahr between 1800 and 1899 then 4
                             when @Jahr between 1900 and 2099 then 5
                             when @Jahr between 2100 and 2199 then 6
                             else 0
                        end


        set @A            = @Jahr % 19
        set @B            = @Jahr %  4
        set @C            = @Jahr %  7
        set @D            = ((@A * 19) + @M) % 30
        set @E            = ((@B * 2) + ( @C * 4 ) + (@D * 6) + @N ) % 7


        -- Tagesdatum berechnen


        set @Tag    = case
                                   when @D + @E + 22 > 31 then @D + @E -9   -- April
                                   else @D + @E + 22                              -- März
                               end


        -- Monat berechnen


        set @Monat  = case
                                   when @D + @E + 22 > 31 then 4 -- April
                                   else 3                                         -- März
                               end


        -- Sonderfall für zwei Tage im April berücksichtigen


        set @Tag    = case
                                   when @Tag = 25 and @Monat = 4 and @D=28 and @A>10 then 18
                                   when @Tag = 26 and @Monat = 4                          then 19
                                   else @Tag
                               end


        set @Datum = convert( Datetime,@strJahr + '-' +      substring(convert (char( 3),@Monat +100), 2,2 ) + '-' +
                                                                                  substring(convert (char( 3),@Tag  +100), 2,2 ))
        --Ostersonntag und Buß-und Bettag bestimmen


        set @OsterSonntag = @Datum


        -- Buß-und Bettag ist immer am 11 Tage vor dem ersten Adventssonntag.
        -- Die Formel berücksichtigt die Wochentagsverschiebung wg. dem ersten Tag der Woche.
        -- Dieser kann Montag oder aber auch Sonntag sein.


        set @BBTag          = dateadd(dd ,- datepart (dw, @strJahr + '-12-25') - 38 + @SA ,@strJahr + '-12-25' )


        -- Berechnung der Feiertage kann jetzt beginnen ...


        set @RetWert = case
                                   when datediff (day, @OsterSonntag,@FuerDatum ) = - 2 then 'Karfreitag (alle)'
                                   when datediff (day, @OsterSonntag,@FuerDatum ) =  0 then 'Ostersonntag (alle)'
                                   when datediff (day, @OsterSonntag,@FuerDatum ) =  1 then 'Ostermontag (alle)'
                                   when datediff (day, @OsterSonntag,@FuerDatum ) = 39 then 'Christi Himmelfahrt (alle)'
                                   when datediff (day, @OsterSonntag,@FuerDatum ) = 49 then 'Pfingstsonntag (alle)'
                                   when datediff (day, @OsterSonntag,@FuerDatum ) = 50 then 'Pfingstmontag (alle)'
                                   when datediff (day, @OsterSonntag,@FuerDatum ) = 60 then 'Fronleichnam (BW, BY, HE, NW, RP,SL)'


                                   when @FuerDatum = @BBTag then 'Buß- und Bettag (SN)'
                                  
                                   -- Feste Feiertage


                                   when convert (datetime, @strJahr + '-01-01') = @FuerDatum then 'Neujahr (alle)'
                                   when convert (datetime, @strJahr + '-01-06') = @FuerDatum then 'Heilige drei Könige (BW, BY, ST)'
                                   when convert (datetime, @strJahr + '-05-01') = @FuerDatum then 'Maifeiertag (alle)'
                                   when convert (datetime, @strJahr + '-10-03') = @FuerDatum then 'Tag der deutschen Einheit (alle)'
                                   when convert (datetime, @strJahr + '-08-15') = @FuerDatum then 'Mariä Himmelfahrt (BY, SL)'
                                   when convert (datetime, @strJahr + '-10-31') = @FuerDatum then 'Reformationstag (BB, MV, SN, ST, TH)'
                                   when convert (datetime, @strJahr + '-11-01') = @FuerDatum then 'Allerheiligen (BW, BY, NW, RP, SL)'
                                   --when convert(datetime,@strJahr + '-12-24') = @FuerDatum then 'Heiligbend'
                                   when convert (datetime, @strJahr + '-12-25') = @FuerDatum then '1. Weihnachtstag (alle)'
                                   when convert (datetime, @strJahr + '-12-26') = @FuerDatum then '2. Weihnachtstag (alle)'
                                   --when convert(datetime,@strJahr + '-12-31') = @FuerDatum then 'Silvester'
                                  
                                   else @RetWert
                             end
    end


    return @RetWert
end
