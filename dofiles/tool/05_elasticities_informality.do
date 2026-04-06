
/*===================================================================================================
Project:			Elasticities sets for Microsimulation Tool
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		02/25/2022

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  01/21/2025 
===================================================================================================*/

drop _all

/*===================================================================================================
 	0 - SETTING
===================================================================================================*/

* Set up postfile for results
tempname regressions
tempfile aux
postfile `regressions' str3(Country) str10(Period) str11(Year) str20(Model) str80(Elasticity) Value using `aux', replace

local n : word count $countries

/*===================================================================================================
 	1 - DATA FILE AND VARIABLES
===================================================================================================*/

use "$path_mpo/$input_hhss_e_inf", clear

replace Indicator = subinstr(Indicator," ","_",.)
replace Indicator = subinstr(Indicator,".","",.)

reshape wide Value, i(Country Year) j(Indicator) string

ren Value* *
ren *, lower
ren agri gdp1
ren indus gdp2
ren serv gdp3

drop if active_population == . | gdp == . 

ren *informal* *inf*
ren *formal* *for*

* Total of workers by sector
for any 1 2 3 : egen workers_X = rowtotal(for_workers_X inf_workers_X)

* Total of workers by informality
for any for inf : egen workers_X = rowtotal(X_workers_1 X_workers_2 X_workers_3)

* Total of workers
egen workers = rowtotal(workers_for workers_inf)

* informal rate
gen inf = workers_inf / workers

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
for any 1 2 3 : gen elas_gdp_inf_X = growth_inf_workers_X / growth_gdpX
for any 1 2 3 : gen elas_gdp_for_X = growth_for_workers_X / growth_gdpX
gen elas_gdp_emp = growth_active_population / growth_gdp

* Annual elasticities income
for any 1 2 3 : gen elas_prod_for_X = growth_avg_for_income_X / growth_prod_X
for any 1 2 3 : gen elas_prod_inf_X = growth_avg_inf_income_X / growth_prod_X

* Iteration variables ln_gdp * informality rate
gen iteration = ln_gdp * inf

* Missing variables
for any elas_gdp_emp_1_99 elas_gdp_emp_1_99_imp: gen X = .
local sectors "1 2 3"
foreach s of local sectors {
	qui gen elas_gdp_for_`s'_1_99 = .
	qui gen elas_gdp_inf_`s'_1_99 = .
	qui gen elas_prod_for_`s'_1_99 = .
	qui gen elas_prod_inf_`s'_1_99 = .
	
	qui gen elas_gdp_for_`s'_1_99_imp = .
	qui gen elas_gdp_inf_`s'_1_99_imp = .
	qui gen elas_prod_for_`s'_1_99_imp = .
	qui gen elas_prod_inf_`s'_1_99_imp = .
}

* Generating annual elasticites data
preserve 
	keep country year elas_*
	reshape long elas_, i(country year) j(elas) string
	drop if elas_==.
	replace elas = "gdp_activity" if elas == "gdp_emp"
	export excel using "$path_mpo\input_MASTER.xlsx", sheet("Elasticities by year, Inf") sheetreplace firstrow(variables)
restore


/*===================================================================================================
* 	2 - ELASTICITIES
===================================================================================================*/

