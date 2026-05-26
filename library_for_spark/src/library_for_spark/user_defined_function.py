import requests


def get_page_content(url: str) -> int:
    return len(requests.get(url).content)
