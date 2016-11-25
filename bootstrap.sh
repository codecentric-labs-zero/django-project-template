#!/bin/bash
PROJECT_NAME={{ project_name | lower }}
APP_NAME=cclz-{{ project_name | lower }}
PROD_APP_NAME="$APP_NAME-prod"
PIPELINE_NAME="$APP_NAME-pipeline"
echo "=== Checking prerequisites ==="
[[ $PROJECT_NAME =~ ^[a-z]+$ ]] || { echo >&2 "Unfortunately, you used an invalid project name ($PROJECT_NAME) when creating a new project."; echo >&2 $'We apologize for not being able to warn you earlier.\nYou must only use lowercase letters as project name for bootstrap.sh to work.'; exit 1; }
command -v curl >/dev/null 2>&1 || { echo >&2 "Please install curl before using this script."; exit 1; }
command -v heroku >/dev/null 2>&1 || { echo >&2 $'Please install the heroku command line tools before using this script.\nYou can find installation instructions at https://devcenter.heroku.com/articles/heroku-command-line.'; exit 1; }
command -v git >/dev/null 2>&1 || { echo >&2 "Please install git before using this script."; exit 1; }
command -v pip >/dev/null 2>&1 || { echo >&2 "Please install pip before using this script."; exit 1; }
heroku auth:whoami >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo >&2 "Please run heroku login before using this script."
  exit 1;
fi
heroku apps:info --app $APP_NAME >/dev/null 2>&1
[[ $? -eq 0 ]] && { echo >&2 "A heroku app with the name $APP_NAME already exists. Please create a new project with a unique name."; exit 1; }
heroku apps:info --app $PROD_APP_NAME >/dev/null 2>&1
[[ $? -eq 0 ]] && { echo >&2 "A heroku app with the name $PROD_APP_NAME already exists. Please create a new project with a unique name."; exit 1; }
git ls-remote git@github.com:codecentric-labs-zero/django-project-template.git >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo >&2 $'It seems that you cannot access codecentric-labs-zero GitHub organisation repositories via their git protocol URL.'
  echo >&2 "Please make sure that you have correctly configured your GitHub account to work with SSH."
  echo >&2 "You can find instruction for doing so at https://help.github.com/articles/generating-an-ssh-key/."
  exit 1;
fi
git ls-remote git@github.com:codecentric-labs-zero/$PROJECT_NAME.git >/dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "Warning! There is an existing GitHub repository at git@github.com:codecentric-labs-zero/$PROJECT_NAME.git."
  echo "This can happen if you are retrying to bootstrap this project and this script has already created it before."
  echo "If you are running this script for the first time, you should probably abort bootstrapping with CTRL-C."
  echo "Check the codecentric-labs-zero organisation on GitHub and use a unique project name next time."
  read -p "If you still want to continue, press [ENTER]."
fi
if [ -z "$CIRCLE_TOKEN" ]; then
  echo >&2 "Please set the CIRCLE_TOKEN environment variable before running this script."
  echo >&2 "You can create a new token at https://circleci.com/account/api."
  exit 1;
fi
if [ -z "$GITHUB_TOKEN" ]; then
  echo >&2 "Please set the GITHUB_TOKEN environment variable before running this script."
  echo >&2 "You can create a new token at https://github.com/settings/tokens."
  exit 1;
fi
if [ -z "$VIRTUAL_ENV" ]; then
  echo >&2 "Please create and activate a Python 3 virtual environment for the new project_name before running this script. One way of doing this is running the following commands: "
  echo >&2 "$ virtualenv --python=python3 venv"
  echo >&2 "$ .venv/bin/activate"
  echo >&2 "For easier management of virtual enviroments, you might want to consider using https://virtualenvwrapper.readthedocs.io/en/latest/index.html."
  exit 1;
fi
echo "=== Installing dependencies ==="
pip install -r requirements.txt >/dev/null
if [ $? -ne 0 ]; then
  echo >&2 "Installing requirements failed. Please have a look at the console output and fix all problem."
  echo >&2 "You can re-run bootstrap.sh at any time to retry bootstrapping this project."
  exit 1;
fi
if [ ! -d .git ]; then
  echo "=== Initializing git repository ==="
  git init
fi
echo "=== Fixing file permissions ==="
chmod u+x manage.py >/dev/null 2>&1
chmod u+x merge-base-ff.sh >/dev/null 2>&1
echo "=== Setting up GitHub and CircleCI ==="
git ls-remote git@github.com:codecentric-labs-zero/$PROJECT_NAME.git >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Creating repository"
  curl -sS -X POST -d '{"name": "'"$PROJECT_NAME"'", "private": false, "team_id": "2073794"}' -H "Authorization: token $GITHUB_TOKEN" -i https://api.github.com/orgs/codecentric-labs-zero/repos >/dev/null
  if [ $? -ne 0 ]; then
    echo >&2 "Creating repository failed. Please have a look at the console output and fix all problem."
    echo >&2 "You can re-run bootstrap.sh at any time to retry bootstrapping this project."
    exit 1;
  fi
  sleep 15s
else
  echo "Repository already exists, skipping creation."
