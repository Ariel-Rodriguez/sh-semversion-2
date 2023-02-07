#!/bin/bash

set -u

# Include semver_compare tool
source ./semver2.sh

# specific target tests

isLowerThanSpec=(
  1.0.0-alpha 1.0.0-alpha.1
  # Spec 11.4.4: A larger set of pre-release fields has a higher precedence than a smaller set, if all of the preceding identifiers are equal.
  1.0.0-alpha 1.0.0-alpha.beta
  # Spec 11.4.2 Identifiers with letters or hyphens are compared lexically in ASCII sort order.
  1.0.0-alpha 1.0.0-beta
  1.0.0-alpha 1.0.0-beta.2
  1.0.0-alpha 1.0.0-beta.11
  1.0.0-alpha 1.0.0-rc.1
  # Spec 11.3 a pre-release version has lower precedence than a normal version
  1.0.0-alpha 1.0.0
  # Spec 11.4.3 Because Numeric identifiers always have lower precedence than non-numeric identifiers
  1.0.0-alpha.1 1.0.0-alpha.beta
  1.0.0-alpha.1 1.0.0-beta
  1.0.0-alpha.1 1.0.0-beta.2
  1.0.0-alpha.1 1.0.0-beta.11
  1.0.0-alpha.1 1.0.0-rc.1
  1.0.0-alpha.1 1.0.0
  1.0.0-alpha.beta 1.0.0-beta
  1.0.0-alpha.beta 1.0.0-beta.2
  1.0.0-alpha.beta 1.0.0-beta.11
  1.0.0-alpha.beta 1.0.0-rc.1
  1.0.0-alpha.beta 1.0.0
  1.0.0-beta 1.0.0-beta.2
  1.0.0-beta 1.0.0-beta.11
  1.0.0-beta 1.0.0-rc.1
  1.0.0-beta 1.0.0
  1.0.0-beta.2 1.0.0-beta.11
  1.0.0-beta.2 1.0.0-rc.1
  1.0.0-beta.2 1.0.0
  1.0.0-beta.11 1.0.0-rc.1
)

# -----
# brute force tests
#
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
  # leading zeroes
  02.00.01-alpha
  02.00.01
  02.00.10
  02.01.00
  02.10.00
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

  if [ "$3" != "$4" ]; then
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
  if [ -n "$reason" ]; then printf "1"; fi
}

exitcode=0
failcount=0
testscount=0

printf "\nSpecific target tests...\n\n"
for (( i=0; i<=$(( ${#isLowerThanSpec[@]} -1 )); i+=2 ))
do
  outcome=$(_assert_is "${isLowerThanSpec[i]}" "${isLowerThanSpec[i+1]}" "$(semver_compare "${isLowerThanSpec[i]}" "${isLowerThanSpec[i+1]}")" "-1")
  echo "$outcome"
  # increase failcount by 1
  testscount=$((testscount + 1))
  
  if [[ "$outcome" == "FAILED "* ]]; then
    failcount=$((failcount + 1))
    exitcode=1
    if [ -n "$*" ] && [ "$1" == "early-exit=true" ]; then
      break
    fi
  fi
done

printf "\n\nBrute force tests...\n\n"
for (( i=0; i<=$(( ${#tests[@]} -1 )); i+=1 ))
do
  for (( j=0; j<$(( ${#tests[@]} )); j+=1 ))
  do
    expected="0"
    if [ "$j" -lt "$i" ]; then expected="1"; fi
    if [ "$j" -gt "$i" ]; then expected="-1"; fi
    outcome=$(_assert_is "${tests[i]}" "${tests[j]}" "$(semver_compare "${tests[i]}" "${tests[j]}")" "$expected")
    
    # print outcome only if optional program parameter contains "print-only-failures"
    if [ -n "$*" ] && [[ "$*" == *"print-only-failures"* ]]; then
      if [[ "$outcome" == "FAILED "* ]]; then
        echo "$outcome"
      fi
      # print a progress bar
      printf "\r"
      printf "Progress: %s%%" "$((100 * i / ${#tests[@]}))"
    else
      printf "%s\n$outcome"
    fi

    # increase failcount by 1
    testscount=$((testscount + 1))
    
    if [[ "$outcome" == "FAILED "* ]]; then
      failcount=$((failcount + 1))
      exitcode=1
      if [ -n "$*" ] && [ "$1" == "early-exit=true" ]; then
        printf "\n%sTotal failures $failcount out of $testscount tests OK\n"
        exit $exitcode
      fi
    fi
  done
done

printf "\n%sTotal failures $failcount of $testscount tests OK\n"
exit $exitcode

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
