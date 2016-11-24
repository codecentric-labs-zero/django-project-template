web_url = "http://localhost:8000/web/"

def test_title(webdriver, live_server):
    webdriver.get(live_server.url + '/web')
    assert 'Hello World' in webdriver.title

def test_body_text(webdriver, live_server):
    webdriver.get(live_server.url + '/web')
    body = webdriver.find_element_by_tag_name('body')
    assert "hello world" in body.text