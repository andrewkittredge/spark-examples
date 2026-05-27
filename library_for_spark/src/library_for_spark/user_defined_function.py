import requests


def page_content_length(url: str) -> int:
    response = requests.get(url)
    response.raise_for_status()
    content = response.content
    return len(content)
