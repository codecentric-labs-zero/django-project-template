#!/bin/bash
heroku auth:whoami >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Please run heroku login before using this script."
  exit 1;
fi
if [ -z "$CIRCLE_TOKEN" ]; then
  echo "Please set the CIRCLE_TOKEN environment variable before running this script."
  echo "You can create a new token at https://circleci.com/account/api."
  exit 1;
fi
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Please set the GITHUB_TOKEN environment variable before running this script."
  echo "You can create a new token at https://github.com/settings/tokens."
  exit 1;
fi
if [ ! -d .git ]; then
  echo "Initializing git repository"
  git init
fi
Echo "Fixing file permissions"
chmod u+x manage.py
chmod u+x merge-base-ff.sh
PROJECT_NAME={{ project_name | lower }}
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
echo "Creating GitHub repo"
curl -X POST -d '{"name": "'"$PROJECT_NAME"'", "private": false, "team_id": "2073794"}' -H "Authorization: token $GITHUB_TOKEN" -i https://api.github.com/orgs/codecentric-labs-zero/repos
sleep 15s
echo "Adding repo to CircleCI"
curl -X POST "https://circleci.com/api/v1.1/project/github/codecentric-labs-zero/$PROJECT_NAME/follow?circle-token=$CIRCLE_TOKEN"
echo "Creating new SSH key"
ssh-keygen -t rsa -b 4096 -C "cc-labs-zero@codecentric.de" -N "" -f $TMPDIR$PROJECT_NAME-key
PRIVATE_KEY="`cat $TMPDIR$PROJECT_NAME-key`"
PUBLIC_KEY="`cat $TMPDIR$PROJECT_NAME-key.pub`"
rm $TMPDIR$PROJECT_NAME-key
rm $TMPDIR$PROJECT_NAME-key.pub
echo "Adding SSH key to CircleCI"
curl -X POST --header "Content-Type: application/json" -d '{"hostname":"github.com", "private_key":"'"$PRIVATE_KEY"'"}' "https://circleci.com/api/v1.1/project/github/codecentric-labs-zero/$PROJECT_NAME/ssh-key?circle-token=$CIRCLE_TOKEN"
echo "Adding SSH key to GitHub"
curl -X POST -d '{"key": "'"$PUBLIC_KEY"'", "title": "CircleCI write access", "read_only": false }' -H "Authorization: token $GITHUB_TOKEN" -i https://api.github.com/repos/codecentric-labs-zero/$PROJECT_NAME/keys
echo "Adding origin remote to local repo"
git remote add origin git@github.com:codecentric-labs-zero/$PROJECT_NAME.git
echo "Pushing initial version"
git add .
git commit -am "Initial project setup"
git push -u origin master
echo "Done"
