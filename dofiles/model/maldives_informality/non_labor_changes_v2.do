
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Change in Non-labor Income Maldives
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya
E-mail:				kmontoyamunoz@worldbank.org
Creation Date:		3/9/2026

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  3/9/2026
=====================================================================================================

NOTE: This dofile progressively deflates non-labor income components (cash transfers) using the information shared by the PE.

=====================================================================================================*/

* Disability - Equals inocct_m 
	
	* Check variable construction
	egen check = rowtotal(icct inocct_m inocct_nm itrane_ns), m
	compare check itrane // Perfect match
	drop check 
	
	
	* Gen hh original nominal variables
	bysort hhid: egen aux_disability = sum(inocct_m), m
	bysort hhid: egen aux_itrane = sum(itrane), m
	
	* Gen disability transfers share in all transfers
	gen sh_disability = aux_disability / aux_itrane
	replace sh_disability = 0 if sh_disability == .
	
	gen disability_s = sh_disability * h_transfers
	gen other_transfers_s = (1-sh_disability) * h_transfers
	
	* Affect new disability transfers factor
	ren (disability_s h_transfers_s) (disability_s_orig h_transfers_s_orig)
	if ${model} == 2020 gen disability_s = disability_s_orig * (1 + 0.013887933) 
	if ${model} == 2021 gen disability_s = disability_s_orig * (1 + 0.00841075) 
	if ${model} == 2022 gen disability_s = disability_s_orig * (1 + -0.014580468) 
	if ${model} == 2023 gen disability_s = disability_s_orig * (1 + 0.436088246) 
	if ${model} == 2024 gen disability_s = disability_s_orig * (1 + 0.416263391)
	if ${model} == 2025 gen disability_s = disability_s_orig * (1 + 0.36126541) 
	if ${model} == 2026 gen disability_s = disability_s_orig * (1 + 0.284212651) 
	if ${model} == 2027 gen disability_s = disability_s_orig * (1 + 0.231268122) 
	if ${model} == 2028 gen disability_s = disability_s_orig * (1 + 0.182774372) 
	
	* New transfers vector
	egen h_transfers_s = rowtotal(disability_s other_transfers_s), m
	drop aux_disability sh_disability other_transfers_s


