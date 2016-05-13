#!/bin/bash

REPO="$1"
MESSAGE='All work and no play makes Jack a dull boy.'
AUTHOR='Jack <jack@work.com>'

function commit_a_work()
{
  local date="$1"
  local time="$2"

  git \
  --git-dir="$REPO/.git" \
  --work-tree="$REPO" \
  commit \
  --allow-empty \
  --message "$MESSAGE" \
  --author "$AUTHOR" \
  --date "$date $time" \
  --quiet
}

commit_a_work 2016-05-01 12:00:00
