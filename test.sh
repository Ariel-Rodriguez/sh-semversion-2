#!/bin/bash

set -eu

# Include semver_compare tool
source ./semver2.sh 1.0.0 1.0.0

# semver2.0 happy path tests ordered by precedence
# spec 11.4
# 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0.
tests=(
  1.0.0-0--1
  1.0.0-0-0
  1.0.0-0-0.alpha
  1.0.0-0-1
  1.0.0-alpha
  1.0.0-alpha.1 
  1.0.0-alpha.beta 
  1.0.0-beta 
  1.0.0-beta.2 
  1.0.0-beta.11 
  1.0.0-rc.1 
  1.0.0+metadata.0.0.0
  2.0.0-ALPHA
  2.0.0-alpha
)

# others
  # 0.0.0+METADATA 0.0.0+METADATA.beta 0
  # 0.0.0 0.0.0 0
  # 0.0.1 0.0.0 1
  # 0.0.0 0.0.1 -1
  # 0.0.1-rc v0.0.1-rc 0
  # 0.0.1-rc.1 v0.0.1-rc 1
  # 0.0.1-rc.0 v0.0.1-rc.2 -1
  # v0.0.1-rc.0 0.0.1-rc.0 0
  # v0.0.1 v0.0.1-rc.2 1
  # v0.0.1 v0.0.1 0
  # v0.1.0-rc.0 0.1.0-rc.1 -1
  # 0.1.0-rc.1 v0.1.0-rc.1 0
  # v0.1.0 v0.1.0-rc.1 1
  # v0.1.0-rc.1 v0.1.0 -1
  # v0.1.0-rc.9 v0.1.0-rc.10 -1
  # v0.1.0-alpha v0.1.0-beta -1
  # v0.1.0-alpha.1 v0.1.0-beta.0 -1

_assert_is() {
  reason=""
  if [ $3 != $4 ]; then
    printf "FAILED "
    reason="expected to be $4 got $3"
  else
    printf "OK "
  fi
  case $4 in
    "-1")
      printf "%s" "$1 < $2"
      ;;
    "1")
      printf "%s" "$1 > $2"
      ;;
    *)
      printf "%s" "$1 = $2"
    ;;
  esac

  printf "%s $reason\n"
  if [ -n "$reason" ]; then exit 1; fi
}

for (( i=0; i<=$(( ${#tests[@]} -1 )); i+=1 ))
do
  for (( j=0; j<$(( ${#tests[@]} )); j+=1 ))
  do
    expected="0"
    if [ "$j" -lt "$i" ]; then expected="1"; fi
    if [ "$j" -gt "$i" ]; then expected="-1"; fi
    echo $(_assert_is ${tests[i]} ${tests[j]} $(semver_compare ${tests[i]} ${tests[j]}) "$expected")
  done
done

# OK 1.0.0-alpha < 1.0.0-alpha.1
# OK 1.0.0-alpha < 1.0.0-alpha.beta
# OK 1.0.0-alpha < 1.0.0-beta
# OK 1.0.0-alpha < 1.0.0-beta.2
# OK 1.0.0-alpha < 1.0.0-beta.11
# OK 1.0.0-alpha < 1.0.0-rc.1
# OK 1.0.0-alpha < 1.0.0
# OK 1.0.0-alpha.1 < 1.0.0-alpha.beta
# OK 1.0.0-alpha.1 < 1.0.0-beta
# OK 1.0.0-alpha.1 < 1.0.0-beta.2
# OK 1.0.0-alpha.1 < 1.0.0-beta.11
# OK 1.0.0-alpha.1 < 1.0.0-rc.1
# OK 1.0.0-alpha.1 < 1.0.0
# OK 1.0.0-alpha.beta < 1.0.0-beta
# OK 1.0.0-alpha.beta < 1.0.0-beta.2
# OK 1.0.0-alpha.beta < 1.0.0-beta.11
# OK 1.0.0-alpha.beta < 1.0.0-rc.1
# OK 1.0.0-alpha.beta < 1.0.0
# OK 1.0.0-beta < 1.0.0-beta.2
# OK 1.0.0-beta < 1.0.0-beta.11
# OK 1.0.0-beta < 1.0.0-rc.1
# OK 1.0.0-beta < 1.0.0
# OK 1.0.0-beta.2 < 1.0.0-beta.11
# OK 1.0.0-beta.2 < 1.0.0-rc.1
# OK 1.0.0-beta.2 < 1.0.0
# OK 1.0.0-beta.11 < 1.0.0-rc.1
# OK 1.0.0-beta.11 < 1.0.0
# OK 1.0.0-rc.1 < 1.0.0
