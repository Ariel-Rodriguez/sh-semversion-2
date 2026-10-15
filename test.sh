#!/bin/sh

set -eu
set -f

script_dir=$(CDPATH='' cd -P "$(dirname "$0")" && pwd)
test_shell=${TEST_SHELL:-sh}
test_tmp=$(mktemp -d "${TMPDIR:-/tmp}/sh-semversion-2.XXXXXX")
trap 'rm -rf "$test_tmp"' 0
trap 'exit 1' 1 2 3 15

quiet=false
early_exit=false
for option do
  case "$option" in
    print-only-failures) quiet=true ;;
    early-exit=true) early_exit=true ;;
  esac
done

failcount=0
testscount=0

finish() {
  printf 'Total failures %s of %s tests\n' "$failcount" "$testscount"
  [ "$failcount" -eq 0 ]
}

record_result() {
  testscount=$((testscount + 1))
  if [ "$1" = true ]; then
    if [ "$quiet" = false ]; then printf 'OK %s\n' "$2"; fi
  else
    failcount=$((failcount + 1))
    printf 'FAILED %s\n' "$2"
    if [ -s "$test_tmp/stderr" ]; then cat "$test_tmp/stderr"; fi
    if [ "$early_exit" = true ]; then finish; exit 1; fi
  fi
}

# Exercise the real command, including its exit status and stderr.
assert_compare() {
  expected=$1
  shift
  status=0
  "$test_shell" "$script_dir/semver2.sh" "$@" >"$test_tmp/stdout" 2>"$test_tmp/stderr" || status=$?
  printf '%s\n' "$expected" >"$test_tmp/expected"
  if [ "$status" -eq 0 ] && cmp -s "$test_tmp/expected" "$test_tmp/stdout" && [ ! -s "$test_tmp/stderr" ]; then
    record_result true "$*: $expected"
  else
    actual=$(cat "$test_tmp/stdout")
    record_result false "$*: expected $expected followed by one newline, got '$actual' (status $status)"
  fi
}

assert_range_error() {
  status=0
  "$test_shell" "$script_dir/semver2.sh" --satisfies "$@" >"$test_tmp/stdout" 2>"$test_tmp/stderr" || status=$?
  passed=false
  if [ "$status" -eq 2 ] && [ ! -s "$test_tmp/stdout" ] && [ -s "$test_tmp/stderr" ]; then
    passed=true
  fi
  record_result "$passed" "invalid range check '$*': expected status 2, stderr and no stdout (status $status)"
}

assert_usage() {
  status=0
  "$test_shell" "$script_dir/semver2.sh" "$@" >"$test_tmp/stdout" 2>"$test_tmp/stderr" || status=$?
  passed=false
  if [ "$status" -ne 0 ] && [ ! -s "$test_tmp/stdout" ] && [ -s "$test_tmp/stderr" ]; then
    passed=true
  fi
  record_result "$passed" "missing arguments ($# supplied): expected failure with stderr and no stdout (status $status)"
}

# Spec 11.4 examples, in both directions.
set -- \
  1.0.0-alpha 1.0.0-alpha.1 \
  1.0.0-alpha 1.0.0-alpha.beta \
  1.0.0-alpha 1.0.0-beta \
  1.0.0-alpha 1.0.0-beta.2 \
  1.0.0-alpha 1.0.0-beta.11 \
  1.0.0-alpha 1.0.0-rc.1 \
  1.0.0-alpha 1.0.0 \
  1.0.0-alpha.1 1.0.0-alpha.beta \
  1.0.0-alpha.1 1.0.0-beta \
  1.0.0-alpha.1 1.0.0-beta.2 \
  1.0.0-alpha.1 1.0.0-beta.11 \
  1.0.0-alpha.1 1.0.0-rc.1 \
  1.0.0-alpha.1 1.0.0 \
  1.0.0-alpha.beta 1.0.0-beta \
  1.0.0-alpha.beta 1.0.0-beta.2 \
  1.0.0-alpha.beta 1.0.0-beta.11 \
  1.0.0-alpha.beta 1.0.0-rc.1 \
  1.0.0-alpha.beta 1.0.0 \
  1.0.0-beta 1.0.0-beta.2 \
  1.0.0-beta 1.0.0-beta.11 \
  1.0.0-beta 1.0.0-rc.1 \
  1.0.0-beta 1.0.0 \
  1.0.0-beta.2 1.0.0-beta.11 \
  1.0.0-beta.2 1.0.0-rc.1 \
  1.0.0-beta.2 1.0.0 \
  1.0.0-beta.11 1.0.0-rc.1

