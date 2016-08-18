# Django project template
You can create a new project from this template by running this inside a
Python 3 virtual environment. Make sure to install Django 1.9+ inside the
environment and use its django-admin.py:

```
$ django-admin.py startproject [project_name] \
  --template https://github.com/codecentric-labs-zero/django-project-template/archive/master.zip \
  --name .flooignore,.gitignore,Procfile,.env
  --extension py,md,txt,sh,ini,yml
```

If necessary, make script executable:

```
$ chmod u+x bootstrap.sh
```

Create continuous delivery pipeline and Heroku apps:

```
$ export GITHUB_TOKEN=[your github token]
$ export CIRCLE_TOKEN=[your circle token]
$ heroku login
$ ./bootstrap.sh
```

Please note that this can only be done once and that you'll need to be part
of the codecentric-labs-zero organizations on Heroku and GitHub for this to work.
