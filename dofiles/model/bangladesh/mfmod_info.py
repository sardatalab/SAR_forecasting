import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, ElementClickInterceptedException
from webdriver_manager.chrome import ChromeDriverManager

# Initialize WebDriver with error handling
try:
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()))
except Exception as e:
    print(f"Error initializing WebDriver: {e}")
    exit()

# URL to interact with
url = 'https://mtimodelling.worldbank.org/livempodata/mpodata.html'

# Navigate to the URL
driver.get(url)

try:
    # Function to click the checkbox by ID within the specified container
    def click_checkbox_by_id(container_selector, checkbox_id, select=True):
        wait = WebDriverWait(driver, 10)
        try:
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
        except TimeoutException:
            print(f"Checkbox {checkbox_id} not found in container {container_selector}")

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

    # Selecting inflows and CPI
    series_container_selector = '#selectedDimension_WDI_Series'
    series_checkbox_ids = ['cBXFSTREMTCD', 'FPCPITOTLXN']
    for checkbox_id in series_checkbox_ids:
        click_checkbox_by_id(series_container_selector, checkbox_id)

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