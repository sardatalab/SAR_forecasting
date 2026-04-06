
/*===================================================================================================
Project:			Microsimulations Inputs from Households' Surveys, PPP
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		10/23/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  4/7/2025
===================================================================================================*/

drop _all

/*===================================================================================================
 	0 - SETTING
===================================================================================================*/

* Set up postfile for results
tempname mypost
tempfile myresults
postfile `mypost' str12(Country) Year str40(Indicator) Value using `myresults', replace


/*===================================================================================================
 	1 - HOUSEHOLDS SURVEYS DATA
===================================================================================================*/

foreach country of global countries_hhss { // Open loop countries
	
	foreach year of numlist ${init_year_hhss} / ${end_year_hhss} { // Open loop year
		
		if !inlist("`country'`year'","MDV2009","MDV2016","MDV2019") continue
		else {
		
		
		/*===========================================================================================
			1.1 - Loading the data
		===========================================================================================*/
		
		
		* Support module - CPIs and PPPs
		cap dlw, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v${cpi_version}_M) filename(Final_CPI_PPP_to_be_used.dta)
		keep if code == "`country'" & year == `year'
		keep code year cpi${cpi_base} icp${cpi_base}
		rename code countrycode
		tempfile dlwcpi
		save `dlwcpi', replace
		
		
		* SARMD modules - IND LBR INC
		local modules "IND LBR INC"
		foreach m of local modules {
			cap dlw, count("`country'") y(`year') t(sarmd) mod(`m') verm(02) vera(01) clear 
			if !_rc {
				di in red "Module `m' for `country' `year' loaded in datalibweb"
				tempfile `m'
				save ``m'', replace
			}
			if _rc {
				di in red "Module `m' for `country' `year' NOT loaded in datalibweb"
				continue
			}		
		}
		
		
		* Merge
		use `IND'
		merge 1:1 hhid pid using `LBR', nogen keep(1 3)
		cap tostring idp_org if "`country'`year'" == "MDV2019"
		merge 1:1 hhid pid using `INC', nogen keep(1 3)
		merge m:1 countrycode year using `dlwcpi', nogen keep(1 3)

		
		* Defining population of reference 
		cap drop sample
		qui gen sample = age > 14 & age != .

		
		* Informality classification - decided with the PE
		cap rename  lstatus_year lstatus_year_orig
		gen     lstatus_year = lstatus
		
		cap rename occup_year occup_year_orig
		qui sum occup_year_orig
		if r(N) == 0 gen occup_year = occup
		else gen occup_year = occup_year_orig
		
		
		* We are using informality here instead of skills
		qui cap drop informal
		qui gen informal = .
		replace informal = socialsec == 0 if empstat == 1
		replace informal = educat4 != 4 if educat4 != . & !inlist(empstat,1,.) & lstatus == 1
		replace informal = . if occup_year == . & educat4 == .

	
		* public job_status
		rename ocusec_year ocusec_year_orig
		qui sum ocusec_year_orig
		if r(N) == 0 gen ocusec_year = ocusec
		else gen ocusec_year = ocusec_year_orig
		label values ocusec ocusec_year ocusec_year_orig ocusec

		gen     public_job = 0 if lstatus == 1 & welfare != .
		replace public_job = 1 if lstatus == 1 & welfare != . & ocusec_year == 1

		
		* Sector main occupation
		/* 1 "Agriculture, Hunting, Fishing, etc." 2 "Mining" 3 "Manufacturing" 4 "Public Utility Services" 5 "Construction" 6 "Commerce" 7 "Transport and Communications" 8 "Financial and Business Services" 9 "Public Administration" 10 "Others */
		cap rename industrycat10_year industrycat10_year_orig
		qui sum industrycat10_year_orig
		if r(N) == 0 recode industrycat10 (1=1 "Agriculture") (2 3 4 5 =2 "Industry") (6 7 8 9 10 =3 "Services") , gen(sector_3)
		else qui recode industrycat10_year (1=1 "Agriculture") (2 3 4 5 =2 "Industry") (6 7 8 9 10 =3 "Services") , gen(sector_3)
		
		note: by definiton the public job is part of formal services sector
		replace sector_3  = 3 if !inlist(sector_3, 3) & public_job ==1 & sector_3!= .
		

		* Labor income - skilled/unskilled by sector and total
		qui gen ip_ppp = ip / cpi${cpi_base} / icp${cpi_base} // Labor income main activity ppp
		for any 1 2 3: qui gen ip_inf_X 	 = ip_ppp if sample == 1 & lstatus_year == 1 & sector_3 == X & informal == 1
		for any 1 2 3: qui gen ip_for_X = ip_ppp if sample == 1 & lstatus_year == 1 & sector_3 == X & informal == 0
		qui gen ip_total = ip_ppp if sample == 1 & lstatus_year == 1 
		qui gen ip_inf 	 = ip_ppp if sample == 1 & lstatus_year == 1 & informal == 1 
		qui gen ip_for  = ip_ppp if sample == 1 & lstatus_year == 1 & informal == 0

		
		* Number of workers - skilled/unskilled by sector
		for any 1 2 3: qui gen emp_inf_X 	= (sample == 1 & lstatus_year == 1 & sector_3 == X & informal == 1)
		for any 1 2 3: qui gen emp_for_X 	= (sample == 1 & lstatus_year == 1 & sector_3 == X & informal == 0)

		
		/*===========================================================================================
			1.2 - Estimations
		===========================================================================================*/
		
		
		** Number of workers

		* Total population
		qui sum weight [w=weight]
		local pop = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Total population") (`pop')

		* Working age population
		qui sum sample [w=weight] if sample == 1
		local wap = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Working age population") (`wap')

		* Active population
		qui sum sample [w=weight] if inlist(lstatus_year,1,2) & sample == 1
		local active = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Active population") (`active')

		* Inactive population
		qui sum sample [w=weight] if lstatus_year == 3 & sample == 1
		local inactive = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Inactive population") (`inactive')

		* Workers
		qui sum sample [w=weight] if lstatus_year == 1 & sample == 1
		local employed = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Working population") (`employed')

		* Unemployed
		qui sum sample [w=weight] if lstatus_year == 2 & sample == 1 
		local unemployed = `r(sum_w)' / 1000000
		post `mypost' ("`country'") (`year') ("Unemployed population") (`unemployed')

		* Sectoral employment
		forvalues i = 1 / 3 {

			* Informal
			qui sum sample [w=weight] if emp_inf_`i' == 1 & sample == 1 
			local emp_inf_`i' = `r(sum_w)' / 1000000
			post `mypost' ("`country'") (`year') ("Informal workers `i'") (`emp_inf_`i'')

			* Formal
			qui sum sample [w=weight] if emp_for_`i' == 1 & sample == 1 
			local emp_for_`i' = `r(sum_w)' / 1000000
			post `mypost' ("`country'") (`year') ("Formal workers `i'") (`emp_for_`i'')
		}


		** Labor income (avg)

		* Total
		qui sum ip_total [w=weight]
		local iptot = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. income") (`iptot')
		
		* Skilled/Unskilled
		qui sum ip_inf [w=weight] 
		local ip_inf = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. informal income") (`ip_inf')

		qui sum ip_for [w=weight] 
		local ip_for = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. formal income") (`ip_for')

		* Sectoral 
		forvalues i = 1 / 3 {
			
			* Skilled
			qui sum ip_inf_`i' [w=weight]
			local ip_inf_`i' = `r(mean)'
			post `mypost' ("`country'") (`year') ("Avg. Informal income `i'") (`ip_inf_`i'')
					
			* Unskilled
			qui sum ip_for_`i' [w=weight] 
			local ip_for_`i' = `r(mean)'
			post `mypost' ("`country'") (`year') ("Avg. Formal income `i'") (`ip_for_`i'')
		}

		 di in red "`country' - `year' finished successfully"
	
		}
		
	} // Close loop year
	
} // Close loop countries


