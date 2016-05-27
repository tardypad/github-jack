init_work()
{
  if [ -d "$REPOSITORY" ]
  then
    if ! $KEEP
    then
      local name=$( basename $( readlink --canonicalize "$REPOSITORY" ) )

      if ! $FORCE && \
        ( [ -d "$REPOSITORY/.git" ] || [ -f "$REPOSITORY/$WRITE_FILE" ] )
      then
        while true; do
          read -p "Confirm the reset of that \"$name\" repository work? "
          case $REPLY in
              yes|y) break;;
              no|n) exit 0;;
              *) echo "Please answer yes or no.";;
          esac
        done
      fi

      info "Resetting $name work repository"
      rm -rf "$REPOSITORY/.git"
      [ -z "$WRITE_FILE" ] || > "$REPOSITORY/$WRITE_FILE"
    fi
  else
    info "Creating $REPOSITORY work repository"
    mkdir --parents "$REPOSITORY"
  fi

  git --git-dir "$REPOSITORY/.git" --work-tree "$REPOSITORY" init --quiet
}

define_multiplier()
{
  if [ -n "$GITHUB_USERNAME" ]
  then
    local count=$(
      curl --silent "https://github.com/$GITHUB_USERNAME" \
      | grep data-count \
      | grep '#1e6823' \
      | sed --regexp-extended 's/.* data-count="([0-9]+)" .*/\1/' \
      | sort --unique --general-numeric-sort \
      | head --lines 1
    )
    [[ "$count" -gt 0 ]] || count=1
    SHADE_MULTIPLIER=$( printf %0.f $( echo "$count / 4" | bc --mathlib ) )
  fi
}

day_count()
{
  local day_number="$1"
  local row=$(( $day_number % 7 + 1 ))
  local col=$(( $day_number / 7 + 1 ))
  local index=$( \
    head "$TEMPLATE" --lines $row \
    | tail --lines 1 \
    | head --bytes $col \
    | tail --bytes 1
  )

  echo $(( $index * $SHADE_MULTIPLIER ))
}

start_date()
{
  if [ "$POSITION" == 'left' ]
  then
    POSITION='-1 year'
  else
    local template_cols=$( wc --max-line-length < "$TEMPLATE" )

    if [ "$POSITION" == 'center' ]
    then
      POSITION="-53 weeks $(( (53 - $template_cols)/2 )) weeks"
    elif [ "$POSITION" == 'right' ]
    then
      POSITION="-$template_cols weeks"
    fi
  fi

  local start="$( echo "$POSITION" | sed "s/ /\\\ /g" )"
  echo "$start"'\ +'{0..6}'\ days' | xargs -n 1 date --date | grep Sun
}

commit_work()
{
  local date_format='%Y-%m-%d'
  local start_date="$( date --date "$( start_date )" +$date_format )"
  local days=$(( $( wc --max-line-length < "$TEMPLATE" ) * 7 ))
  local date count

  for (( c = 0; c < "$days"; c++ ))
  do
    date=$( date --date "$start_date +$c day" +$date_format )
    count=$( day_count $c )
    commit_day_work "$date" "$count"
  done

  info "$MESSAGE"
}

random_time()
{
  local hours=$( printf %02d $(( $RANDOM % 24 )) )
  local minutes=$( printf %02d $(( $RANDOM % 60 )) )
  local seconds=$( printf %02d $(( $RANDOM % 60 )) )

  echo $hours:$minutes:$seconds
}

commit_day_work()
{
  local date="$1"
  local count="$2"
  local times

  info "Committing day work $date $count"

  for ((i = 1; i <= $count; i++))
  do
    times="$times $( random_time )"
  done

  for time in $( echo "$times" | tr " " "\n" | sort )
  do
   commit_a_work "$date" "$time"
  done
}

commit_a_work()
{
  local date="$1"
  local time="$2"

  if [ -n "$WRITE_FILE" ]
  then
    echo "$MESSAGE" >> "$REPOSITORY/$WRITE_FILE"
    git \
    --git-dir "$REPOSITORY/.git" \
    --work-tree "$REPOSITORY" \
    add \
    "$WRITE_FILE"
  fi

  git \
  --git-dir "$REPOSITORY/.git" \
  --work-tree "$REPOSITORY" \
  commit \
  --allow-empty \
  --message "$MESSAGE" \
  --author "$AUTHOR_NAME <$AUTHOR_EMAIL>" \
  --date "$date $time" \
  --quiet
}
