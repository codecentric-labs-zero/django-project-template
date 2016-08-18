from django.conf.urls import url
from {{ project_name }}_api import views

urlpatterns = [
    url(r'^hello_world$', views.hello_world)
    ]
