# 필요한 라이브러리 임포트
import requests
from bs4 import BeautifulSoup
import pandas as pd
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from webdriver_manager.chrome import ChromeDriverManager
from datetime import datetime
import os

# HTTP 요청 헤더 설정: User-Agent를 브라우저처럼 설정하여 차단 방지
headers = {
    "User-Agent": "Mozilla/5.0"
}

# 한글 포함 여부 확인 함수
# 유니코드 범위로 한글 포함 여부를 확인
def contains_korean(text):
    return any('\uac00' <= char <= '\ud7a3' for char in text)

# Bing 뉴스 검색 함수
# BeautifulSoup으로 Bing 뉴스에서 기사 제목과 링크를 추출
def search_bing_news(keyword):
    url = f"https://www.bing.com/news/search?q={keyword}"
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.text, "html.parser")
    results = []
    for card in soup.find_all("a", class_="title"):
        title = card.text.strip()
        href = card.get("href")
        results.append({"site": "Bing", "title": title, "url": href})
    return results

# DuckDuckGo 뉴스 검색 함수
# POST 방식으로 HTML 결과 페이지를 요청해 기사 정보 추출
def search_duckduckgo_news(keyword):
    url = "https://html.duckduckgo.com/html/"
    payload = {'q': keyword + ' site:news'}
    response = requests.post(url, headers=headers, data=payload)
    soup = BeautifulSoup(response.text, "html.parser")
    results = []
    for card in soup.find_all("a", class_="result__a"):
        title = card.text.strip()
        href = card.get("href")
        results.append({"site": "DuckDuckGo", "title": title, "url": href})
    return results

# BIG KINDS 뉴스 검색 함수 (Selenium 사용)
# 자바스크립트 기반 사이트이므로 Selenium으로 자동화 수행
# 한글 키워드만 검색 가능
# BIG KINDS 뉴스 검색 함수 (Selenium 사용)
def search_bigkinds_news(keyword):
    if contains_korean(keyword):
        options = Options()
        options.add_argument('--headless')  # 창 없이 실행
        options.add_argument('--disable-gpu')
        driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=options)
        results = []
        try:
            driver.get("https://www.bigkinds.or.kr/")
            time.sleep(3)
            search_input = driver.find_element(By.ID, "news-search-keyword")
            search_input.send_keys(keyword)
            search_button = driver.find_element(By.CLASS_NAME, "btn.search")
            search_button.click()
            time.sleep(5)
            soup = BeautifulSoup(driver.page_source, "html.parser")
            for item in soup.select("div.news-item a"):
                title = item.text.strip()
                href = item.get("href")
                results.append({"site": "BIG KINDS", "title": title, "url": href})
        except Exception as e:
            print("BIG KINDS 검색 오류:", e)
        finally:
            driver.quit()
        return results
    return []

# 네이버 뉴스 검색 함수
# 네이버 뉴스 검색 결과에서 기사 제목과 링크 추출
def search_naver_news(keyword):
    url = f"https://search.naver.com/search.naver?where=news&query={keyword}"
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.text, "html.parser")
    results = []
    for card in soup.find_all("a", class_="news_tit"):
        title = card.get("title")
        href = card.get("href")
        results.append({"site": "Naver", "title": title, "url": href})
    return results

# 네이트 뉴스 검색 함수
# 네이트 뉴스 검색 결과에서 기사 제목과 링크 추출
def search_nate_news(keyword):
    url = f"https://news.nate.com/search?q={keyword}"
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.text, "html.parser")
    results = []
    for item in soup.select("div.postWrap div.lt1 a"):
        title = item.text.strip()
        href = item.get("href")
        if not href.startswith("http"):
            href = "https://news.nate.com" + href
        results.append({"site": "Nate", "title": title, "url": href})
    return results

# Yahoo News 검색 함수 (영문 키워드 전용)
# 한글 포함 시 검색 제외
def search_yahoo_news(keyword):
    if not contains_korean(keyword):
        url = f"https://news.search.yahoo.com/search?p={keyword}"
        response = requests.get(url, headers=headers)
        soup = BeautifulSoup(response.text, "html.parser")
        results = []
        for card in soup.select("h4.title a"):
            title = card.text.strip()
            href = card.get("href")
            results.append({"site": "Yahoo News", "title": title, "url": href})
        return results
    return []

# ScienceNews 검색 함수 (영문 키워드 전용)
# 카드 요소에서 기사 제목과 링크 수집
def search_sciencenews(keyword):
    if not contains_korean(keyword):
        url = f"https://www.sciencenews.org/search/{keyword}"
        response = requests.get(url, headers=headers)
        soup = BeautifulSoup(response.text, "html.parser")
        results = []
        for item in soup.select(".search-results .card__title a"):
            title = item.text.strip()
            href = item.get("href")
            if not href.startswith("http"):
                href = "https://www.sciencenews.org" + href
            results.append({"site": "ScienceNews", "title": title, "url": href})
        return results
    return []

# 중복 기사 제거 함수
def remove_duplicates(news_list):
    seen_titles = set()
    unique_results = []
    for item in news_list:
        if item['title'] not in seen_titles:
            seen_titles.add(item['title'])
            unique_results.append(item)
    return unique_results

# 메인 실행 함수
def main():
    keywords = input("검색할 키워드를 ,로 구분하여 입력하세요: ").split(',')
    keywords = [k.strip() for k in keywords if k.strip()]
    today = datetime.now().strftime("%Y%m%d")
    filename = f"news_results_{today}.xlsx"
    
    # 엑셀 파일 작성 준비
    writer = pd.ExcelWriter(filename, engine='xlsxwriter')
    workbook = writer.book  # workbook 객체를 가져옴

    for keyword in keywords:
        results = []
        # 각 사이트에서 뉴스 결과 수집
        results += search_bing_news(keyword)
        results += search_duckduckgo_news(keyword)
        results += search_naver_news(keyword)
        results += search_nate_news(keyword)
        results += search_bigkinds_news(keyword)
        results += search_yahoo_news(keyword)
        results += search_sciencenews(keyword)

        # 중복 제거 및 엑셀 저장
        unique_results = remove_duplicates(results)
        if unique_results:
            # 시트 이름을 키워드로 설정 (엑셀 시트 이름은 31자 이하로 제한됨)
            worksheet = workbook.add_worksheet(keyword[:31])  # 시트 이름이 31자까지 허용됨
            worksheet.write_row(0, 0, ["Site", "Title", "URL"])  # 헤더 추가

            # 데이터 작성
            for row_num, result in enumerate(unique_results, 1):
                worksheet.write(row_num, 0, result["site"])
                worksheet.write(row_num, 1, result["title"])
                if result["url"]:
                    # 하이퍼링크 추가
                    worksheet.write_url(row_num, 2, result["url"], string="링크")
                else:
                    worksheet.write(row_num, 2, "URL 없음")

    writer.close()  # 엑셀 파일 저장
    print(f"모든 키워드의 결과가 {filename} 파일에 시트별로 저장되었습니다.")

# 프로그램 실행 트리거
if __name__ == "__main__":
    main() 