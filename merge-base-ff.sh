#!/bin/bash
if [ "$CIRCLE_BRANCH" == "develop" ]
then
  echo "Merging master into develop before running tests."
  git merge --ff-only origin/master
  exit $?
elif [ "$CIRCLE_BRANCH" == "master" ]
then
  echo "Doing nothing for master."
  exit
else
  echo "Merging develop into feature branch before running tests."
  git merge --ff-only origin/develop
  exit $?
fi
