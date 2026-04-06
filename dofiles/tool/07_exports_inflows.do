
/*===================================================================================================
Project:			Microsimulations Remittances Inputs from MFMod
Institution:		World Bank - ESAPV

Authors:			Kelly Y. Montoya (kmontoyamunoz@worldbank.org) 
Creation Date:		02/19/2024

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  1/29/2025
===================================================================================================*/

clear all 

/*===================================================================================================
	1 - REMITTANCES FROM MFMOD
===================================================================================================*/

/*Download from: https://mtimodelling.worldbank.org/livempodata/mpodata.html
series "Exports-Remittance Inflows, Value, Millions USD"
*/
/*
python

import selenium
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, ElementClickInterceptedException
from webdriver_manager.chrome import ChromeDriverManager
import time

# Initialize the WebDriver
driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()))

# URL to interact with
url = 'https://mtimodelling.worldbank.org/livempodata/mpodata.html'

# Navigate to the URL
driver.get(url)

try:
    
    # Function to click the checkbox by ID within the specified container
    def click_checkbox_by_id(container_selector, checkbox_id, select=True):
        wait = WebDriverWait(driver, 10)
        container = wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, container_selector)))
        checkbox = container.find_element(By.ID, checkbox_id)
        driver.execute_script("arguments[0].scrollIntoView(true);", checkbox)  # Scroll to the checkbox to make it visible

        # Retry mechanism
        for attempt in range(3):
            try:
                checkbox = wait.until(EC.element_to_be_clickable((By.ID, checkbox_id)))
                if (checkbox.is_selected() and not select) or (not checkbox.is_selected() and select):
                    checkbox.click()
                time.sleep(1)  
                break  
            except (TimeoutException, ElementClickInterceptedException) as e:
                print(f"Attempt {attempt + 1} failed: {e}")
                time.sleep(2)  

    container_selector = '#tbll_WDI_Ctry > ul.unselectedCnts.variableTable.availableView.table-dimension-C'

    # List of countries within microsimulation
    countries = ['AFG', 'BGD', 'BTN', 'IND', 'MDV', 'NPL', 'PAK', 'LKA']
    
    # Select the countries with microsimulations
    for country_id in countries:
        click_checkbox_by_id(container_selector, country_id)

    # Unselect default countries
    default_countries = ['WLT', 'DEV']
    
    for country_id in default_countries:
        click_checkbox_by_id(container_selector, country_id, select=False)

    # Expand the Series dropdown
    try:
		dropdown_link = WebDriverWait(driver, 10).until(
			EC.element_to_be_clickable((By.CSS_SELECTOR, 'a[data-toggle="collapse"][href="#selectedDimension_WDI_Series"]'))
		)
		dropdown_link.click()
    except TimeoutException:
        print("Series dropdown not found")

    # List of series
    series = ['cBXFSTREMTCD', 'FPCPITOTLXN']
	
	# Selecting inflows and CPI
    series_container_selector = '#selectedDimension_WDI_Series'
    
	for series_id in series:
        click_checkbox_by_id(series_container_selector, series_id)

    # Unselect the default Series
    unselect_checkbox_id = 'cNYGDPMKTPKDZ'
    click_checkbox_by_id(series_container_selector, unselect_checkbox_id, select=False)

    # Click on the "Series" link
    series_link = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.ID, 'lnkSeries'))
    )
    series_link.click()

    # Click on the "Table" link
    table_link = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.ID, 'lnkTable'))
    )
    table_link.click()

    # Click on the "Download" link
    download_link = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.ID, 'lnkDownload'))
    )
    download_link.click()

    # Click the "Submit" button
    submit_button = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.ID, 'downloadButton'))
    )
    submit_button.click()

finally:
   
    time.sleep(10)  # Time to observe or modify if needed
    driver.quit()
end
*/

copy "${downloads}/${inflows}.csv" "${path_mpo}/${inflows}.csv", replace
erase "${downloads}/${inflows}.csv"


/*===================================================================================================
	2 - PREPARING FILE FOR MICROSIMS TOOL
===================================================================================================*/

import delimited "${path_mpo}/${inflows}.csv", varnames(nonames) stringcols(_all) clear

forval j = 3/51 {
	rename v`j' `= "y_" + v`j'[1]'
}

drop if v2 == ""
drop in 1

destring *, replace

drop y_1980-y_2000

gen country = ""
replace country = "AFG" if v2 == "Afghanistan"
replace country = "BGD" if v2 == "Bangladesh"
replace country = "BTN" if v2 == "Bhutan"
replace country = "IND" if v2 == "India"
replace country = "MDV" if v2 == "Maldives"
replace country = "NPL" if v2 == "Nepal"
replace country = "PAK" if v2 == "Pakistan"
replace country = "LKA" if v2 == "Sri Lanka"

gen v1_aux=substr(v1,-7,.)
replace v1_aux = "Inflows" if v1_aux == "TREMTCD"
replace v1_aux = "CPI" if v1_aux == "ITOTLXN"

drop v1 v2
order country v1_aux
ren v1_aux indicator

reshape long y_, i(country indicator) j(year)
drop if y_ == .

ren y_ value

gen date = "$date_inflows"


/*===================================================================================================
	3 - EXPORT DATA
===================================================================================================*/

export excel using "$path_mpo/$input_master", sheet("inflows") sheetreplace firstrow(variables)

/*===================================================================================================
	- END
===================================================================================================*/
