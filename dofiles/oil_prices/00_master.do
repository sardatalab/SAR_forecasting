
/*===================================================================================================
Project:			Iran's Conflict Distributional Impact
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		3/24/2026

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  3/24/2026
===================================================================================================*/

drop _all
version 17.0


/*=================================================================================================*/
**# 1. Setting
/*=================================================================================================*/

* Globals for paths
gl microsims_dir	"C:\Users\wb587758\WBG\SARDATALAB - Documents\Microsimulations"
gl path 			"${microsims_dir}\AM2026"
gl data_baseline	"${microsims_dir}\1_ST_working_folder\AM2026"
gl data_conflict	"${microsims_dir}\1_ST_working_folder\AM2026"
gl food_share 		"${path}\food_vectors_SAR"
gl dos 				"${microsims_dir}\0_SAR_forecasting\dofiles\oil_prices"
gl input_baseline 	"${path}\Oil prices\input\compiled_baseline_MPOweights"
gl input_conflict 	"${path}\Oil prices\input\compiled_2026conflict_MPOweights"


* Other globals
gl version 		"OCT_26_2026"
gl countries 	"BGD BTN IND LKA MDV NPL" //BGD BTN IND LKA MDV NPL "  //  // LKA doesn't have a baseline for now since we moved to S2S, and BTN model is yet to be defined
gl v_oil = ((87.02/72.74)-1)*100 //West Texas Intermediate Spot Average Q3/Q1 2026 


// Previous note from Kelly:  Projected growth in oil prices for Q1 and Q2 of 2026 in Feb report (56.14), for March (78.58) and projected new price from Global assumptions (94). - https://www.eia.gov/outlooks/steo/report/us_oil.php, consulted on 03-17-2026, macro updated on 03-24-2026.
gl out_sim "${path}\Oil prices\output\compiled_sim_${version}"
gl out "${path}\Oil prices\output\SAR_Iran_conflict_${version}.xlsx"
gl out_mat "${path}\Oil prices\output\deco_matrix.xlsx"

cd "${dos}"


/*=================================================================================================*/
**# 2. Run the project
/*=================================================================================================*/

* 1. Transform Microsimulated Conflict data
	run "01_conflict_data.do"

* 2. Transform Microsimulated Baseline data
	run "02_preconflict_data.do"

* 3. Apply inflation effects
	run "03_inflation_impacts.do"

* 4. Vectors of income components
	run "04_components.do"

* 5. Shapley decomposition
	run "05_shapley_adecomp.do"
	
* 6. Profiles
	*run "06_profiles.do" // Not finished
