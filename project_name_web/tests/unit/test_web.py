from django.core.urlresolvers import resolve
import pytest
from {{ project_name }}_web.views import hello_world


def test_root_resolves_to_hello_world():
    found = resolve('/web/')
    assert found.func == hello_world

def test_hello_world_contains_greeting(client):
    response = client.get('/web/')
    assert response.context['greeting'] == 'hello world'
