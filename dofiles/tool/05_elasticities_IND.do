
/*===================================================================================================
Project:			Elasticities sets for Microsimulation Tool
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		02/25/2022

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  02/23/2026 
===================================================================================================*/

drop _all

/*===================================================================================================
 	0 - SETTING
===================================================================================================*/

* Set up Elasticities - Countries to include and their RESPECTIVE year restriction
gl countries 	"IND"  
gl min_year 	"2017"
gl last_year 	"2023"

* Set up postfile for results
tempname regressions
tempfile aux
postfile `regressions' str3(Country) str10(Period) str11(Year) str20(Model) str80(Elasticity) Value using `aux', replace

local n : word count $countries

/*===================================================================================================
 	1 - DATA FILE AND VARIABLES
===================================================================================================*/

use "$path_mpo\inputs_hhss_elasticities_IND", clear

replace Indicator = subinstr(Indicator," ","_",.)
replace Indicator = subinstr(Indicator,".","",.)

reshape wide Value, i(Country Year) j(Indicator) string

ren Value* *
ren *, lower
ren agri gdp1
ren indus gdp2
ren serv gdp3

drop if active_population == . | gdp == . 

* Total of workers by sector
for any 1 2 3 : egen workers_X = rowtotal(skilled_workers_X unskilled_workers_X)

* Total of workers by skill level
for any skilled unskilled : egen workers_X = rowtotal(X_workers_1 X_workers_2 X_workers_3)

* Total of workers
egen workers = rowtotal(workers_skilled workers_unskilled)

* Unskilled rate
gen unskilled = workers_unskilled / workers

* Productivities
for any 1 2 3 : gen prod_X = X / workers_X 

* Creating lns of employment and gdp
foreach v of varlist active_population *_workers_* prod_* gdp* avg* {
	gen ln_`v' = ln(`v')
}

* Growth rates
foreach v of varlist active_population *_workers_* prod_* gdp* *income* {
	gen growth_`v' = (`v'/ `v'[_n-1] - 1) if country[_n] == country[_n-1]
}

* Annual elasticities employment
for any 1 2 3 : gen elas_gdp_sk_X = growth_skilled_workers_X / growth_gdpX
for any 1 2 3 : gen elas_gdp_unsk_X = growth_unskilled_workers_X / growth_gdpX
gen elas_gdp_emp = growth_active_population / growth_gdp

* Annual elasticities income
for any 1 2 3 : gen elas_prod_sk_X = growth_avg_skilled_income_X / growth_prod_X
for any 1 2 3 : gen elas_prod_unsk_X = growth_avg_unskilled_income_X / growth_prod_X

* Iteration variables ln_gdp * Unskilled rate
gen iteration = ln_gdp * unskilled

* Missing variables
for any elas_gdp_emp_1_99 elas_gdp_emp_1_99_imp: gen X = .
local sectors "1 2 3"
foreach s of local sectors {
	qui gen elas_gdp_sk_`s'_1_99 = .
	qui gen elas_gdp_unsk_`s'_1_99 = .
	qui gen elas_prod_sk_`s'_1_99 = .
	qui gen elas_prod_unsk_`s'_1_99 = .
	
	qui gen elas_gdp_sk_`s'_1_99_imp = .
	qui gen elas_gdp_unsk_`s'_1_99_imp = .
	qui gen elas_prod_sk_`s'_1_99_imp = .
	qui gen elas_prod_unsk_`s'_1_99_imp = .
}

* Generating annual elasticites data
preserve 
	keep country year elas_*
	reshape long elas_, i(country year) j(elas) string
	drop if elas_==.
	replace elas = "gdp_activity" if elas == "gdp_emp"
	export excel using "$path_mpo\input_MASTER.xlsx", sheet("Elasticities by year IND") sheetreplace firstrow(variables)
restore


/*===================================================================================================
* 	2 - ELASTICITIES
===================================================================================================*/

