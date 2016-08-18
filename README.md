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

If necessary, make scripts executable:

```
$ chmod u+x manage.py
$ chmod u+x merge-base-ff.sh
$ chmod u+x bootstrap.sh
```

Install requirements and run migrations:

```
$ pip install -r requirements.txt
$ ./manage.py migrate
```

If you want to create a continuous delivery pipeline and Heroku apps, you can
run the bootstrap script:

```
$ heroku login
$ ./bootstrap.sh
```

Please note that this must only be done once and that you'll need to be part
of the codecentric-labs-zero organization for this to work.
