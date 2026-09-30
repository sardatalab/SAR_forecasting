
/*========================================================================
Project:			Country-folders' creation
Institution:		World Bank - ESAPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		07/05/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date: 	07/22/2026
========================================================================*/

* NOTE: This dofile creates empty country folders in the two round folders' for MPOs microsimulations.

drop _all

* Globals
	gl mpo_version 	"SM2027" 					// Folder name in sharepoint
	gl prev_version "AM2026"
	gl sharep_path	"C:\Users\wb520054\WBG\SARDATALAB - Documents\Microsimulations"	// Change for your personal path
	gl countries	"BGD BTN IND MDV NPL LKA" 


* Round folder
	cap mkdir 	"${sharep_path}/${mpo_version}"
	cap mkdir 	"${sharep_path}/${mpo_version}\_inputs"

* Country-specific folders
	foreach country of global countries {
		cap mkdir 	"${sharep_path}/${mpo_version}/`country'"
	}

* Copy previous round tools

	** Master file and other main files
	cap copy "${sharep_path}/${prev_version}\_inputs\Data availability by country.xlsx" ///
			"${sharep_path}/${mpo_version}\_inputs\Data availability by country.xlsx"
	cap copy "${sharep_path}/${prev_version}\_inputs\input_MASTER.xlsx" ///
			"${sharep_path}/${mpo_version}\_inputs\input_MASTER.xlsx"
	cap copy "${sharep_path}/${prev_version}\_inputs\Microsimulation_Inputs_PROTO.xlsm" ///
			"${sharep_path}/${mpo_version}\_inputs\Microsimulation_Inputs_PROTO.xlsm"
	cap copy "${sharep_path}/${prev_version}\_inputs\Results_CCC.xlsm" ///
			"${sharep_path}/${mpo_version}\_inputs\Results_CCC.xlsm"
	
	* Microsimulation tools and results files
	foreach country of global countries {
		cap copy "${sharep_path}/${prev_version}/`country'\Microsimulation_Inputs_`country'.xlsm"  ///
				"${sharep_path}/${mpo_version}/`country'\Microsimulation_Inputs_`country'.xlsm"
			
			if "`country'" == "LKA" {
				
				cap copy "${sharep_path}/${prev_version}/`country'\Microsimulation_Inputs_`country'_HIES.xlsm"  ///
				"${sharep_path}/${mpo_version}/`country'\Microsimulation_Inputs_`country'_HIES.xlsm"
				
				cap copy "${sharep_path}/${prev_version}/`country'\Microsimulation_Inputs_`country'_LFS_Imputed.xlsm"  ///
				"${sharep_path}/${mpo_version}/`country'\Microsimulation_Inputs_`country'_LFS_Imputed.xlsm"
			}
				
		cap copy "${sharep_path}/${prev_version}\_inputs\Results_`country'.xlsm"  ///
				"${sharep_path}/${mpo_version}\_inputs\Results_`country'.xlsm"
	}