loc country "IND"


	/*===================================================================================================
	* 2.1 - Minimum year to last year available
	===================================================================================================*/
	
	di in red "Period $min_year - $last_year"
	
	/*===================================================================================================
	* 2.1.1 - Simple averages
	===================================================================================================*/
	
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp if year >= $min_year & year <= $last_year & country == "`country'"
	loc av_elas_gdp_emp = r(mean)
	post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg") ("gdp_activity") (`av_elas_gdp_emp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui sum elas_gdp_sk_`sector' if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_gdp_sk_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg") ("gdp_sk_`sector'") (`avg_elas_gdp_sk_`sector'')
		
		** Low skilled
		qui sum elas_gdp_unsk_`sector' if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_gdp_unsk_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg") ("gdp_unsk_`sector'") (`avg_elas_gdp_unsk_`sector'')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui sum elas_prod_sk_`sector' if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_prod_sk_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg") ("prod_sk_`sector'") (`avg_elas_prod_sk_`sector'')
		
		** Low skilled
		qui sum elas_prod_unsk_`sector' if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_prod_unsk_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg") ("prod_unsk_`sector'") (`avg_elas_prod_unsk_`sector'')
		
	}
	
	
	/*===================================================================================================
	* 2.1.2 - Averages without outliers (1%-99%)
	===================================================================================================*/
	
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp if year >= $min_year & year <= $last_year & country == "`country'", d
	qui replace elas_gdp_emp_1_99 = elas_gdp_emp if year >= $min_year & year <= $last_year & country == "`country'" & elas_gdp_emp > r(p1) & elas_gdp_emp < r(p99)
	qui sum elas_gdp_emp_1_99 if year >= $min_year & year <= $last_year & country == "`country'"
	loc av_elas_gdp_emp_1_99 = r(mean)
	post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg_1_99") ("gdp_activity") (`av_elas_gdp_emp_1_99')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui sum elas_gdp_sk_`sector' if year >= $min_year & year <= $last_year & country == "`country'", d
		qui replace elas_gdp_sk_`sector'_1_99 = elas_gdp_sk_`sector' if year >= $min_year & year <= $last_year & country == "`country'" &elas_gdp_sk_`sector' > r(p1) & elas_gdp_sk_`sector' < r(p99)
		qui sum elas_gdp_sk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_gdp_sk_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg_1_99") ("gdp_sk_`sector'") (`avg_elas_gdp_sk_`sector'_1_99')
		
		** Low skilled
		qui sum elas_gdp_unsk_`sector' if year >= $min_year & year <= $last_year & country == "`country'", d
		qui replace elas_gdp_unsk_`sector'_1_99 = elas_gdp_unsk_`sector' if year >= $min_year & year <= $last_year & country == "`country'" & elas_gdp_unsk_`sector' > r(p1) & elas_gdp_unsk_`sector' < r(p99)
		qui sum elas_gdp_unsk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_gdp_unsk_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg_1_99") ("gdp_unsk_`sector'") (`avg_elas_gdp_unsk_`sector'_1_99')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui sum elas_prod_sk_`sector' if year >= $min_year & year <= $last_year & country == "`country'", d
		qui replace elas_prod_sk_`sector'_1_99 = elas_prod_sk_`sector' if year >= $min_year & year <= $last_year & country == "`country'" & elas_prod_sk_`sector' > r(p1) & elas_prod_sk_`sector' < r(p99)
		qui sum elas_prod_sk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_prod_sk_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg_1_99") ("prod_sk_`sector'") (`avg_elas_prod_sk_`sector'_1_99')
		
		** Low skilled
		qui sum elas_prod_unsk_`sector' if year >= $min_year & year <= $last_year & country == "`country'", d
		qui replace elas_prod_unsk_`sector'_1_99 = elas_prod_unsk_`sector' if year >= $min_year & year <= $last_year & country == "`country'" & elas_prod_unsk_`sector' > r(p1) & elas_prod_unsk_`sector' < r(p99)
		qui sum elas_prod_unsk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_prod_unsk_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg_1_99") ("prod_unsk_`sector'") (`avg_elas_prod_unsk_`sector'_1_99')
		
	}
	
	
	/*===================================================================================================
	* 2.1.3 - Averages with imputed outliers (1%-99% using mean)
	===================================================================================================*/
		
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp_1_99 if year >= $min_year & year <= $last_year & country == "`country'", d
	loc av_elas_gdp_emp_1_99 = r(p50)
	qui replace elas_gdp_emp_1_99_imp = elas_gdp_emp_1_99 if year >= $min_year & year <= $last_year & country == "`country'"
	qui replace elas_gdp_emp_1_99_imp = `av_elas_gdp_emp_1_99' if elas_gdp_emp_1_99_imp == . & elas_gdp_emp != . & year >= $min_year & year <= $last_year & country == "`country'"
	qui sum elas_gdp_emp_1_99_imp if year >= $min_year & year <= $last_year & country == "`country'"
	loc av_elas_gdp_emp_1_99_imp = r(mean)
	post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg_1_99_imp") ("gdp_activity") (`av_elas_gdp_emp_1_99_imp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui sum elas_gdp_sk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'", d
		loc avg_elas_gdp_sk_`sector'_1_99 = r(p50)
		qui replace elas_gdp_sk_`sector'_1_99_imp = elas_gdp_sk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'"
		qui replace elas_gdp_sk_`sector'_1_99_imp = `avg_elas_gdp_sk_`sector'_1_99' if elas_gdp_sk_`sector'_1_99_imp == . & elas_gdp_sk_`sector' != . & year >= $min_year & year <= $last_year & country == "`country'"
		qui sum elas_gdp_sk_`sector'_1_99_imp if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_gdp_sk_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg_1_99_imp") ("gdp_sk_`sector'") (`avg_elas_gdp_sk_`sector'_1_99_imp')
		
		** Low skilled
		qui sum elas_gdp_unsk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'", d
		loc avg_elas_gdp_unsk_`sector'_1_99 = r(p50)
		qui replace elas_gdp_unsk_`sector'_1_99_imp = elas_gdp_unsk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'"
		qui replace elas_gdp_unsk_`sector'_1_99_imp = `avg_elas_gdp_unsk_`sector'_1_99' if elas_gdp_unsk_`sector'_1_99_imp == . & elas_gdp_unsk_`sector' != . & year >= $min_year & year <= $last_year & country == "`country'"
		qui sum elas_gdp_unsk_`sector'_1_99_imp if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_gdp_unsk_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg_1_99_imp") ("gdp_unsk_`sector'") (`avg_elas_gdp_unsk_`sector'_1_99_imp')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui sum elas_prod_sk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'", d
		loc avg_elas_prod_sk_`sector'_1_99 = r(p50)
		qui replace elas_prod_sk_`sector'_1_99_imp = elas_prod_sk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'"
		qui replace elas_prod_sk_`sector'_1_99_imp = `avg_elas_prod_sk_`sector'_1_99' if elas_prod_sk_`sector'_1_99_imp == . & elas_prod_sk_`sector' != . & year >= $min_year & year <= $last_year & country == "`country'"
		qui sum elas_prod_sk_`sector'_1_99_imp if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_prod_sk_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg_1_99_imp") ("prod_sk_`sector'") (`avg_elas_prod_sk_`sector'_1_99')
		
		** Low skilled
		qui sum elas_prod_unsk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'", d
		loc avg_elas_prod_unsk_`sector'_1_99 = r(p50)
		qui replace elas_prod_unsk_`sector'_1_99_imp = elas_prod_unsk_`sector'_1_99 if year >= $min_year & year <= $last_year & country == "`country'"
		qui replace elas_prod_unsk_`sector'_1_99_imp = `avg_elas_prod_unsk_`sector'_1_99' if elas_prod_unsk_`sector'_1_99_imp == . & elas_prod_unsk_`sector' != . & year >= $min_year & year <= $last_year & country == "`country'"
		qui sum elas_prod_unsk_`sector'_1_99_imp if year >= $min_year & year <= $last_year & country == "`country'"
		loc avg_elas_prod_unsk_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("avg_1_99_imp") ("prod_unsk_`sector'") (`avg_elas_prod_unsk_`sector'_1_99_imp')
		
	}
	
	
	/*===================================================================================================
	* 2.1.4 - Mean regression
	===================================================================================================*/
	
	* GDP-Activity
	*****************
	qui reg ln_active_population ln_gdp if year >= $min_year & year <= $last_year & country == "`country'"
	loc reg_gdp_emp = _b[ln_gdp]
	post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg") ("gdp_activity") (`reg_gdp_emp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui reg ln_skilled_workers_`sector' ln_gdp`sector' if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_gdp_sk_`sector' = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg") ("gdp_sk_`sector'") (`reg_gdp_sk_`sector'')
		
		** Low skilled
		qui reg ln_unskilled_workers_`sector' ln_gdp`sector' if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_gdp_unsk_`sector' = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg") ("gdp_unsk_`sector'") (`reg_gdp_unsk_`sector'')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui reg ln_avg_skilled_income_`sector' ln_prod_`sector' if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_prod_sk_`sector' = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg") ("prod_sk_`sector'") (`reg_prod_sk_`sector'')
		
		** Low skilled
		qui reg ln_avg_unskilled_income_`sector' ln_prod_`sector' if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_prod_unsk_`sector' = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg") ("prod_unsk_`sector'") (`reg_prod_unsk_`sector'')
		
	}
	
	/*
	/*===================================================================================================
	* 2.1.5 - Median regression
	===================================================================================================*/
	
		* GDP-Activity
		*****************
		qui qreg ln_active_population ln_gdp if year >= $min_year & year <= $last_year & country == "`country'", vce(robust)
		loc med_reg_gdp_emp = _b[ln_gdp]
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("med_reg") ("gdp_activity") (`med_reg_gdp_emp')
		
		* Sectoral GDP-Sectoral Workers 
		**********************************
		local sectors "1 2 3"
		foreach sector of local sectors {
			
			** High skilled
			qui qreg ln_skilled_workers_`sector' ln_gdp`sector' if year >= $min_year & year <= $last_year & country == "`country'"
			loc med_reg_gdp_sk_`sector' = _b[ln_gdp`sector']
			post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("med_reg") ("gdp_sk_`sector'") (`med_reg_gdp_sk_`sector'')
			
			** Low skilled
			qui qreg ln_unskilled_workers_`sector' ln_gdp`sector' if year >= $min_year & year <= $last_year & country == "`country'"
			loc med_reg_gdp_unsk_`sector' = _b[ln_gdp`sector']
			post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("med_reg") ("gdp_unsk_`sector'") (`med_reg_gdp_unsk_`sector'')
			
		}
		
		* Sectoral Productivity-Sectoral Income 
		******************************************
		local sectors "1 2 3"
		foreach sector of local sectors {
			
			** High skilled
			qui qreg ln_avg_skilled_income_`sector' ln_prod_`sector' if year >= $min_year & year <= $last_year & country == "`country'"
			loc med_reg_prod_sk_`sector' = _b[ln_prod_`sector']
			post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("med_reg") ("prod_sk_`sector'") (`med_reg_prod_sk_`sector'')
			
			** Low skilled
			qui qreg ln_avg_unskormal_income_`sector' ln_prod_`sector' if year >= $min_year & year <= $last_year & country == "`country'"
			loc med_reg_prod_unsk_`sector' = _b[ln_prod_`sector']
			post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("med_reg") ("prod_unsk_`sector'") (`med_reg_prod_unsk_`sector'')
			
		}

		*/
	
	/*===================================================================================================
	* 2.1.6 - Mean regression + Total GDP
	===================================================================================================*/
	
	* GDP-Activity
	*****************
	qui reg ln_active_population ln_gdp if year >= $min_year & year <= $last_year & country == "`country'"
	loc reg_gdp_emp_2 = _b[ln_gdp]
	post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg_gdp") ("gdp_activity") (`reg_gdp_emp_2')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui reg ln_skilled_workers_`sector' ln_gdp`sector' ln_gdp if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_gdp_sk_`sector'_2 = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg_gdp") ("gdp_sk_`sector'") (`reg_gdp_sk_`sector'_2')
		
		** Low skilled
		qui reg ln_unskilled_workers_`sector' ln_gdp`sector' ln_gdp if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_gdp_unsk_`sector'_2 = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg_gdp") ("gdp_unsk_`sector'") (`reg_gdp_unsk_`sector'_2')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui reg ln_avg_skilled_income_`sector' ln_prod_`sector' ln_gdp if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_prod_sk_`sector'_2 = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg_gdp") ("prod_sk_`sector'") (`reg_prod_sk_`sector'_2')
		
		** Low skilled
		qui reg ln_avg_unskilled_income_`sector' ln_prod_`sector' ln_gdp if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_prod_unsk_`sector'_2 = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg_gdp") ("prod_unsk_`sector'") (`reg_prod_unsk_`sector'_2')
		
	}
	
	
	/*===================================================================================================
	* 2.1.7 - Mean regression + Total GDP * Unskilled rate
	===================================================================================================*/
	
	* GDP-Activity
	*****************
	qui reg ln_active_population ln_gdp iteration if year >= $min_year & year <= $last_year & country == "`country'"
	loc reg_gdp_emp_3 = _b[ln_gdp]
	post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg_iter") ("gdp_activity") (`reg_gdp_emp_3')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui reg ln_skilled_workers_`sector' ln_gdp`sector' iteration if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_gdp_sk_`sector'_3 = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg_iter") ("gdp_sk_`sector'") (`reg_gdp_sk_`sector'_3')
		
		** Low skilled
		qui reg ln_unskilled_workers_`sector' ln_gdp`sector' iteration if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_gdp_unsk_`sector'_3 = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg_iter") ("gdp_unsk_`sector'") (`reg_gdp_unsk_`sector'_3')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** High skilled
		qui reg ln_avg_skilled_income_`sector' ln_prod_`sector' iteration if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_prod_sk_`sector'_3 = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg_iter") ("prod_sk_`sector'") (`reg_prod_sk_`sector'_3')
		
		** Low skilled
		qui reg ln_avg_unskilled_income_`sector' ln_prod_`sector' iteration if year >= $min_year & year <= $last_year & country == "`country'"
		loc reg_prod_unsk_`sector'_3 = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("$min_year - $last_year") ("reg_iter") ("prod_unsk_`sector'") (`reg_prod_unsk_`sector'_3')
		
	}


postclose `regressions'
use `aux', clear
compress

replace Period = "Long" if Period == "_period1"

sort Country Period Year Model Elasticity
save "$path_mpo\elasticities_IND.dta", replace
save "$path_mpo\elasticities_IND_${version}.dta", replace
export excel using "$path_mpo\input_MASTER.xlsx", sheet("Elasticities IND") sheetreplace firstrow(variables)

/*===================================================================================================
	- END
===================================================================================================*/