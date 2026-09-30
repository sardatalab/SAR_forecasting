README
********

This document explains how to update the exercise that Assess the impact of Middle East Conflict in South Asian countries. Please follow the steps below, some comments are inside the respective files:

1. Create Oil_prices folder in the round's folder (e.g., AM2026). This folder is NOT created automatically.

2. Copy the following necessary files from the previous round in the new folder:
	2.1. food_share_vectors_SAR.do
	2.2. /input/base_cpi_headline_food.xlsx
	2.3. /input/pppfactors.xlsx
	2.4. /output/Conflict after Price Adjustment.xlsx
	2.5. /output/Conflict after Price Adjustment 2025 - 2026.xlsx
	2.6. /output/SAR_Iran_conflict_SEP_29_2026.xlsx  ## Latest date available

3. Update country food vectors using the dofile in 2.1 "food_share_vectors_SAR.do", if necessary. The hhid in these vectors should match those in the microsimulated microdata, so the data is successfully merged. For actual survey data the vector is called "ISO_food_share", for imputed data the name is "ISO_food_share_YYYY_s2s". ISO is the country 3-digits iso code and YYYY is the year of the receiving database in the imputation.

4. Update macroeconomic projections using the microsimulation tools in the files 2.4 and 2.5. The baseline data for cases that use a counterfactual (e.g., baseline vs. conflict instead of 2025 vs. 2026) are available in SM2026. For file 2.5, the poverty and labor market projections can be updated using the "Results_ISO" Excel files resulting from the microsimulation for each country, since this exercise doesn't rely on changes in relative prices.

5. Update 2.2 and 2.3 with the latest CPI, food CPI, food weight, and agricultural production parameters with the latest data. Headline CPI comes from macro projections and can be consulted in the respective microsimulation tools or the files in 2.4 and 2.5. The food CPI information needs to be consulted on each NSO page. Check the formulas in each Excel and the technical note before proceeding. Some links of the respective NSOs are available in the "Simulations check list" Excel file.

6. Rename file in 2.6 with the current date.

7. Update dofiles in "C:\Users\wb520054\WBG\SARDATALAB - Documents\Microsimulations\0_SAR_forecasting\dofiles\oil_prices" including the R script "transitions", so they use the current path, microdata, and with the current date. Run. This will fill the information in file 2.6. After that, you can finish updating 2.4.