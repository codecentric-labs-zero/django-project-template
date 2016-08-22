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
chmod u+x manage.py >/dev/null 2>&1
chmod u+x merge-base-ff.sh >/dev/null 2>&1
PROJECT_NAME={{ project_name | lower }}
APP_NAME=cclz-{{ project_name | lower }}
PROD_APP_NAME="$APP_NAME-prod"
PIPELINE_NAME="$APP_NAME-pipeline"
echo "=== Setting up Heroku ==="
heroku create $APP_NAME --org codecentric-labs-zero --remote staging --region eu
heroku buildpacks:add https://github.com/heroku/heroku-buildpack-python.git --app $APP_NAME
heroku config:set ENVIRONMENT=STAGING --app $APP_NAME
heroku config:set DJANGO_SECRET_KEY=`./manage.py generate_secret_key` --app $APP_NAME
heroku addons:create papertrail:choklad --app $APP_NAME
heroku addons:create heroku-postgresql:hobby-dev --app $APP_NAME
heroku pg:wait --app $APP_NAME
heroku create $PROD_APP_NAME --org codecentric-labs-zero --remote staging --region eu
heroku buildpacks:add https://github.com/heroku/heroku-buildpack-python.git --app $PROD_APP_NAME
heroku config:set ENVIRONMENT=PRODUCTION --app $PROD_APP_NAME
heroku config:set DJANGO_SECRET_KEY=`./manage.py generate_secret_key` --app $PROD_APP_NAME
heroku addons:create papertrail:choklad --app $PROD_APP_NAME
heroku addons:create heroku-postgresql:hobby-dev --app $PROD_APP_NAME
heroku plugins:install heroku-pipelines
heroku pipelines:create $PIPELINE_NAME --app $PROD_APP_NAME --stage production
heroku pipelines:add $PIPELINE_NAME --app $APP_NAME --stage staging
echo "=== Done setting up Heroku ==="
echo "=== Setting up GitHub and CircleCI ==="
echo "Creating repository"
curl -sS -X POST -d '{"name": "'"$PROJECT_NAME"'", "private": false, "team_id": "2073794"}' -H "Authorization: token $GITHUB_TOKEN" -i https://api.github.com/orgs/codecentric-labs-zero/repos >/dev/null
sleep 15s
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
echo "Writing new README.md"
echo "# testproject" > README.md
echo "[![CircleCI](https://circleci.com/gh/codecentric-labs-zero/$PROJECT_NAME.svg?style=svg)](https://circleci.com/gh/codecentric-labs-zero/$PROJECT_NAME)" >> README.md
echo "## Links" >> README.md
echo "### Staging environment" >> README.md
echo "* [Web application](https://$APP_NAME.herokuapp.com/web)" >> README.md
echo "* [API](https://$APP_NAME.herokuapp.com/api/hello_world)" >> README.md
echo "* [Admin UI](https://$APP_NAME.herokuapp.com/admin)" >> README.md
echo "### Production environment" >> README.md
echo "* [Web application)](https://$PROD_APP_NAME.herokuapp.com/web)" >> README.md
echo "* [API](https://$PROD_APP_NAME.herokuapp.com/api/hello_world)" >> README.md
echo "* [Admin UI](https://$PROD_APP_NAME.herokuapp.com/admin)" >> README.md
echo "### Monitoring" >> README.md
echo "* [Heroku Dashboard](https://dashboard.heroku.com/apps/$APP_NAME)" >> README.md
echo "* [Papertrail Event Dashboard (staging)](https://papertrailapp.com/systems/$APP_NAME/events)" >> README.me
echo "* [Papertrail Event Dashboard (production)](https://papertrailapp.com/systems/$PROD_APP_NAME/events)" >> README.me
echo "Removing bootstrap.sh"
rm bootstrap.sh >/dev/null
echo "Pushing initial project setup"
git add .
git commit -am "Initial project setup"
git push -u origin master
echo "Done"
