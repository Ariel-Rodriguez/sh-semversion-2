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

# Range checks validate their inputs without changing legacy comparisons.
validIdentifiers() {
  id_rest=$1
  while :; do
    id_part=${id_rest%%.*}
    case "$id_part" in
      ''|*[!0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-]*) return 1 ;;
    esac
    if [ "$2" = prerelease ] && [ "$(isNumber "$id_part")" = true ]; then
      case "$id_part" in 0?*) return 1 ;; esac
    fi
    case "$id_rest" in
      *.*) id_rest=${id_rest#*.} ;;
      *) return 0 ;;
    esac
  done
}

# Print a normalized full version, or fail without writing to stdout.
validatedVersion() {
  validation_value=${1#v}
  validation_version=${validation_value%%+*}
  case "$validation_value" in
    *+*) validIdentifiers "${validation_value#*+}" build || return 1 ;;
  esac
  validation_core=${validation_version%%-*}
  validation_pre=''
  case "$validation_version" in
    *-*)
      validation_pre=${validation_version#*-}
      validIdentifiers "$validation_pre" prerelease || return 1
      validation_pre=-$validation_pre
      ;;
  esac
  case "$validation_core" in *.*.*) ;; *) return 1 ;; esac
  validation_major=${validation_core%%.*}
  validation_rest=${validation_core#*.}
  validation_minor=${validation_rest%%.*}
  validation_patch=${validation_rest#*.}
  for validation_part in "$validation_major" "$validation_minor" "$validation_patch"; do
    if [ "$(isNumber "$validation_part")" != true ]; then return 1; fi
  done
  printf '%s.%s.%s%s' "$(normalizeZero "$validation_major")" \
    "$(normalizeZero "$validation_minor")" "$(normalizeZero "$validation_patch")" "$validation_pre"
}

rangeError() {
  printf 'Invalid range check: %s\n' "$1" >&2
  exit 2
}

# Supports a single exact, caret, or X-range. Prints 1 for a match, 0 otherwise;
# malformed/unsupported input exits 2. No arithmetic on version numbers is used.
semver_satisfies() {
  candidate=$(validatedVersion "$1") || rangeError "version '$1'"
  range_text=$2
  caret=false
  case "$range_text" in
    ^*) caret=true; range_text=${range_text#^} ;;
  esac
  range_text=${range_text#v}
  if [ -z "$range_text" ]; then rangeError "range '$2'"; fi
  range_without_build=${range_text%%+*}
  range_core=${range_without_build%%-*}
  range_qualifier=${range_text#"$range_core"}

  range_major=${range_core%%.*}
  range_minor=x
  range_patch=x
  case "$range_core" in
    *.*)
      range_rest=${range_core#*.}
      range_minor=${range_rest%%.*}
      case "$range_rest" in *.*) range_patch=${range_rest#*.} ;; esac
      ;;
  esac

  range_precision=0
  range_wildcard=false
  range_lower_core=''
  for range_part in "$range_major" "$range_minor" "$range_patch"; do
    case "$range_part" in
      x|X|'*') range_wildcard=true; range_number=0 ;;
      *)
        if [ "$(isNumber "$range_part")" != true ]; then rangeError "range '$2'"; fi
        if [ "$range_wildcard" = true ]; then rangeError "wildcards must be trailing: '$2'"; fi
        range_number=0
        if [ "$range_wildcard" = false ]; then
          range_precision=$((range_precision + 1))
          range_number=$(normalizeZero "$range_part")
        fi
        ;;
    esac
    range_lower_core=${range_lower_core:+$range_lower_core.}$range_number
  done
  if [ -n "$range_qualifier" ] && [ "$range_precision" -ne 3 ]; then
    rangeError "qualifiers require a full numeric range: '$2'"
  fi
  range_lower=$(validatedVersion "$range_lower_core$range_qualifier") || rangeError "range '$2'"
  candidate_core=${candidate%%-*}

  # npm-style prerelease admission: opt in with a prerelease on the same core.
  case "$candidate" in
    *-*)
      case "$range_lower" in
        *-*) if [ "$candidate_core" != "$range_lower_core" ]; then outcome 0; return; fi ;;
        *) outcome 0; return ;;
      esac
      ;;
  esac
  range_comparison=$(semver_compare "$candidate" "$range_lower")
  if [ "$range_comparison" = -1 ]; then outcome 0; return; fi

  # An exact range matches only equality, including prerelease identifiers.
  if [ "$caret" = false ] && [ "$range_precision" -eq 3 ]; then
    if [ "$range_comparison" = 0 ]; then outcome 1; else outcome 0; fi
    return
  fi

  # X-ranges fix the numeric prefix. Carets fix through the first nonzero
  # component, or through the last supplied component for an all-zero prefix.
  range_fixed=$range_precision
  if [ "$caret" = true ] && [ "$range_precision" -gt 0 ]; then
    range_fixed=0
    range_remaining=$range_lower_core
    while [ "$range_fixed" -lt "$range_precision" ]; do
      range_fixed=$((range_fixed + 1))
      if [ "${range_remaining%%.*}" != 0 ]; then break; fi
      range_remaining=${range_remaining#*.}
    done
  fi
  range_remaining=$range_lower_core
  candidate_remaining=$candidate_core
  while [ "$range_fixed" -gt 0 ]; do
    if [ "${candidate_remaining%%.*}" != "${range_remaining%%.*}" ]; then outcome 0; return; fi
    range_remaining=${range_remaining#*.}
    candidate_remaining=${candidate_remaining#*.}
    range_fixed=$((range_fixed - 1))
  done
  outcome 1
}

usage() {
  printf 'Usage: %s VERSION_A VERSION_B [debug] [verbose]\n' "$0" >&2
  printf '       %s --satisfies VERSION RANGE\n' "$0" >&2
}

if [ "${1:-}" = --satisfies ]; then
  if [ "$#" -ne 3 ]; then usage; exit 2; fi
  semver_satisfies "$2" "$3"
else
  if [ "$#" -lt 2 ]; then usage; exit 1; fi
  # Call directly so comparison failures cannot be hidden by printf's status.
  semver_compare "$@"
fi