postclose `mypost'
use  `myresults', clear

compress
save "$path_mpo\inputs_hhss_inf.dta", replace
export excel using "$path_mpo/$input_master", sheet("input_hhss_inf") sheetreplace firstrow(variables)


/*===================================================================================================
 	2 - MPO DATA
===================================================================================================*/

* Loading the MPO data
use "$povmod", clear

* Keep only countries of interest
keep if inlist(countrycode,"AFG","BGD","BTN","IND","MDV","NPL","PAK","LKA") 

* Keep last version
tab date
gen date1=date(date,"MDY")
egen datem= max(date1)
keep if date1 == datem
tab date

* Keep variables of interest
keep year countrycode pop privconstant gdpconstant agriconstant indusconstant servconstant

ren *constant Value*
ren pop Valuepop

reshape long Value, i(country year) j(Indicator) string
ren (countrycode year) (Country Year)

order Country Year Indicator Value
sort Country Year Indicator Value

tempfile macrodata
save `macrodata', replace


/*===================================================================================================
 	3 - ELASTICITIES INPUTS
===================================================================================================*/

use "$path_mpo\inputs_hhss_inf.dta", clear
append using `macrodata'
sort Country Year Indicator
save "$path_mpo/$input_hhss_e_inf", replace

/*===================================================================================================
	- END
===================================================================================================*/