forvalues i = 1/`n' {
	local country 	: word `i' of $countries
    local min 		: word `i' of $min_year
	local last 		: word `i' of $last_year
	
	di in red "`country'"
	
	/*===================================================================================================
	* 2.1 - Minimum year to last year available
	===================================================================================================*/
	
	di in red "Period `min' - `last'"
	
	/*===================================================================================================
	* 2.1.1 - Simple averages
	===================================================================================================*/
	
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp if year >= `min' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp = r(mean)
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg") ("gdp_activity") (`av_elas_gdp_emp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui sum elas_gdp_for_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'')
		
		** informal
		qui sum elas_gdp_inf_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui sum elas_prod_for_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'')
		
		** informal
		qui sum elas_prod_inf_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'')
		
	}
	
	
	/*===================================================================================================
	* 2.1.2 - Averages without outliers (1%-99%)
	===================================================================================================*/
	
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp if year >= `min' & year <= `last' & country == "`country'", d
	qui replace elas_gdp_emp_1_99 = elas_gdp_emp if year >= `min' & year <= `last' & country == "`country'" & elas_gdp_emp > r(p1) & elas_gdp_emp < r(p99)
	qui sum elas_gdp_emp_1_99 if year >= `min' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp_1_99 = r(mean)
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99") ("gdp_activity") (`av_elas_gdp_emp_1_99')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui sum elas_gdp_for_`sector' if year >= `min' & year <= `last' & country == "`country'", d
		qui replace elas_gdp_for_`sector'_1_99 = elas_gdp_for_`sector' if year >= `min' & year <= `last' & country == "`country'" &elas_gdp_for_`sector' > r(p1) & elas_gdp_for_`sector' < r(p99)
		qui sum elas_gdp_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'_1_99')
		
		** informal
		qui sum elas_gdp_inf_`sector' if year >= `min' & year <= `last' & country == "`country'", d
		qui replace elas_gdp_inf_`sector'_1_99 = elas_gdp_inf_`sector' if year >= `min' & year <= `last' & country == "`country'" & elas_gdp_inf_`sector' > r(p1) & elas_gdp_inf_`sector' < r(p99)
		qui sum elas_gdp_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'_1_99')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui sum elas_prod_for_`sector' if year >= `min' & year <= `last' & country == "`country'", d
		qui replace elas_prod_for_`sector'_1_99 = elas_prod_for_`sector' if year >= `min' & year <= `last' & country == "`country'" & elas_prod_for_`sector' > r(p1) & elas_prod_for_`sector' < r(p99)
		qui sum elas_prod_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'_1_99')
		
		** informal
		qui sum elas_prod_inf_`sector' if year >= `min' & year <= `last' & country == "`country'", d
		qui replace elas_prod_inf_`sector'_1_99 = elas_prod_inf_`sector' if year >= `min' & year <= `last' & country == "`country'" & elas_prod_inf_`sector' > r(p1) & elas_prod_inf_`sector' < r(p99)
		qui sum elas_prod_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'_1_99')
		
	}
	
	
	/*===================================================================================================
	* 2.1.3 - Averages with imputed outliers (1%-99% using mean)
	===================================================================================================*/
		
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp_1_99 if year >= `min' & year <= `last' & country == "`country'", d
	loc av_elas_gdp_emp_1_99 = r(p50)
	qui replace elas_gdp_emp_1_99_imp = elas_gdp_emp_1_99 if year >= `min' & year <= `last' & country == "`country'"
	qui replace elas_gdp_emp_1_99_imp = `av_elas_gdp_emp_1_99' if elas_gdp_emp_1_99_imp == . & elas_gdp_emp != . & year >= `min' & year <= `last' & country == "`country'"
	qui sum elas_gdp_emp_1_99_imp if year >= `min' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp_1_99_imp = r(mean)
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99_imp") ("gdp_activity") (`av_elas_gdp_emp_1_99_imp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui sum elas_gdp_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'", d
		loc avg_elas_gdp_for_`sector'_1_99 = r(p50)
		qui replace elas_gdp_for_`sector'_1_99_imp = elas_gdp_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		qui replace elas_gdp_for_`sector'_1_99_imp = `avg_elas_gdp_for_`sector'_1_99' if elas_gdp_for_`sector'_1_99_imp == . & elas_gdp_for_`sector' != . & year >= `min' & year <= `last' & country == "`country'"
		qui sum elas_gdp_for_`sector'_1_99_imp if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99_imp") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'_1_99_imp')
		
		** informal
		qui sum elas_gdp_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'", d
		loc avg_elas_gdp_inf_`sector'_1_99 = r(p50)
		qui replace elas_gdp_inf_`sector'_1_99_imp = elas_gdp_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		qui replace elas_gdp_inf_`sector'_1_99_imp = `avg_elas_gdp_inf_`sector'_1_99' if elas_gdp_inf_`sector'_1_99_imp == . & elas_gdp_inf_`sector' != . & year >= `min' & year <= `last' & country == "`country'"
		qui sum elas_gdp_inf_`sector'_1_99_imp if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99_imp") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'_1_99_imp')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui sum elas_prod_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'", d
		loc avg_elas_prod_for_`sector'_1_99 = r(p50)
		qui replace elas_prod_for_`sector'_1_99_imp = elas_prod_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		qui replace elas_prod_for_`sector'_1_99_imp = `avg_elas_prod_for_`sector'_1_99' if elas_prod_for_`sector'_1_99_imp == . & elas_prod_for_`sector' != . & year >= `min' & year <= `last' & country == "`country'"
		qui sum elas_prod_for_`sector'_1_99_imp if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99_imp") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'_1_99')
		
		** informal
		qui sum elas_prod_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'", d
		loc avg_elas_prod_inf_`sector'_1_99 = r(p50)
		qui replace elas_prod_inf_`sector'_1_99_imp = elas_prod_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		qui replace elas_prod_inf_`sector'_1_99_imp = `avg_elas_prod_inf_`sector'_1_99' if elas_prod_inf_`sector'_1_99_imp == . & elas_prod_inf_`sector' != . & year >= `min' & year <= `last' & country == "`country'"
		qui sum elas_prod_inf_`sector'_1_99_imp if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99_imp") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'_1_99_imp')
		
	}
	
	
	/*===================================================================================================
	* 2.1.4 - Mean regression
	===================================================================================================*/
	
	* GDP-Activity
	*****************
	qui reg ln_active_population ln_gdp if year >= `min' & year <= `last' & country == "`country'"
	loc reg_gdp_emp = _b[ln_gdp]
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg") ("gdp_activity") (`reg_gdp_emp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui reg ln_for_workers_`sector' ln_gdp`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector' = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg") ("gdp_for_`sector'") (`reg_gdp_for_`sector'')
		
		** informal
		qui reg ln_inf_workers_`sector' ln_gdp`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector' = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui reg ln_avg_for_income_`sector' ln_prod_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector' = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg") ("prod_for_`sector'") (`reg_prod_for_`sector'')
		
		** informal
		qui reg ln_avg_inf_income_`sector' ln_prod_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector' = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg") ("prod_inf_`sector'") (`reg_prod_inf_`sector'')
		
	}
	
	
	/*===================================================================================================
	* 2.1.5 - Median regression
	===================================================================================================*/
	
	if !inlist("`country'","BGD","LKA","MDV") {
		
		* GDP-Activity
		*****************
		qui qreg ln_active_population ln_gdp if year >= `min' & year <= `last' & country == "`country'", vce(robust)
		loc med_reg_gdp_emp = _b[ln_gdp]
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("med_reg") ("gdp_activity") (`med_reg_gdp_emp')
		
		* Sectoral GDP-Sectoral Workers 
		**********************************
		local sectors "1 2 3"
		foreach sector of local sectors {
			
			** formal
			qui qreg ln_for_workers_`sector' ln_gdp`sector' if year >= `min' & year <= `last' & country == "`country'"
			loc med_reg_gdp_for_`sector' = _b[ln_gdp`sector']
			post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("med_reg") ("gdp_for_`sector'") (`med_reg_gdp_for_`sector'')
			
			** informal
			qui qreg ln_inf_workers_`sector' ln_gdp`sector' if year >= `min' & year <= `last' & country == "`country'"
			loc med_reg_gdp_inf_`sector' = _b[ln_gdp`sector']
			post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("med_reg") ("gdp_inf_`sector'") (`med_reg_gdp_inf_`sector'')
			
		}
		
		* Sectoral Productivity-Sectoral Income 
		******************************************
		local sectors "1 2 3"
		foreach sector of local sectors {
			
			** formal
			qui qreg ln_avg_for_income_`sector' ln_prod_`sector' if year >= `min' & year <= `last' & country == "`country'"
			loc med_reg_prod_for_`sector' = _b[ln_prod_`sector']
			post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("med_reg") ("prod_for_`sector'") (`med_reg_prod_for_`sector'')
			
			** informal
			qui qreg ln_avg_inf_income_`sector' ln_prod_`sector' if year >= `min' & year <= `last' & country == "`country'"
			loc med_reg_prod_inf_`sector' = _b[ln_prod_`sector']
			post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("med_reg") ("prod_inf_`sector'") (`med_reg_prod_inf_`sector'')
			
		}
	}
	
	
	/*===================================================================================================
	* 2.1.6 - Mean regression + Total GDP
	===================================================================================================*/
	
	* GDP-Activity
	*****************
	qui reg ln_active_population ln_gdp if year >= `min' & year <= `last' & country == "`country'"
	loc reg_gdp_emp_2 = _b[ln_gdp]
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_gdp") ("gdp_activity") (`reg_gdp_emp_2')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui reg ln_for_workers_`sector' ln_gdp`sector' ln_gdp if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector'_2 = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_gdp") ("gdp_for_`sector'") (`reg_gdp_for_`sector'_2')
		
		** informal
		qui reg ln_inf_workers_`sector' ln_gdp`sector' ln_gdp if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector'_2 = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_gdp") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'_2')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui reg ln_avg_for_income_`sector' ln_prod_`sector' ln_gdp if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector'_2 = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_gdp") ("prod_for_`sector'") (`reg_prod_for_`sector'_2')
		
		** informal
		qui reg ln_avg_inf_income_`sector' ln_prod_`sector' ln_gdp if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector'_2 = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_gdp") ("prod_inf_`sector'") (`reg_prod_inf_`sector'_2')
		
	}
	
	
	/*===================================================================================================
	* 2.1.7 - Mean regression + Total GDP * informal rate
	===================================================================================================*/
	
	* GDP-Activity
	*****************
	qui reg ln_active_population ln_gdp iteration if year >= `min' & year <= `last' & country == "`country'"
	loc reg_gdp_emp_3 = _b[ln_gdp]
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_iter") ("gdp_activity") (`reg_gdp_emp_3')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui reg ln_for_workers_`sector' ln_gdp`sector' iteration if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector'_3 = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_iter") ("gdp_for_`sector'") (`reg_gdp_for_`sector'_3')
		
		** informal
		qui reg ln_inf_workers_`sector' ln_gdp`sector' iteration if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector'_3 = _b[ln_gdp`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_iter") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'_3')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "1 2 3"
	foreach sector of local sectors {
		
		** formal
		qui reg ln_avg_for_income_`sector' ln_prod_`sector' iteration if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector'_3 = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_iter") ("prod_for_`sector'") (`reg_prod_for_`sector'_3')
		
		** informal
		qui reg ln_avg_inf_income_`sector' ln_prod_`sector' iteration if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector'_3 = _b[ln_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_iter") ("prod_inf_`sector'") (`reg_prod_inf_`sector'_3')
		
	}
	
}

postclose `regressions'
use `aux', clear
compress

replace Period = "Long" if Period == "_period1"

sort Country Period Year Model Elasticity
save "$path_mpo\elasticities_inf.dta", replace
save "$path_mpo\elasticities_inf_${version}.dta", replace
export excel using "$path_mpo\input_MASTER.xlsx", sheet("Elasticities inf") sheetreplace firstrow(variables)

/*===================================================================================================
	- END
===================================================================================================*/