
/*===================================================================================================
Project:			Microsimulations Inputs from Macro MPO 
Institution:		World Bank - ESAPV

Authors:			Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		08/01/2022

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  02/20/2025
===================================================================================================*/

clear all 
set timeout1 60
set timeout2 300

/*===================================================================================================
	1 - WDI POPULATION
===================================================================================================*/

* Load the data
wbopendata, sync
wbopendata, indicator(SP.POP.TOTL; SP.POP.1564.TO; SP.POP.65UP.TO) year(2004:2030) projection clear

* Keep only SAR countries
keep if inlist(countrycode,"AFG","BGD","BTN","IND","MDV","NPL","PAK","LKA")
keep indicatorname  countrycode countryname yr*
replace indicatorname = "pop_15up" if indicatorname == "Population ages 15-64, total"
replace indicatorname = "pop_15up" if indicatorname == "Population ages 65 and above, total"
replace indicatorname = "pop_total" if indicatorname== "Population, total"

collapse (sum) yr*, by(countrycode countryname indicatorname)

* Population share for 15up y.o.
reshape long yr, i(countrycode indicatorname) j(year)
reshape wide yr, i(countrycode year) j (indicatorname) string
gen share_pop = yrpop_15up/yrpop_total

* Save version control
compress
save "$path_mpo\inputs_pop", replace


/*===================================================================================================
	2 - POVMOD MACRO AND POPULATION PROJECTIONS 
===================================================================================================*/

* Load the data
use "$povmod", clear

* Keep only the most recent data
tab date
gen date1=date(date,"MDY")
egen datem= max(date1)
keep if date1 == datem
tab date

* Keep only LAC countries
keep if inlist(countrycode,"AFG","BGD","BTN","IND","MDV","NPL","PAK","LKA") 

* Keep necessary variables
keep countrycode year pop privconstant gdpconstant agriconstant indusconstant servconstant date
order countrycode year privconstant gdpconstant agriconstant indusconstant servconstant pop
sort countrycode year

* Save version control
save "$path_mpo\inputs_mpo_gdp", replace


/*===================================================================================================
	3 - FINAL FILE
===================================================================================================*/

* Merge population data
merge m:m countrycode year using "$path_mpo\inputs_pop", keepusing(share) keep(3) nogenerate

* New populations 
gen pop_15up = pop*share_pop

* File structure
keep countrycode year date privconstant gdpconstant agriconstant indusconstant servconstant  pop*
rename privconstant v_priv
rename gdpconstant v_gdp
rename agriconstant v_gdp_agriculture
rename indusconstant v_gdp_industry
rename servconstant v_gdp_services
rename pop_15up v_pop_15up
rename pop v_pop_total
reshape long v_, i(year countrycode) j(indicator) string
tab date
drop if v_==.
rename countrycode Country
rename year Year
rename indicator Indicator
rename v_ Value

order Country Year Indicator Value

* Saving 
save "$path_mpo\input_mpo_all.dta", replace
export excel using "$path_mpo/$input_master", sheet("input-mpo") sheetreplace firstrow(variables)

/*===================================================================================================
	- END
===================================================================================================*/

