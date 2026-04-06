
* 1.3 - Temporary file
*************************
clear
loc country = "$country"
tempfile `country'

* 1.4 - Uploading the data for each year
*************************************
loc col_years = colsof(data)
forvalues i = 1/`col_years' {
	
	local year = data[1,`i']
	
	** 1.4.1 - Actual data
	*************************
	if data[2,`i'] == 0 {
		
		* Support module - CPIs and PPPs
		qui dlw, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v${cpi_version}_M) filename(Final_CPI_PPP_to_be_used.dta)
		keep if code == "${country}" & year == `year'
		keep code year cpi${ppp} icp${ppp}
		rename code countrycode
		tempfile dlwcpi
		save `dlwcpi', replace
				
		* SARMD modules - IND LBR INC
		local modules "IND LBR INC"
		foreach m of local modules {
			di in red "`m'"
			if "${country}" == "BGD" & `year' == 2016 & "`m'" == "IND" qui dlw, count("${country}") y(`year') t(sarmd) mod(`m') filename(BGD_2016_HIES_v01_M_v07_A_SARMD_IND.dta) clear nocpi
			else if "${country}" == "LKA" & inlist(`year',2009,2012) & "`m'" == "IND" qui dlw, count("${country}") y(`year') t(sarmd) mod(`m') filename(LKA_`year'_HIES_v01_M_v06_A_SARMD_IND.dta) clear nocpi
			else dlw, count("${country}") y(`year') t(sarmd) mod(`m') clear nocpi
			tempfile `m'
			save ``m'', replace	
		}
				
		* Merge
		use `IND'
		merge 1:1 hhid pid using `LBR', nogen keep(1 3)
		merge 1:1 hhid pid using `INC', nogen keep(1 3)
		merge m:1 countrycode year using `dlwcpi', nogen keep(1 3)
		

		** weight
		qui cap ren wgt fexp_s
		qui cap ren weight fexp_s
		
		* deflate welfare // Needs to be fixed in SARMD and dlw
		if "${country}`year'" == "BGD2022" {

			/*sum   zu_cbn [aw=fexp_s] 
			local mean_nat = r(mean)
			
			sum   welfare [aw=fexp_s] 
			local avg = r(mean)

			gen welfare_adj = welfare*`mean_nat'/zu_cbn
			sum welfare_adj [aw=fexp_s] 
			local avg2 = r(mean)
			replace welfare = welfare_adj*`avg'/`avg2'
			drop welfare_adj*/
			
			replace welfare = welfaredef
			
			replace pline_nat = pline_nat * (welfaredef / welfarenat)
		
		}
		
		if "${country}`year'" == "MDV2019" {
			
			replace pline_nat = pline_nat /12
		
		}
		
		* Preparing variables
		keep countrycode year hhid pid fexp_s welfare male urban age relationharm educat* hsize ipcf itf ip inp ila icap ijubi inla_otro itranp itrane renta_imp itranext_m itranext_nm itranint_m itranint_nm itran_ns cpi${ppp} icp${ppp} hogarsec empstat* lstatus* occup* industry* pline_nat socialsec
		
		** sample
		cap drop sample
		gen sample 		= age > 14 & age != .
		
		* Household size
		clonevar h_size = hsize
		
		* Household head
		qui gen h_head = relationharm == 1 if relationharm != .
		qui bysort hhid: egen n_heads = sum(h_head), m
		qui replace h_head = 0 if h_head == . & n_heads == 1
		drop n_heads
		
		** depen
		cap drop aux*
		cap drop depen
		qui egen aux = total((age < 15 | age > 64)), by(hhid)
		qui gen depen = aux/h_size 
		
		* convert income variables to ppp
		foreach incomevar of varlist welfare ila ijubi itranp itrane icap inla_otro renta_imp ipcf itf ip inp itranext_m itranext_nm itranint_m itranint_nm itran_ns {
			cap drop `incomevar'_ppp
			qui gen `incomevar'_ppp=`incomevar' / cpi${ppp} / icp${ppp} 
			*replace `incomevar'_ppp = `incomevar'_ppp / 12
			}
			
		* Foreign remittances
		egen itranext_ppp = rowtotal(itranext_m_ppp itranext_nm_ppp), m

		* Domestic remittances
		egen itranint_ppp = rowtotal(itranint_m_ppp itranint_nm_ppp), m
		
		** welfare_s
		ren welfare_ppp welfare_s
		
		** income
		ren ipcf_ppp pc_inc_s
						
		rename occup_year occup_year_orig
		qui sum occup_year_orig
		if r(N) == 0 gen occup_year = occup
		else gen occup_year = occup_year_orig
			
		* We are using informality here instead of skills
		qui cap drop informal_s
		qui gen informal_s = .
		replace informal_s = socialsec == 0 if empstat == 1
		replace informal_s = educat4 != 4 if educat4 != . & !inlist(empstat,1,.) & lstatus == 1
		replace informal_s = . if occup_year == . & educat4 == .
		
		
		** Economic sectors
		/* 1 "Agriculture, Hunting, Fishing, etc." 2 "Mining" 3 "Manufacturing" 4 "Public Utility Services" 5 "Construction" 6 "Commerce" 7 "Transport and Communications" 8 "Financial and Business Services" 9 "Public Administration" 10 "Others */
		local sectors_vars "industrycat10 industrycat10_2"
		foreach var of local sectors_vars {
			cap rename `var'_year `var'_year_orig
			qui sum `var'_year_orig
			if r(N) == 0 recode `var' (1=1 "Agriculture") (2 3 4 5 =2 "Industry") (6 7 8 9 10 =3 "Services") , gen(sector_`var')
			else qui recode `var'_year (1=1 "Agriculture") (2 3 4 5 =2 "Industry") (6 7 8 9 10 =3 "Services") , gen(sector_`var')
		}

		ren (sector_industrycat10 sector_industrycat10_2) (sect_main_s sect_secu)
		
		
		** occupation_s
		rename  lstatus_year lstatus_year_orig
		gen     lstatus_year = lstatus
		replace lstatus_year = 1 if !inlist(ip,0,.) & "${country}" == "BGD"
		qui gen active_s = inlist(lstatus_year,1,2) if lstatus_year != .
		
		gen emplyd_s	= lstatus == 1 if welfare != . & lstatus != . & sample == 1
		gen unemplyd_s 	= lstatus_year == 2 if welfare != . & inlist(lstatus_year,1,2) & sample == 1
 
		qui gen     occupation_s = .
		qui replace occupation_s = 0 if  active_s     == 0 
		qui replace occupation_s = 1 if  unemplyd_s   == 1  	
		qui replace occupation_s = 2 if  sect_main_s == 1 & emplyd_s == 1 & informal_s == 0
		qui replace occupation_s = 3 if  sect_main_s == 1 & emplyd_s == 1 & informal_s == 1
		qui replace occupation_s = 4 if  sect_main_s == 2 & emplyd_s == 1 & informal_s == 0
		qui replace occupation_s = 5 if  sect_main_s == 2 & emplyd_s == 1 & informal_s == 1
		qui replace occupation_s = 6 if  sect_main_s == 3 & emplyd_s == 1 & informal_s == 0
		qui replace occupation_s = 7 if  sect_main_s == 3 & emplyd_s == 1 & informal_s == 1
		
		gen formal_s = !informal_s if informal_s != . & sample == 1 & lstatus_year == 1 & sect_main_s != .
		
		** lai_s
		qui clonevar lai_m_s = ip_ppp
		qui clonevar lai_s_s = inp_ppp
		qui egen tot_lai_s = rowtotal(lai_m_s lai_s_s), missing
		qui replace tot_lai_s = lai_s_s if lai_m_s < 0
		
		** non-labor income
		qui gen capital_ppp  = icap_ppp
		qui gen pensions_ppp = ijubi_ppp
		qui gen otherinla_ppp = inla_otro_ppp
		qui gen remitt_ppp	= itranp_ppp
		qui gen int_remit_ppp = itranext_ppp
		qui gen dom_remit_ppp = itranint_ppp
		qui gen ns_remit_ppp = itran_ns_ppp
		qui gen transfers_ppp = itrane_ppp
		qui replace renta_imp_ppp = renta_imp_ppp / h_size
		
		local var "remitt int_remit dom_remit ns_remit pensions capital renta_imp otherinla transfers"
		foreach x of local var {
			qui egen     h_`x'_s = sum(`x'_ppp) if hogarsec != 1, by(hhid) //missing
			*qui replace  h_`x'_s = . if h_`x'_s == 0
		}


		** labor relationship
		local relation_vars "empstat empstat_2"
		foreach var of local relation_vars {
			rename `var'_year `var'_year_orig
			qui sum `var'_year_orig
			if r(N) == 0 gen `var'_year = `var'
			else gen `var'_year = `var'_year_orig
			label values `var'_year `var' `var'_year_orig `var'
		}
		
		gen salaried_s 	= empstat_year == 1 			if emplyd_s==1
		gen self_emp 	= inlist(empstat_year,3,4) 		if emplyd_s==1 
		gen unpaid 		= empstat_year == 2 			if emplyd_s==1

		gen salaried2 	= empstat_2_year == 1 			if emplyd_s==1
		gen self_emp2 	= inlist(empstat_2_year,3,4) 	if emplyd_s==1 
		gen unpaid2		= empstat_2_year == 2 			if emplyd_s==1
		
		qui gen     labor_rel = 1 if salaried_s	== 1
		qui replace labor_rel = 2 if self_emp 	== 1
		qui replace labor_rel = 3 if unpaid   	== 1
		qui replace labor_rel = 4 if unemplyd_s == 1
		
		* Saving temporal database
		qui compress
		if `year' == data[1,1] qui save ``country'', replace
		else {
			qui append using ``country''
			qui save ``country'', replace
		}
		
	}
	
	
	** 1.4.2 - Simulated data
	****************************
	if data[2,`i'] == 1 {
			
		if "${country}" == "BGD" qui use "${data_path}/${country}\Data/${country}_`year'_6s_dom_yes_int_no_inc_no_cons_no_matching_yes_st_yes.dta", clear
		
		else if "${country}" == "MDV" qui use "${data_path}/${country}\Data\Postcrisis_covidtransfers/${country}_`year'_6s_dom_no_int_no_inc_no_cons_no_matching_yes_st_yes.dta", clear
		
		*else if "${country}" == "MDV" qui use "${data_path}/${country}\Data/${country}_`year'_6s_dom_no_int_no_inc_no_cons_yes_matching_yes_st_yes.dta", clear

		di in red "${country} `year' loaded from simulations"
		
		* Preparing variables
		cap drop year
		qui gen year = `year'
		keep countrycode year hhid pid fexp_* sample welfare_* male urban age relationharm educat* h_size depen active* emplyd_s pc_inc_* poor*1 occupation_* lai_m_s lai_s_s tot_lai_* h_transfers* h_*remit* h_pensions* h_otherinla* h_capital* h_renta_imp* labor_rel salaried_s self_emp unpaid formal_s informal_s pline_nat cpi* icp*
		
		cap keep if welfare_s!=.
		
		if "${country}" == "MDV" {
			replace pline_nat = pline_nat /12
		}
		
		
		* Household head
		qui gen h_head = relationharm == 1 if relationharm != .
		qui bysort hhid: egen n_heads = sum(h_head), m
		qui replace h_head = 0 if h_head == . & n_heads == 1
		drop n_heads
		
		* Labor status
		cap drop emplyd_s
		cap drop unemplyd_s
		gen emplyd_s	= inrange(occupation_s,2,7)	if welfare_s != . & occupation_s != . & sample == 1
		gen unemplyd_s 	= occupation_s == 1  if welfare_s != . & inrange(occupation_s,1,7) & sample == 1
		
		
		* Adjusting non-labor income to make it comparable
		local nonlabor "transfers int_remit dom_remit ns_remit pensions capital otherinla renta_imp"
		foreach nli of local nonlabor  {
			qui bysort year hhid: egen aux_`nli' = sum(h_`nli'_s) if h_head != ., m
			qui replace h_`nli'_s = aux_`nli' 
			drop  aux_`nli' 
		}
		
		* Saving temporal database
		qui compress
		if `year' == data[1,1] qui save ``country'', replace
		else {
			qui cap append using ``country''
			qui save ``country'', replace
		}
	}
}
