from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
import pandas as pd
import time

def init_driver():
    options = Options()
    # options.add_argument("--headless")  # 브라우저 창 안 띄우고 실행하려면 주석 해제
    service = Service(executable_path="C:/Users/tjdwo/AppData/Local/Programs/Python/Python313/chromedriver.exe")
    return webdriver.Chrome(service=service, options=options)

def search_google(driver, keyword):
    driver.get("https://www.google.com/")
    time.sleep(2)
    search_box = driver.find_element(By.NAME, "q")
    search_box.send_keys(keyword)
    search_box.send_keys(Keys.RETURN)
    time.sleep(3)

    results = []
    # 바뀐 구조에 맞춰 수정
    links = driver.find_elements(By.CSS_SELECTOR, "div#search .tF2Cxc")
    for link in links:
        try:
            title = link.find_element(By.CSS_SELECTOR, "h3").text
            url = link.find_element(By.CSS_SELECTOR, "a").get_attribute("href")
            results.append({"site": "Google", "title": title, "url": url})
            print(driver.current_url)
            print(driver.page_source)
        except:
            continue
    return results

#def search_google(driver, keyword):/
    driver.get("https://www.google.com/")
    time.sleep(1)
    search_box = driver.find_element(By.NAME, "q")
    search_box.send_keys(keyword)
    search_box.send_keys(Keys.RETURN)
    time.sleep(2)

    results = []
    links = driver.find_elements(By.CSS_SELECTOR, "div.g")
    for link in links:
        try:
            title = link.find_element(By.TAG_NAME, "h3").text
            url = link.find_element(By.TAG_NAME, "a").get_attribute("href")
            results.append({"site": "Google", "title": title, "url": url})
        except:
            continue
    return results#

def search_naver(driver, keyword):
    driver.get("https://search.naver.com/search.naver?query=" + keyword)
    time.sleep(2)

    results = []
    links = driver.find_elements(By.CSS_SELECTOR, "a.api_txt_lines.total_tit")
    for link in links:
        try:
            title = link.text
            url = link.get_attribute("href")
            results.append({"site": "Naver", "title": title, "url": url})
        except:
            continue
    return results

def main():
    keyword = input("검색할 키워드를 입력하세요: ")
    driver = init_driver()

    try:
        google_results = search_google(driver, keyword)
        naver_results = search_naver(driver, keyword)
    finally:
        driver.quit()

    all_results = google_results + naver_results
    df = pd.DataFrame(all_results)
    df.to_excel("search_results.xlsx", index=False)
    print("검색 결과가 search_results.xlsx에 저장되었습니다.")

if __name__ == "__main__":
    main()
