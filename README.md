# Django project template
You can create a new project from this template by running this inside a
Python 3 virtual environment. Make sure to install Django 1.9+ inside the
environment and use its django-admin.py:

```
$ virtualenv --python=python3 venv
$ . venv/bin/activate
$ pip install Django==1.11
$ venv/bin/django-admin startproject [project_name] \
  --template https://github.com/codecentric-labs-zero/django-project-template/archive/master.zip \
  --name .flooignore,.gitignore,Procfile,.env \
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

Also, you need to use a GitHub token with the following permissions:

* **repo**
* **admin:org**
* **admin:repo_hook**
* **admin:public_key**

Make sure that you can access GitHub repositories [via ssh](https://help.github.com/articles/generating-an-ssh-key/).

If you prefer not to set up the delivery pipeline, you can simply prepare the
project for development:

```
$ chmod u+x manage.py
$ chmod u+x merge-base-ff.sh
$ rm bootstrap.sh
$ echo "# [project name]" > README.md
$ pip install -r requirements.txt
$ ./manage.py migrate
$ py.test
$ git init
$ git commit -am "Initial project setup"
```
