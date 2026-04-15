
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

	
* PDS
	
	* Real growth
	if ${model} == 2024 gen gr_pds = (186194/201037) - 1
	if ${model} == 2025 gen gr_pds = (178985/201037) - 1
	if inlist(${model},2026,2027,2028) gen gr_pds = (178985/201037) - 1
	
	* New PDS vector
	gen h_pds_s = h_pds * (1 + gr_pds)

	
* Other Schemes
	
	* Real growth
	if ${model} == 2024 gen gr_oth = (173026.91/177037.69) - 1
	if ${model} == 2025 gen gr_oth = (169467.53/177037.69) - 1
	if inlist(${model},2026,2027,2028) gen gr_oth = (166551.90/177037.69) - 1
	
	* New PDS vector
	gen h_oth_schemes_s = h_oth_schemes * (1 + gr_oth)

