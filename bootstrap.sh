#!/bin/bash
heroku auth:whoami >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Please run heroku login before using this script."
    exit 1;
fi
if [ ! -d .git ]; then
    echo "Initializing git repository"
    git init
fi
APP_NAME=cclz-{{ project_name | lower }}
PROD_APP_NAME="$APP_NAME-prod"
PIPELINE_NAME="$APP_NAME-pipeline"
echo "Creating heroku staging app $APP_NAME"
heroku create $APP_NAME --org codecentric-labs-zero --remote staging --region eu
echo "Setting staging environment"
heroku config:set ENVIRONMENT=STAGING --app $APP_NAME
echo "Creating secret key"
heroku config:set DJANGO_SECRET_KEY=`./manage.py generate_secret_key` --app $APP_NAME
echo "Adding heroku-postgresql to $APP_NAME"
heroku addons:create heroku-postgresql:hobby-dev --app $APP_NAME
heroku pg:wait --app $APP_NAME
echo "Creating heroku production app $PROD_APP_NAME"
heroku create $PROD_APP_NAME --org codecentric-labs-zero --remote staging --region eu
echo "Setting production environment"
heroku config:set ENVIRONMENT=PRODUCTION --app $PROD_APP_NAME
echo "Creating secret key"
heroku config:set DJANGO_SECRET_KEY=`./manage.py generate_secret_key` --app $PROD_APP_NAME
echo "Adding heroku-postgresql to $PROD_APP_NAME"
heroku addons:create heroku-postgresql:hobby-dev --app $PROD_APP_NAME
echo "Creating heroku pipeline $PIPELINE_NAME"
heroku plugins:install heroku-pipelines
echo "Adding $PROD_APP_NAME to $PIPELINE_NAME production stage"
heroku pipelines:create $PIPELINE_NAME --app $PROD_APP_NAME --stage production
echo "Adding $APP_NAME to $PIPELINE_NAME staging stage"
heroku pipelines:add $PIPELINE_NAME --app $APP_NAME --stage staging
echo "Done"
