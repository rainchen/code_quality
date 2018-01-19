#!/bin/sh
# This script is used to run on Travis CI to publish generated files to GitHub pages
if [ ${TRAVIS} = "true" ]; then
  echo "Starting to update gh-pages"

  #copy data we're interested in to other place
  mkdir $HOME/tmp
  cp -R tmp/code_quality $HOME/tmp/code_quality

  #go to home
  cd $HOME

  #using token clone gh-pages branch
  git clone --quiet --branch=gh-pages https://${GH_TOKEN}@github.com/${TRAVIS_REPO_SLUG}.git gh-pages > /dev/null

  #go into diractory and copy data we're interested in to that directory
  cd gh-pages
  cp -Rf $HOME/tmp/code_quality/* .

  #setup git user
  git config user.email "travis@travis-ci.org"
  git config user.name "Travis CI"

  #add, commit and push files
  travis_build_url="https://travis-ci.org/${TRAVIS_REPO_SLUG}/builds/${TRAVIS_BUILD_ID}"
  git add -f .
  git commit -m "Travis CI build $travis_build_url pushed to gh-pages"
  git push -fq origin gh-pages > /dev/null

  #display GitHub Project Pages url
  owner_name=`echo $TRAVIS_REPO_SLUG|cut -d / -f 1`
  repo_name=`echo $TRAVIS_REPO_SLUG|cut -d / -f 2`
  gh_pages_url="https://$owner_name.github.io/$repo_name"
  echo "Push to $gh_pages_url"
fi
