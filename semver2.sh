#!/bin/sh

# POSIX SH portable semver 2.0 comparison tool.
# Numeric prerelease identifiers sort before non-numeric identifiers;
# non-numeric identifiers are compared in ASCII order.
#
# Prints 1 when A is greater than B, 0 when equal, -1 when lower.
# Usage: ./semver2.sh 1.0.0-rc.0.a+metadata v1.0.0-rc.0+metadata
# Spec: https://semver.org/spec/v2.0.0.html

set -eu

debug() {
  if [ "$debug" = debug ]; then printf 'DEBUG: %s\n' "$1"; fi
}

ord() {
  printf '%d' "'$1"
}

isNumber() {
  case "$1" in
    ''|*[!0-9]*) printf 'false' ;;
    *) printf 'true' ;;
  esac
}

outcome() {
  printf '%s\n' "$1"
}

# Preserve the existing leading-zero extension without octal arithmetic.
normalizeZero() {
  next=$1
  while [ "${#next}" -gt 1 ] && [ "${next#0}" != "$next" ]; do
    next=${next#0}
  done
  printf '%s' "$next"
}

compareString() {
  while [ -n "$1" ] && [ -n "$2" ]; do
    rest_a=${1#?}
    rest_b=${2#?}
    ord_a=$(ord "${1%"$rest_a"}")
    ord_b=$(ord "${2%"$rest_b"}")
    if [ "$ord_a" -lt "$ord_b" ]; then
      printf '%s' -1
      return
    fi
    if [ "$ord_a" -gt "$ord_b" ]; then
      printf '1'
      return
    fi
    set -- "$rest_a" "$rest_b"
  done
  if [ -n "$1" ]; then
    printf '1'
  elif [ -n "$2" ]; then
    printf '%s' -1
  else
    printf '0'
  fi
}

compareNumber() {
  number_a=$(normalizeZero "$1")
  number_b=$(normalizeZero "$2")

  # SemVer puts no integer-size limit on numeric identifiers. Compare their
  # lengths, then their digits, instead of overflowing shell arithmetic.
  if [ "${#number_a}" -lt "${#number_b}" ]; then
    printf '%s' -1
  elif [ "${#number_a}" -gt "${#number_b}" ]; then
    printf '1'
  else
    compareString "$number_a" "$number_b"
  fi
}

semver_compare() {
  firstParam=$1
  secondParam=$2
  debug=${3:-1}
  verbose=${4:-1}

  if [ "$verbose" = verbose ]; then set -x; fi

  # Spec 10: build metadata never affects precedence.
  version_a=${firstParam%%+*}
  version_a=${version_a#v}
  version_b=${secondParam%%+*}
  version_b=${version_b#v}

  a_core=${version_a%%-*}
  b_core=${version_b%%-*}
  a_pre=${version_a#"$a_core"}
  a_pre=${a_pre#-}
  b_pre=${version_b#"$b_core"}
  b_pre=${b_pre#-}

  a_major=${a_core%%.*}
  a_rest=${a_core#*.}
  a_minor=${a_rest%%.*}
  a_patch=${a_rest#*.}
  b_major=${b_core%%.*}
  b_rest=${b_core#*.}
  b_minor=${b_rest%%.*}
  b_patch=${b_rest#*.}

  debug "Detected: $a_major $a_minor $a_patch identifiers: $a_pre"
  debug "Detected: $b_major $b_minor $b_patch identifiers: $b_pre"

  # Spec 11.2: the first different core component decides precedence.
  set -- MAJOR "$a_major" "$b_major" MINOR "$a_minor" "$b_minor" PATCH "$a_patch" "$b_patch"
  while [ "$#" -gt 0 ]; do
    result=$(compareNumber "$2" "$3")
    if [ "$result" != 0 ]; then
      debug "$1 is different"
      outcome "$result"
      return
    fi
    debug "$1 are equal"
    shift 3
  done

  # Spec 11.3: a normal release sorts after any prerelease.
  if [ -z "$a_pre" ] && [ -z "$b_pre" ]; then
    outcome 0
    return
  fi
  if [ -z "$a_pre" ]; then
    outcome 1
    return
  fi
  if [ -z "$b_pre" ]; then
    outcome -1
    return
  fi

  # Spec 11.4: consume every identifier, with no fixed field limit.
  while [ -n "$a_pre" ] || [ -n "$b_pre" ]; do
    a=${a_pre%%.*}
    b=${b_pre%%.*}
    debug "Comparing identifier $a with $b"

    # Equal prefixes: the version with more identifiers sorts later.
    if [ -z "$a" ]; then
      outcome -1
      return
    fi
    if [ -z "$b" ]; then
      outcome 1
      return
    fi

    a_numeric=$(isNumber "$a")
    b_numeric=$(isNumber "$b")
    if [ "$a_numeric" = true ] && [ "$b_numeric" = true ]; then
      result=$(compareNumber "$a" "$b")
    elif [ "$a_numeric" = true ]; then
      result=-1
    elif [ "$b_numeric" = true ]; then
      result=1
    else
      result=$(compareString "$a" "$b")
    fi
    if [ "$result" != 0 ]; then
      outcome "$result"
      return
    fi

    case "$a_pre" in
      *.*) a_pre=${a_pre#*.} ;;
      *) a_pre='' ;;
    esac
    case "$b_pre" in
      *.*) b_pre=${b_pre#*.} ;;
      *) b_pre='' ;;
    esac
  done
  outcome 0
}

if [ "$#" -lt 2 ]; then
  printf 'Usage: %s VERSION_A VERSION_B [debug] [verbose]\n' "$0" >&2
  exit 1
fi

# Call directly so a comparison failure cannot be hidden by printf's status.
semver_compare "$@"
