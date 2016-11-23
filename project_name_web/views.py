from django.shortcuts import render
from django.http import HttpResponse

def hello_world(request):
    return render(request, 'base.html', {'greeting': 'hello world'})


def ping(request):
    return HttpResponse("I am alive.", content_type="text/plain")

