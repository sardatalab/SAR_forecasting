
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Minimum wage implementation
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		03/17/2020

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/11/2024
===================================================================================================*/
/*
Notes from PE:

Hi Kelly,

As discussed, here is the outline for simulating the minimum wage reform in the Maldives which was introduced in 2022: 
-	Full-time, formal workers in the private sector which earn less than 4,500 MVR/month should receive 4,500 MVR/month. The value of the minimum wage stays the same over time since 2022 (so the real value decreases actually). 
-	Full-time, formal workers in the public sector which earn less than 7,000 MVR/month should receive 7,000 MVR/month. Same here, the value of the minimum wage stays the same over time since 2022 (so the real values decrease again).
-	No adjustments for informal workers.  

Please let me know if you have any questions. 

Thank you and best, 
Britta

*/


/*===================================================================================================
	1 - Minimum wage real values
===================================================================================================*/

gen deflator = .
replace deflator = 0.9863023	if ${model} == 2020
replace deflator = 0.991659401 	if ${model} == 2021
replace deflator = 1.014796203 	if ${model} == 2022
replace deflator = 1.044504057 	if ${model} == 2023
replace deflator = 1.059125025 	if ${model} == 2024
replace deflator = 1.1019159 	if ${model} == 2025
replace deflator = 1.151199971 	if ${model} == 2026
replace deflator = 1.200701569 	if ${model} == 2027
replace deflator = 1.249930334 	if ${model} == 2028

gen min_w_priv = 4500
gen min_w_pub = 7000

gen min_w_priv_s = (min_w_priv / cpi$ppp / icp$ppp ) / deflator
gen min_w_pub_s = (min_w_pub / cpi$ppp / icp$ppp ) / deflator


/*===================================================================================================
	2 - Adjust simulated wage using the real minimum wage
===================================================================================================*/

* Private employee
replace lai_m_s = min_w_priv_s if /// Asign minimum wage
	salaried_s == 1 & /// Salared worker
	lai_m_s < min_w_priv_s & lai_m_s != . & /// simulated wage is lower that minimum wage
	informal_s == 0 & /// formal worker|
	sect_secu6 == . & /// no additional jobs
	public == 0 & /// and private employee
	placebirth_OtherCountry == . // Non-migrant
	
* Public employee	
replace lai_m_s = min_w_pub_s if /// Asign minimum wage
	salaried_s == 1 & /// Salared worker
	lai_m_s < min_w_priv_s & lai_m_s != . & /// simulated wage is lower that minimum wage
	informal_s == 0 & /// formal worker|
	sect_secu6 == . & /// no additional jobs
	public == 1 & /// and public employee
	placebirth_OtherCountry == . // Non-migrant


/*===================================================================================================
	- END
===================================================================================================*/
