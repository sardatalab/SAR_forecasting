
/*===================================================================================================
Project:			SAR Poverty micro-simulations - Income Support Allowance 2020
Institution:		World Bank - ESAPV

Authors:			Sergio Olivieri & Kelly Y. Montoya
E-mail:				solivieri@worldbank.org; kmontoyamunoz@worldbank.org
Creation Date:		03/17/2020

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  11/11/2024
===================================================================================================*/
/*
Notes from PE:

We will need to give the support only to people who lost their job or faced reduced earnings during the pandemic – this will be determined by what I do in the labor market part of the model. 

Individuals who met the ISA eligibility criteria as potential beneficiaries in 2020 were:
•	Maldivian nationals aged 18–65
•	Employed or self-employed (including those in the informal sector)
•	No public sector workers — the ISA was targeted at workers who lost income due to COVID, and civil servants faced salary cuts rather than job loss, and were not eligible for ISA
•	No households where total household income already exceeded MVR 5,000/month from non-labor sources
•	No expatriate workers, who were excluded

Eligible individuals received the following benefits: 
•	If post-shock income is below MVR 5,000: ISA transfer = MVR 5,000 minus post-shock income
•	If post-shock income is zero: ISA transfer = MVR 5,000 (full benefit)
•	If post-shock income exceeds MVR 5,000: ISA transfer = 0 (ineligible)



*/


/*===================================================================================================
	1 - Elegibility Criteria
===================================================================================================*/

* Maldivian nationals aged 18–65
	gen criteria1 = 1 if /*inrange(age,18,65) &*/ Nationality == 1
	
* Employed or self-employed (including those in the informal sector)
	gen criteria2 = 1 if inlist(empstat,1,4) & emplyd == 1

* No public sector workers — the ISA was targeted at workers who lost income due to COVID, and civil servants faced salary cuts rather than job loss, and were not eligible for ISA
	gen criteria3 = 1 if public != 1

* No households where total household income already exceeded MVR 5,000/month from non-labor sources
	gen criteria4 = 1 if lai_m_s * cpi$ppp * icp$ppp < 5000 & lai_m_s != .
	
* Elegible
	egen aux_eleg = rowtotal(criteria1 criteria2 criteria3 criteria4)
	gen elegible = 1 if aux_eleg == 4


/*===================================================================================================
	2 - Income adjustments
===================================================================================================*/

/* 
 - If post-shock income is below MVR 5,000: ISA transfer = MVR 5,000 minus post-shock income
 - If post-shock income is zero: ISA transfer = MVR 5,000 (full benefit)
 - If post-shock income exceeds MVR 5,000: ISA transfer = 0 (ineligible)
 */
 
	gen aux_lai_m_s = 5000 / cpi$ppp / icp$ppp if (lai_m_s < 5000 / cpi$ppp / icp$ppp) & elegible == 1
	
	ren lai_m_s lai_m_s_orig
	
	clonevar lai_m_s = lai_m_s_orig
	
	replace lai_m_s = aux_lai_m_s if aux_lai_m_s != .


/*===================================================================================================
	- END
===================================================================================================*/