while [ "$#" -gt 0 ]; do
  assert_compare -1 "$1" "$2"
  assert_compare 1 "$2" "$1"
  shift 2
done

# Keep the original all-pairs precedence coverage and leading-zero extension.
versions='
1.0.0-0--1
1.0.0-0-0
1.0.0-0-0.alpha
1.0.0-0-1
1.0.0-alpha
1.0.0-alpha.1
1.0.0-alpha.beta
1.0.0-alpha.beta.1
1.0.0-beta
1.0.0-beta.2
1.0.0-beta.11
1.0.0-rc.1
1.0.0+metadata.0.0.0
2.0.0-ALPHA
2.0.0-alpha
02.00.01-alpha
02.00.01
02.00.10
02.01.00
02.10.00
'
i=0
for first in $versions; do
  j=0
  for second in $versions; do
    expected=0
    if [ "$i" -lt "$j" ]; then expected=-1; fi
    if [ "$i" -gt "$j" ]; then expected=1; fi
    assert_compare "$expected" "$first" "$second"
    j=$((j + 1))
  done
  i=$((i + 1))
done

# Regression pairs: equal and reverse comparisons are checked too.
while read -r expected first second; do
  assert_compare "$expected" "$first" "$second"
  assert_compare "$((-expected))" "$second" "$first"
  assert_compare 0 "$first" "$first"
done <<'CASES'
-1 1.0.0-alpha.beta.gamma.delta.1 1.0.0-alpha.beta.gamma.delta.2
-1 1.0.0-alpha.beta.gamma.delta 1.0.0-alpha.beta.gamma.delta.epsilon
-1 1.0.0-a.b.c.d.e.f.g.h.i.9 1.0.0-a.b.c.d.e.f.g.h.i.10
-1 1.0.0-a.b.c.d.e.f.g.h.i.1 1.0.0-a.b.c.d.e.f.g.h.i.alpha
-1 1.0.0-a.b.c.d.e.f.g.h.i.A 1.0.0-a.b.c.d.e.f.g.h.i.a
0 1.0.0-alpha.beta.gamma.delta.1+build.1 v1.0.0-alpha.beta.gamma.delta.1+build.2
0 0008.0009.0010 8.9.10
0 0000.00000.000000 0.0.0
-1 0008.0.0 0009.0.0
-1 1.0008.0 1.0009.0
-1 1.0.0008 1.0.0009
-1 9.0.0 10.0.0
-1 1.9.0 1.10.0
-1 1.0.9 1.0.10
-1 1.999.999 2.0.0
-1 1.1.999 1.2.0
-1 1.0.0 9223372036854775808.0.0
-1 1.0.0 18446744073709551616.0.0
-1 1.1.0 1.18446744073709551616.0
-1 1.0.1 1.0.18446744073709551616
-1 999999999999999999999998.0.0 999999999999999999999999.0.0
-1 1.0.0-1 1.0.0-18446744073709551616
-1 1.0.0-999999999999999999999998 1.0.0-999999999999999999999999
-1 1.0.0-999999999999999999999999 1.0.0-alpha
-1 1.0.0-- 1.0.0-A
-1 1.0.0-A 1.0.0-Z
-1 1.0.0-Z 1.0.0-a
-1 1.0.0-alpha 1.0.0-alphaa
-1 1.0.0-1 1.0.0-1a
-1 1.0.0-9 1.0.0-10
-1 1.0.0-1.2 1.0.0-1.2.0
-1 1.0.0-alpha+build.1 1.0.0+build.0
0 1.0.0+metadata.build.1 1.0.0+metadata.build.2
0 1.0.0+build-with-hyphens 1.0.0
0 1.0.0-rc.1+001 1.0.0-rc.1+999
0 v1.0.0 1.0.0
0 v1.0.0-rc.0 1.0.0-rc.0
0 v1.0.0+meta 1.0.0+other
-1 v1.0.0-rc.9 1.0.0-rc.10
CASES

assert_usage
assert_usage 1.0.0

# Issue #1: caret/X-ranges use membership rather than version ordering.
while read -r expected version range; do
  assert_compare "$expected" --satisfies "$version" "$range"
