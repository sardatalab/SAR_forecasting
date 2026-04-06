
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
		
		if !inlist("`country'`year'","AFG2016","AFG2019") /// AFG2007 AFG2011 AFG2013
		 & !inlist("`country'`year'","BGD2005","BGD2010","BGD2016","BGD2022") /// BGD2000  & !inlist("`country'`year'","BTN2022") /// BTN2003 BTN2007 BTN2012 BTN2017 & !inlist("`country'`year'","IND2004","IND2009","IND2011") /// 
		 & !inlist("`country'`year'","MDV2009","MDV2016","MDV2019") /// MDV2002 MDV2009 MDV2016 
		 & !inlist("`country'`year'","NPL2022") /// NPL2003 NPL2010
		 & !inlist("`country'`year'","PAK2018") /// PAK2004 PAK2005 PAK2007 PAK2010 PAK2011 PAK2013 PAK2015
		 & !inlist("`country'`year'","LKA2006","LKA2009","LKA2012","LKA2016","LKA2019") /// LKA2002
		 continue
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
			if "`country'" == "MDV" cap dlw, count("`country'") y(`year') t(sarmd) mod(`m') verm(02) vera(01) clear 
			else cap dlw, count("`country'") y(`year') t(sarmd) mod(`m') clear 
			if !_rc {
				di in red "Module `m' for `country' `year' loaded in datalibweb"
				cap drop __000000 // NPL INC has this variable and it's creating issues with the merge
				tempfile `m'
				save ``m'', replace
			}
			if _rc {
				di in red "Module `m' for `country' `year' NOT loaded in datalibweb"
				continue
			}		
		}
		
		/*if "`country'`year'" == "BGD2022" {
			cap dlw, count("`country'") y(`year') t(sarmd) mod(INC) clear 
			di in red "Module `m' for `country' `year' loaded in datalibweb"
			tempfile INC
			save `INC', replace
			
		}*/
		
		
		* Merge
		use `IND'
		merge 1:1 hhid pid using `LBR', nogen keep(1 3)
		cap tostring idp_org if "`country'`year'" == "MDV2019"
		/*if "`country'`year'" == "BGD2022"*/ merge 1:1 hhid pid using `INC', nogen keep(1 3)
		merge m:1 countrycode year using `dlwcpi', nogen keep(1 3)

		
		* Defining population of reference 
		cap drop sample
		qui gen sample = age > 14 & age != .
		
		/* Spatial deflation fo wage in BGD 2022 // This is temporary
		
		if "`country'`year'" == "BGD2022" {

			sum   zu_cbn [aw=wgt] 
			local mean_nat = r(mean)
			
			sum   wage [aw=wgt] 
			local avg = r(mean)

			gen wage_adj = wage*`mean_nat'/zu_cbn
			sum wage_adj [aw=wgt] 
			local avg2 = r(mean)
			replace wage = wage_adj*`avg'/`avg2'
			drop wage_adj
		
		}*/
		
		if "`country'`year'" == "NPL2022" { // Needs adjustment in the harmonizaton

			cap drop lstatus
			gen lstatus = 1 if q09_02 == 1 | q09_03 == 1 | q09_04 == 1 | q09_05 == 1 | q09_07 == 1 
			replace lstatus = 2 if (q09_18 == 1 & inrange(q09_20,1,11)) | (q09_19 == 1 & inlist(q09_22,1,2)) 
			replace  lstatus  = 3 if (q09_18 == 1 & !inrange(q09_20,1,11)) | (q09_18 == 2 & (q09_19 == 2 | (q09_19 == 1 & !inlist(q09_22,1,2))))
		
		}

		
		* Skill/Unskilled classification
		* Important!!! check this definition for all countries
		/*Following the ILO skill level classification[1], we classify workers into high-skilled and low-skilled. Workers in occupations such as Managers (1), Professionals (2), and Technicians and Associate professionals (3) correspond to "High-skilled" workers, whilst workers in Elementary Occupations (9) are "low-skilled." Given the diverse nature of the intermediate categories of this classification (Clerical support (4), Service and Sales (6), Skilled Agricultural, Forestry and Fisheries (6), Craft and Related Trades (7), and Plant and Machine Operators, and Assembler (8)), we added a layer to the high/low skill classification by using educational attainment and considering those with complete secondary and above as "high-skilled", and "low-skilled" otherwise. This is regardless of the workers' economic activity sector (agriculture, industry, services). Armed forces are excluded from the microsimulation model and, hence, from this classification. The table below summarizes the skill-level classification used.*/
		cap rename  lstatus_year lstatus_year_orig
		gen     lstatus_year = lstatus
		replace lstatus_year = 1 if  !inlist(ip,0,.) & "`country'`year'" == "BGD2022"
		
		cap rename occup_year occup_year_orig
		qui sum occup_year_orig
		if r(N) == 0 gen occup_year = occup
		else gen occup_year = occup_year_orig
		
		qui cap drop skilled
		qui gen skilled = .
		replace skilled = 1 if inrange(occup_year,1,3) 	| (inlist(occup_year,4,5,6,7,8,.) & inlist(educat7,5,6,7))
		replace skilled = 0 if occup_year==9 			| (inlist(occup_year,4,5,6,7,8,.) & !inlist(educat7,5,6,7))
		replace skilled = 0 if inrange(occup_year,4,8) 	& educat7 == .
		replace skilled = . if occup_year == . & educat7 == .

		
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
		if inlist("`country'","BGD","NPL") qui gen ip_ppp = (ip/12) / cpi${cpi_base} / icp${cpi_base} // Labor income main activity ppp
		else 					qui gen ip_ppp = ip / cpi${cpi_base} / icp${cpi_base} 
		
		for any 1 2 3: qui gen ip_sk_X 	 = ip_ppp if sample == 1 & lstatus_year == 1 & sector_3 == X & sk == 1
		for any 1 2 3: qui gen ip_unsk_X = ip_ppp if sample == 1 & lstatus_year == 1 & sector_3 == X & sk == 0
		qui gen ip_total = ip_ppp if sample == 1 & lstatus_year == 1 
		qui gen ip_sk 	 = ip_ppp if sample == 1 & lstatus_year == 1 & sk == 1 
		qui gen ip_unsk  = ip_ppp if sample == 1 & lstatus_year == 1 & sk == 0

		
		* Number of workers - skilled/unskilled by sector
		for any 1 2 3: qui gen emp_sk_X 	= (sample == 1 & lstatus_year == 1 & sector_3 == X & sk == 1)
		for any 1 2 3: qui gen emp_unsk_X 	= (sample == 1 & lstatus_year == 1 & sector_3 == X & sk == 0)

		
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

			* Skilled
			qui sum sample [w=weight] if emp_sk_`i' == 1 & sample == 1 
			local emp_sk_`i' = `r(sum_w)' / 1000000
			post `mypost' ("`country'") (`year') ("Skilled workers `i'") (`emp_sk_`i'')

			* Unskilled
			qui sum sample [w=weight] if emp_unsk_`i' == 1 & sample == 1 
			local emp_unsk_`i' = `r(sum_w)' / 1000000
			post `mypost' ("`country'") (`year') ("Unskilled workers `i'") (`emp_unsk_`i'')
		}


		** Labor income (avg)

		* Total
		qui sum ip_total [w=weight]
		local iptot = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. income") (`iptot')
		
		* Skilled/Unskilled
		qui sum ip_sk [w=weight] 
		local ip_sk = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. skilled income") (`ip_sk')

		qui sum ip_unsk [w=weight] 
		local ip_unsk = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. unskilled income") (`ip_unsk')

		* Sectoral 
		forvalues i = 1 / 3 {
			
			* Skilled
			qui sum ip_sk_`i' [w=weight]
			local ip_sk_`i' = `r(mean)'
			post `mypost' ("`country'") (`year') ("Avg. Skilled income `i'") (`ip_sk_`i'')
					
			* Unskilled
			qui sum ip_unsk_`i' [w=weight] 
			local ip_unsk_`i' = `r(mean)'
			post `mypost' ("`country'") (`year') ("Avg. Unskilled income `i'") (`ip_unsk_`i'')
		}

		 di in red "`country' - `year' finished successfully"
	
		}
		
	} // Close loop year
	
} // Close loop countries


postclose `mypost'
use  `myresults', clear

compress
save "$path_mpo\inputs_hhss.dta", replace
export excel using "$path_mpo/$input_master", sheet("input_hhss") sheetreplace firstrow(variables)


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

use "$path_mpo\inputs_hhss.dta", clear
append using `macrodata'
sort Country Year Indicator
save "$path_mpo/$input_hhss_e", replace

/*===================================================================================================
	- END
===================================================================================================*/
