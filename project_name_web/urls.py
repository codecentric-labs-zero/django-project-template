from django.conf.urls import url
from {{ project_name }}_web import views

# patterns here are prefixed with 'web/'
urlpatterns = [
    url(r'^$', views.hello_world),
    ]