fi
echo "Adding repository to CircleCI"
curl -sS -X POST "https://circleci.com/api/v1.1/project/github/codecentric-labs-zero/$PROJECT_NAME/follow?circle-token=$CIRCLE_TOKEN" >/dev/null
echo "Creating new SSH key"
ssh-keygen -t rsa -b 4096 -C "cc-labs-zero@codecentric.de" -N "" -f $TMPDIR$PROJECT_NAME-key >/dev/null
PRIVATE_KEY="`cat $TMPDIR$PROJECT_NAME-key`"
PUBLIC_KEY="`cat $TMPDIR$PROJECT_NAME-key.pub`"
rm $TMPDIR$PROJECT_NAME-key >/dev/null
rm $TMPDIR$PROJECT_NAME-key.pub >/dev/null
echo "Adding SSH key to CircleCI"
curl -sS -X POST --header "Content-Type: application/json" -d '{"hostname":"github.com", "private_key":"'"$PRIVATE_KEY"'"}' "https://circleci.com/api/v1.1/project/github/codecentric-labs-zero/$PROJECT_NAME/ssh-key?circle-token=$CIRCLE_TOKEN" >/dev/null
echo "Adding SSH key to GitHub"
curl -sS -X POST -d '{"key": "'"$PUBLIC_KEY"'", "title": "CircleCI write access", "read_only": false }' -H "Authorization: token $GITHUB_TOKEN" -i https://api.github.com/repos/codecentric-labs-zero/$PROJECT_NAME/keys >/dev/null
echo "Adding Heroku API key to CircleCI"
curl -sS --data "apikey=`heroku auth:token`" "https://circleci.com/api/v1.1/user/heroku-key?circle-token=$CIRCLE_TOKEN" >/dev/null
echo "================================================================================================================================"
echo "You need to manually associate a Heroku SSH key with your CircleCI account."
echo "Please visit https://circleci.com/gh/codecentric-labs-zero/$PROJECT_NAME/edit#heroku and follow the instructions given in Step 2."
read -p "Press [Enter] when you have completed this step."
echo "Adding origin remote to local repository"
git remote add origin git@github.com:codecentric-labs-zero/$PROJECT_NAME.git >/dev/null
echo "=== Setting up Heroku ==="
heroku create $APP_NAME --org codecentric-labs-zero --remote staging --region eu
if [ $? -ne 0 ]; then
  echo >&2 "Creating heroku application failed. Please have a look at the console output and fix all problem."
  echo >&2 "You can re-run bootstrap.sh at any time to retry bootstrapping this project."
  exit 1;
fi
heroku buildpacks:add https://github.com/heroku/heroku-buildpack-python.git --app $APP_NAME
heroku config:set ENVIRONMENT=STAGING --app $APP_NAME
heroku config:set DJANGO_SECRET_KEY=`./manage.py generate_secret_key` --app $APP_NAME
heroku addons:create papertrail:choklad --app $APP_NAME
heroku addons:create heroku-postgresql:hobby-dev --app $APP_NAME
heroku addons:create newrelic:wayne --app $APP_NAME
heroku config:set NEW_RELIC_APP_NAME="$APP_NAME" --app $APP_NAME
heroku pg:wait --app $APP_NAME
heroku create $PROD_APP_NAME --org codecentric-labs-zero --remote staging --region eu
if [ $? -ne 0 ]; then
  echo >&2 "Creating heroku application failed. Please have a look at the console output and fix all problem."
  echo >&2 "You can re-run bootstrap.sh at any time to retry bootstrapping this project."
  exit 1;
fi
heroku buildpacks:add https://github.com/heroku/heroku-buildpack-python.git --app $PROD_APP_NAME
heroku config:set ENVIRONMENT=PRODUCTION --app $PROD_APP_NAME
heroku config:set DJANGO_SECRET_KEY=`./manage.py generate_secret_key` --app $PROD_APP_NAME
heroku addons:create papertrail:choklad --app $PROD_APP_NAME
heroku addons:create heroku-postgresql:hobby-dev --app $PROD_APP_NAME
heroku addons:create newrelic:wayne --app $PROD_APP_NAME
heroku config:set NEW_RELIC_APP_NAME="$PROD_APP_NAME" --app $PROD_APP_NAME
heroku plugins:install heroku-pipelines
heroku pipelines:create $PIPELINE_NAME --app $PROD_APP_NAME --stage production
heroku pipelines:add $PIPELINE_NAME --app $APP_NAME --stage staging
echo "=== Done setting up Heroku ==="
echo "Writing new README.md"
echo "# $PROJECT_NAME" > README.md
echo "[![CircleCI](https://circleci.com/gh/codecentric-labs-zero/$PROJECT_NAME.svg?style=svg)](https://circleci.com/gh/codecentric-labs-zero/$PROJECT_NAME)" >> README.md
echo "## Links" >> README.md
echo "### Staging environment" >> README.md
echo "* [Web application](https://$APP_NAME.herokuapp.com/web)" >> README.md
echo "* [API](https://$APP_NAME.herokuapp.com/api/hello_world)" >> README.md
echo "* [Admin UI](https://$APP_NAME.herokuapp.com/admin)" >> README.md
echo $'\n' >> README.md
echo "### Production environment" >> README.md
echo "* [Web application](https://$PROD_APP_NAME.herokuapp.com/web)" >> README.md
echo "* [API](https://$PROD_APP_NAME.herokuapp.com/api/hello_world)" >> README.md
echo "* [Admin UI](https://$PROD_APP_NAME.herokuapp.com/admin)" >> README.md
echo $'\n' >> README.md
echo "### Monitoring" >> README.md
echo "* [Heroku Dashboard](https://dashboard.heroku.com/apps/$APP_NAME)" >> README.md
echo "* [Papertrail Event Dashboard (staging)](https://papertrailapp.com/systems/$APP_NAME/events)" >> README.md
echo "* [Papertrail Event Dashboard (production)](https://papertrailapp.com/systems/$PROD_APP_NAME/events)" >> README.md
echo "Removing bootstrap.sh"
rm bootstrap.sh >/dev/null
echo "Pushing initial project setup"
git add .
git commit -am "Initial project setup"
git push -u origin master
echo "Done"