* Single and Foster Parents - Separate treatment but both included in ICCT
	
	* Check variable construction
	egen check = rowtotal(RentOfGoodsAmnt_5 RentOfGoodsAmnt_6 RentOfGoodsAmnt_7 RentOfGoodsAmnt_8), m
	compare check icct // Perfect match
	drop check 
	
	* Gen hh original nominal variables
	egen aux_sing_parent = rowtotal(RentOfGoodsAmnt_5 RentOfGoodsAmnt_6), m
	bysort hhid: egen aux_sing_parent2 = sum(aux_sing_parent), m
	
	egen aux_fost_parent = rowtotal(RentOfGoodsAmnt_7 RentOfGoodsAmnt_8), m
	bysort hhid: egen aux_fost_parent2 = sum(aux_fost_parent), m
	
	* Gen each program share in all transfers
	gen sh_sing_parent = aux_sing_parent2 / aux_itrane
	replace sh_sing_parent = 0 if sh_sing_parent == .
	
	gen sh_fost_parent = aux_fost_parent2 / aux_itrane
	replace sh_fost_parent = 0 if sh_fost_parent == .
	
	* Original real values
	gen sing_parent_s = sh_sing_parent * h_transfers
	gen fost_parent_s = sh_fost_parent * h_transfers
	
	gen aux_sing_parent_s = -sing_parent_s
	gen aux_fost_parent_s = -fost_parent_s
	egen other_transfers_s = rowtotal(h_transfers_s aux_sing_parent_s aux_fost_parent_s), m
	
	ren (sing_parent_s fost_parent_s) (sing_parent_s_orig fost_parent_s_orig)
	
	* Modifying Single Parent Allowance
	
	if ${model} == 2020 gen sing_parent_s = sing_parent_s_orig * (1 + 0.013887933) 
	if ${model} == 2021 gen sing_parent_s = sing_parent_s_orig * (1 + 0.00841075) 
	if ${model} == 2022 gen sing_parent_s = sing_parent_s_orig * (1 + -0.014580468) 
	if ${model} == 2023 gen sing_parent_s = sing_parent_s_orig * (1 + -0.042607836) 
	if ${model} == 2024 gen sing_parent_s = sing_parent_s_orig * (1 + -0.055824406)
	if ${model} == 2025 gen sing_parent_s = sing_parent_s_orig * (1 + -0.092489727) 
	if ${model} == 2026 gen sing_parent_s = sing_parent_s_orig * (1 + 0.284212651) 
	if ${model} == 2027 gen sing_parent_s = sing_parent_s_orig * (1 + 0.231268122) 
	if ${model} == 2028 gen sing_parent_s = sing_parent_s_orig * (1 + 0.182774372) 

	* Modifying Foster Parent Allowance	
	
	if ${model} == 2020 gen fost_parent_s = fost_parent_s_orig * (1 + 0.013887933) 
	if ${model} == 2021 gen fost_parent_s = fost_parent_s_orig * (1 + 0.00841075) 
	if ${model} == 2022 gen fost_parent_s = fost_parent_s_orig * (1 + -0.014580468) 
	if ${model} == 2023 gen fost_parent_s = fost_parent_s_orig * (1 + -0.042607836) 
	if ${model} == 2024 gen fost_parent_s = fost_parent_s_orig * (1 + 2.14725198)
	if ${model} == 2025 gen fost_parent_s = fost_parent_s_orig * (1 + 2.025034244) 
	if ${model} == 2026 gen fost_parent_s = fost_parent_s_orig * (1 + 1.853805891) 
	if ${model} == 2027 gen fost_parent_s = fost_parent_s_orig * (1 + 1.736151381) 
	if ${model} == 2028 gen fost_parent_s = fost_parent_s_orig * (1 + 1.628387494) 
	
	* Putting all changes together
	ren h_transfers_s h_transfers_s_orig2
	egen h_transfers_s = rowtotal(sing_parent_s fost_parent_s other_transfers_s), m
	drop aux_sing_parent* aux_fost_parent* 
	

* Old age pension - Equals ijubi_ncon
	
	* Check variable construction
	egen check = rowtotal(ijubi_con ijubi_ncon), m
	compare check ijubi // Perfect match
	drop check 
	
	* Gen hh original nominal variables
	bysort hhid: egen pension_ncont = sum(ijubi_ncon), m
	bysort hhid: egen pension = sum(ijubi), m
	
	* Gen non-contributory pensions share in all pensions
	gen sh_pens_ncon = pension_ncont / pension
	gen pens_ncon_s = sh_pens_ncon * h_pensions_s
	gen pens_con_s = (1-sh_pens_ncon) * h_pensions_s
	
	* Affect new non-contributory pensions factor
	ren (pens_ncon_s h_pensions_s) (pens_ncon_s_orig h_pensions_s_orig)
	if ${model} == 2020 gen pens_ncon_s = pens_ncon_s_orig * (1 + 0.013887933) 
	if ${model} == 2021 gen pens_ncon_s = pens_ncon_s_orig * (1 + 0.00841075) 
	if ${model} == 2022 gen pens_ncon_s = pens_ncon_s_orig * (1 + -0.014580468) 
	if ${model} == 2023 gen pens_ncon_s = pens_ncon_s_orig * (1 + -0.042607836) 
	if ${model} == 2024 gen pens_ncon_s = pens_ncon_s_orig * (1 + -0.055824406)
	if ${model} == 2025 gen pens_ncon_s = pens_ncon_s_orig * (1 + -0.092489727) 
	if ${model} == 2026 gen pens_ncon_s = pens_ncon_s_orig * (1 + -0.143858233) 
	if ${model} == 2027 gen pens_ncon_s = pens_ncon_s_orig * (1 + -0.179154586) 
	if ${model} == 2028 gen pens_ncon_s = pens_ncon_s_orig * (1 + -0.211483752) 
	
	* New pensions vector
	egen h_pensions_s = rowtotal(pens_con_s pens_ncon_s), m
	