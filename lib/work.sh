# Copyright (c) 2016 Damien Tardy-Panis
#
# This file is subject to the terms and conditions defined in
# file 'LICENSE', which is part of this source code package.
#
# Work related functions


################################################################################
# Initialize the work repository
# Globals:
#   FORCE
#   KEEP
#   REPLY
#   REPOSITORY
#   WRITE_FILE
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   0 if reset is not confirmed
################################################################################
work::init_repository() {
  if [[ -d "${REPOSITORY}" ]]; then
    if ! ${KEEP}; then
      local name=$( basename $( readlink --canonicalize -- "${REPOSITORY}" ) )
      local write_file_path="${REPOSITORY}/${WRITE_FILE}"

      if ! ${FORCE} && \
        ( [[ -d "${REPOSITORY}/.git" ]] || [[ -f "${write_file_path}" ]] ); then
        while true; do
          read -p "Confirm the reset of that \"${name}\" repository work? "
          case "${REPLY}" in
            yes|y) break ;;
            no|n) exit 0 ;;
            *) echo "Please answer yes or no." ;;
          esac
        done
      fi

      general::info "Resetting ${name} work repository"
      rm -rf -- "${REPOSITORY}/.git"
      [[ -z "${WRITE_FILE}" ]] || > "${write_file_path}"
    fi
  else
    general::info "Creating ${REPOSITORY} work repository"
    mkdir --parents -- "${REPOSITORY}"
  fi

  git --git-dir "${REPOSITORY}/.git" --work-tree "${REPOSITORY}" init --quiet
}


################################################################################
# Define the shade multiplier
# Globals:
#   GITHUB_USERNAME
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   Never
################################################################################
work::define_multiplier() {
  if [[ -n "${GITHUB_USERNAME}" ]]; then
    # Find lowest number of commits per day colored with darkest shade
    local count=$(
      curl --silent "https://github.com/${GITHUB_USERNAME}" \
        | grep data-count \
        | grep '#1e6823' \
        | sed --regexp-extended 's/.* data-count="([0-9]+)" .*/\1/' \
        | sort --unique --general-numeric-sort \
        | head --lines 1
    )
    [[ "${count}" -gt 0 ]] || count=1

    # Ceiling (division by number of indexes)
    SHADE_MULTIPLIER=$( printf %0.f $( echo "${count} / 4" | bc --mathlib ) )
  fi
}


################################################################################
# Define the start date of the work
# Globals:
#   POSITION
#   REPOSITORY
#   TEMPLATE
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   Never
################################################################################
work::define_start_date() {
  if [[ "${POSITION}" == 'last' ]]; then
    if [[ -d "${REPOSITORY}/.git" ]]; then
      # handle empty work repository by ignoring error output
      local last_author_timestamp=$(
        git \
        --git-dir "${REPOSITORY}/.git" \
        --work-tree "${REPOSITORY}" \
        log \
        --pretty="format:%at" \
        2> /dev/null \
          | sort --reverse \
          | head --lines 1
      )

      if [[ -n "${last_author_timestamp}" ]]; then
        POSITION=$( date -d @"${last_author_timestamp}" )
      else
        POSITION='left'
      fi
    else
      POSITION='left'
    fi
  fi

  local template_cols=$( wc --max-line-length < "${TEMPLATE}" )

  # Define approximate position if an identifier is used
  case "${POSITION}" in
    left)
      POSITION='-1 year'
      ;;
    center)
      POSITION="-53 weeks $(( (53 - ${template_cols})/2 )) weeks"
      ;;
    right)
      POSITION="-${template_cols} weeks"
      ;;
  esac

  # Find the closest Sunday
  local start="$( echo "${POSITION}" | sed "s/ /\\\ /g" )"

  POSITION=$(
    echo "${start}"'\ +'{0..6}'\ days' | xargs -n 1 date --date | grep Sun
  )
}


################################################################################
# Print a random time in the format HH:MM:SS
# Globals:
#   RANDOM
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   Never
################################################################################
work::random_time() {
  local hours=$( printf %02d $(( ${RANDOM} % 24 )) )
  local minutes=$( printf %02d $(( ${RANDOM} % 60 )) )
  local seconds=$( printf %02d $(( ${RANDOM} % 60 )) )

  echo ${hours}:${minutes}:${seconds}
}


################################################################################
# Print the commits count of a day
# Globals:
#   SHADE_MULTIPLIER
#   TEMPLATE
# Arguments:
#   - day number
# Returns:
#   None
# Exits:
#   Never
################################################################################
work::day_count() {
  local day_number="$1"
  local row=$(( ${day_number} % 7 + 1 ))
  local col=$(( ${day_number} / 7 + 1 ))
  local index=$(
    head --lines ${row} -- "${TEMPLATE}" \
      | tail --lines 1 \
      | head --bytes ${col} \
      | tail --bytes 1
  )

  echo $(( ${index} * ${SHADE_MULTIPLIER} ))
}


################################################################################
# Create all the work commits
# Globals:
#   AUTHOR_EMAIL
#   AUTHOR_NAME
#   MESSAGE
#   POSITION
#   REPOSITORY
#   SHADE_MULTIPLIER
#   TEMPLATE
#   VERBOSE
#   WRITE_FILE
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   Never
################################################################################
work::commit_all() {
  local date_format='%Y-%m-%d'
  local start_date="$( date --date "${POSITION}" +${date_format} )"
  local days=$(( $( wc --max-line-length < "${TEMPLATE}" ) * 7 ))
  local date count

  for (( c = 0; c < "${days}"; c++ )); do
    date=$( date --date "${start_date} +$c day" +${date_format} )
    count=$( work::day_count $c )
    work::commit_day "${date}" "${count}"
  done

  general::info "${MESSAGE}"
}


################################################################################
# Create all the work commits for a day
# Globals:
#   AUTHOR_EMAIL
#   AUTHOR_NAME
#   MESSAGE
#   REPOSITORY
#   VERBOSE
#   WRITE_FILE
# Arguments:
#   - day date in the format YYYY-MM-DD
#   - number of commits to create
# Returns:
#   None
# Exits:
#   Never
################################################################################
work::commit_day() {
  local date="$1"
  local count="$2"
  local times

  general::info "Committing day work ${date} ${count}"

  # Generate multiple random times to be sorted afterwards
  for ((i = 1; i <= ${count}; i++)); do
    times="${times} $( work::random_time )"
  done

  for time in $( echo "${times}" | tr " " "\n" | sort ); do
   work::commit_single "${date}" "${time}"
  done
}


################################################################################
# Create one work commit
# Globals:
#   AUTHOR_EMAIL
#   AUTHOR_NAME
#   MESSAGE
#   REPOSITORY
#   WRITE_FILE
# Arguments:
#   - commit date in the format YYYY-MM-DD
#   - commit time in the format HH:MM:SS
# Returns:
#   None
# Exits:
#   Never
################################################################################
work::commit_single() {
  local date="$1"
  local time="$2"

  if [[ -n "${WRITE_FILE}" ]]; then
    echo "${MESSAGE}" >> "${REPOSITORY}/${WRITE_FILE}"
    git \
    --git-dir "${REPOSITORY}/.git" \
    --work-tree "${REPOSITORY}" \
    add -- \
    "${WRITE_FILE}"
  fi

  git \
  --git-dir "${REPOSITORY}/.git" \
  --work-tree "${REPOSITORY}" \
  commit \
  --allow-empty \
  --message "${MESSAGE}" \
  --author "${AUTHOR_NAME} <${AUTHOR_EMAIL}>" \
  --date "${date} ${time}" \
  --quiet
}