done <<'RANGES'
1 1.2.3 ^1.2.3
1 1.9.9 ^1.2.3
0 1.2.2 ^1.2.3
0 2.0.0 ^1.2.3
0 0.9.9 ^1.2.3
1 0.2.3 ^0.2.3
1 0.2.99 ^0.2.3
0 0.2.2 ^0.2.3
0 0.3.0 ^0.2.3
0 1.0.0 ^0.2.3
1 0.0.3 ^0.0.3
0 0.0.2 ^0.0.3
0 0.0.4 ^0.0.3
1 0.0.0 ^0.0.0
0 0.0.1 ^0.0.0
1 1.99.99 ^1
0 2.0.0 ^1
1 0.99.99 ^0
0 1.0.0 ^0
1 0.0.99 ^0.0
0 0.1.0 ^0.0
1 1.2.0 ^1.2
1 1.9.9 ^1.2
0 1.1.99 ^1.2
1 0.0.99 ^0.0.x
0 0.1.0 ^0.0.x
1 0.99.99 ^0.x
0 1.0.0 ^0.x
1 1.99.99 ^1.2.x
0 2.0.0 ^1.2.x
1 9.9.9 ^*
1 0.0.0 *
1 9.9.9 *
1 9.9.9 x
1 9.9.9 X
1 4.0.0 4.x
1 4.99.99 4.x
0 3.99.99 4.x
0 5.0.0 4.x
1 4.1.9 4.X
1 4.1.9 4.*
1 4.1.9 4.x.x
1 4.1.9 4.*.*
1 4.2.0 4.2.x
1 4.2.99 4.2.x
0 4.1.99 4.2.x
0 4.3.0 4.2.x
1 4.2.9 4.2.X
1 4.2.9 4.2.*
1 4.99.99 4
0 5.0.0 4
1 4.2.99 4.2
0 4.3.0 4.2
1 1.2.3 1.2.3
0 1.2.4 1.2.3
0 1.2.2 1.2.3
0 1.2.3-beta *
0 4.2.0-beta 4.x
0 1.3.0-beta ^1.2.3
0 2.0.0-beta ^1.2.3
1 1.2.3-beta.2 ^1.2.3-beta.2
1 1.2.3-beta.3 ^1.2.3-beta.2
0 1.2.3-beta.1 ^1.2.3-beta.2
1 1.2.3 ^1.2.3-beta.2
1 1.3.0 ^1.2.3-beta.2
0 1.3.0-beta.3 ^1.2.3-beta.2
1 0.0.3-beta.2 ^0.0.3-beta
1 0.0.3 ^0.0.3-beta
0 0.0.4-alpha ^0.0.3-beta
1 1.2.3-beta 1.2.3-beta
0 1.2.3-beta.1 1.2.3-beta
0 1.2.3 1.2.3-beta
1 1.2.3+build.2 1.2.3+build.1
1 v1.5.0 ^v1.2.3
1 v4.2.3 v4.x
1 0004.0002.0003 4.2.x
1 4.2.3 0004.0002.x
1 1.2.3-alpha+build ^01.02.03-alpha+meta
1 18446744073709551616.9.9 ^18446744073709551616.0.0
0 18446744073709551617.0.0 ^18446744073709551616.0.0
1 1.18446744073709551616.9 1.18446744073709551616.x
0 1.18446744073709551617.0 1.18446744073709551616.x
1 0.0.18446744073709551616 ^0.0.18446744073709551616
0 0.0.18446744073709551617 ^0.0.18446744073709551616
RANGES

for invalid_version in '' 1.2 1.2.x 1.2.3.4 a.b.c 1.2.-3 1.2.3-01 1.2.3- 1.2.3+ 1.2.3-a..b 1.2.3+a..b '1.2.3+a%' '1.2.3-é' '1.2.3+é'; do
  assert_range_error "$invalid_version" '*'
done
for invalid_range in '' '^' '^v' '^^1.2.3' '~1.2.3' '>=1.0.0' '1.x || 2.x' 1.2.3.4 1..2 1.2. '^1.2.3-' '^1.2.3-01' '1.x-beta' '1.2.3+a%' 1.x.3 '*.2.3' '1.*.0' '^1.x.3' '^1.2.3-é'; do
  assert_range_error 1.2.3 "$invalid_range"
done
assert_range_error
assert_range_error 1.2.3
assert_range_error 1.2.3 '^1.2.3' extra
finish
