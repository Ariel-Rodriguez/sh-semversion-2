# sh-semversion-2

SH script to compare versions using semversion 2.0 spec.

- highly-cross-compatible shell compliant with the POSIX standard.

- Semversion 2.0 compliant: https://semver.org/

#

| Method   | Command                                                                                                |
| :------- | :----------------------------------------------------------------------------------------------------- |
| **npx**  | `npx --no-install git+https://github.com/Ariel-Rodriguez/sh-semversion-2.git 1.0.0 2.0.0`              |
| **curl** | `curl https://raw.githubusercontent.com/Ariel-Rodriguez/sh-semversion-2/main/semver2.sh -o semver2.sh` |
| **wget** | `wget https://raw.githubusercontent.com/Ariel-Rodriguez/sh-semversion-2/main/semver2.sh`               |

###

<table>
<thead>
<tr>
<th>Param 1</th>
<th>Param 2</th>
</tr>
</thead>
<tbody>
<tr>
<td>1.0.0</td>
<td>0.1.0</td>
<td>1</td>
</tr>
<tr>
<td>1.0.0-alpha</td>
<td>1.0.0+metadata.build.1</td>
<td>-1</td>
</tr>
<tr>
<td>1.0.0+metadata.build.1</td>
<td>1.0.0+metadata.build.2</td>
<td>0</td>
</tr>
</tbody>
</table>

- When A greater than B: returns 1
- When A equals than B: returns 0
- When A lower than B:returns -1

# Usage

```sh
npx sh-semversion-2 1.0.0-rc.0.a+metadata v1.0.0-rc.0+metadata
# output 1
```

```sh
./semver2.sh 1.0.0-rc.0.a+metadata v1.0.0-rc.0+metadata
# output  1
```

## Tests

```sh
./test.sh print-only-failures
# abort on first failure match
./test.sh print-only-failures early-exit=true
```

```sh
# semver2.0 happy path tests ordered by precedence
# spec 11.4
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
```

```sh
OK 1.0.0-alpha = 1.0.0-alpha
OK 1.0.0-alpha < 1.0.0-alpha.1
OK 1.0.0-alpha < 1.0.0-alpha.beta
OK 1.0.0-alpha < 1.0.0-beta
OK 1.0.0-alpha < 1.0.0-beta.2
OK 1.0.0-alpha < 1.0.0-beta.11
OK 1.0.0-alpha < 1.0.0-rc.1
OK 1.0.0-alpha < 1.0.0+metadata.0.0.0
OK 1.0.0-alpha < 2.0.0-ALPHA
OK 1.0.0-alpha < 2.0.0-alpha
OK 1.0.0-alpha.1 > 1.0.0-alpha
OK 1.0.0-alpha.1 = 1.0.0-alpha.1
OK 1.0.0-alpha.1 < 1.0.0-alpha.beta
OK 1.0.0-alpha.1 < 1.0.0-beta
OK 1.0.0-alpha.1 < 1.0.0-beta.2
OK 1.0.0-alpha.1 < 1.0.0-beta.11
OK 1.0.0-alpha.1 < 1.0.0-rc.1
OK 1.0.0-alpha.1 < 1.0.0+metadata.0.0.0
OK 1.0.0-alpha.1 < 2.0.0-ALPHA
OK 1.0.0-alpha.1 < 2.0.0-alpha
OK 1.0.0-alpha.beta > 1.0.0-alpha
OK 1.0.0-alpha.beta > 1.0.0-alpha.1
OK 1.0.0-alpha.beta = 1.0.0-alpha.beta
OK 1.0.0-alpha.beta < 1.0.0-beta
OK 1.0.0-alpha.beta < 1.0.0-beta.2
OK 1.0.0-alpha.beta < 1.0.0-beta.11
OK 1.0.0-alpha.beta < 1.0.0-rc.1
OK 1.0.0-alpha.beta < 1.0.0+metadata.0.0.0
OK 1.0.0-alpha.beta < 2.0.0-ALPHA
OK 1.0.0-alpha.beta < 2.0.0-alpha
OK 1.0.0-beta > 1.0.0-alpha
OK 1.0.0-beta > 1.0.0-alpha.1
OK 1.0.0-beta > 1.0.0-alpha.beta
OK 1.0.0-beta = 1.0.0-beta
OK 1.0.0-beta < 1.0.0-beta.2
OK 1.0.0-beta < 1.0.0-beta.11
OK 1.0.0-beta < 1.0.0-rc.1
OK 1.0.0-beta < 1.0.0+metadata.0.0.0
OK 1.0.0-beta < 2.0.0-ALPHA
OK 1.0.0-beta < 2.0.0-alpha
OK 1.0.0-beta.2 > 1.0.0-alpha
OK 1.0.0-beta.2 > 1.0.0-alpha.1
OK 1.0.0-beta.2 > 1.0.0-alpha.beta
OK 1.0.0-beta.2 > 1.0.0-beta
OK 1.0.0-beta.2 = 1.0.0-beta.2
OK 1.0.0-beta.2 < 1.0.0-beta.11
OK 1.0.0-beta.2 < 1.0.0-rc.1
OK 1.0.0-beta.2 < 1.0.0+metadata.0.0.0
OK 1.0.0-beta.2 < 2.0.0-ALPHA
OK 1.0.0-beta.2 < 2.0.0-alpha
OK 1.0.0-beta.11 > 1.0.0-alpha
OK 1.0.0-beta.11 > 1.0.0-alpha.1
OK 1.0.0-beta.11 > 1.0.0-alpha.beta
OK 1.0.0-beta.11 > 1.0.0-beta
OK 1.0.0-beta.11 > 1.0.0-beta.2
OK 1.0.0-beta.11 = 1.0.0-beta.11
OK 1.0.0-beta.11 < 1.0.0-rc.1
OK 1.0.0-beta.11 < 1.0.0+metadata.0.0.0
OK 1.0.0-beta.11 < 2.0.0-ALPHA
OK 1.0.0-beta.11 < 2.0.0-alpha
OK 1.0.0-rc.1 > 1.0.0-alpha
OK 1.0.0-rc.1 > 1.0.0-alpha.1
OK 1.0.0-rc.1 > 1.0.0-alpha.beta
OK 1.0.0-rc.1 > 1.0.0-beta
OK 1.0.0-rc.1 > 1.0.0-beta.2
OK 1.0.0-rc.1 > 1.0.0-beta.11
OK 1.0.0-rc.1 = 1.0.0-rc.1
OK 1.0.0-rc.1 < 1.0.0+metadata.0.0.0
OK 1.0.0-rc.1 < 2.0.0-ALPHA
OK 1.0.0-rc.1 < 2.0.0-alpha
OK 1.0.0+metadata.0.0.0 > 1.0.0-alpha
OK 1.0.0+metadata.0.0.0 > 1.0.0-alpha.1
OK 1.0.0+metadata.0.0.0 > 1.0.0-alpha.beta
OK 1.0.0+metadata.0.0.0 > 1.0.0-beta
OK 1.0.0+metadata.0.0.0 > 1.0.0-beta.2
OK 1.0.0+metadata.0.0.0 > 1.0.0-beta.11
OK 1.0.0+metadata.0.0.0 > 1.0.0-rc.1
OK 1.0.0+metadata.0.0.0 = 1.0.0+metadata.0.0.0
OK 1.0.0+metadata.0.0.0 < 2.0.0-ALPHA
OK 1.0.0+metadata.0.0.0 < 2.0.0-alpha
OK 2.0.0-ALPHA > 1.0.0-alpha
OK 2.0.0-ALPHA > 1.0.0-alpha.1
OK 2.0.0-ALPHA > 1.0.0-alpha.beta
OK 2.0.0-ALPHA > 1.0.0-beta
OK 2.0.0-ALPHA > 1.0.0-beta.2
OK 2.0.0-ALPHA > 1.0.0-beta.11
OK 2.0.0-ALPHA > 1.0.0-rc.1
OK 2.0.0-ALPHA > 1.0.0+metadata.0.0.0
OK 2.0.0-ALPHA = 2.0.0-ALPHA
OK 2.0.0-ALPHA < 2.0.0-alpha
OK 2.0.0-alpha > 1.0.0-alpha
OK 2.0.0-alpha > 1.0.0-alpha.1
OK 2.0.0-alpha > 1.0.0-alpha.beta
OK 2.0.0-alpha > 1.0.0-beta
OK 2.0.0-alpha > 1.0.0-beta.2
OK 2.0.0-alpha > 1.0.0-beta.11
OK 2.0.0-alpha > 1.0.0-rc.1
OK 2.0.0-alpha > 1.0.0+metadata.0.0.0
OK 2.0.0-alpha > 2.0.0-ALPHA
OK 2.0.0-alpha = 2.0.0-alpha
```

# development

## How to debug

- Enable [DEBUG] messages

```sh
./semver2.sh v0.0.1 v0.0.1-rc debug
DEBUG: Detected: 0 0 1 identifiers:
DEBUG: Detected: 0 0 1 identifiers: rc
DEBUG: MAJOR are equal
DEBUG: MINOR are equal
DEBUG: PATCH are equal
DEBUG: Because releases without pre-release identifiers have higher precedence
1
```

- Enable verbose

```sh
./semver2.sh v0.0.1 v0.0.1-rc debug verbose
+ printf %s v0.0.1
+ cut -d+ -f 1
+ version_a=v0.0.1
+ removeLeadingV v0.0.1
+ printf %s0.0.1
+ version_a=0.0.1
+ printf %s v0.0.1-rc
+ cut -d+ -f 1
+ version_b=v0.0.1-rc
+ removeLeadingV v0.0.1-rc
+ printf %s0.0.1-rc
+ version_b=0.0.1-rc
+ printf %s 0.0.1
+ cut -d. -f 1
+ a_major=0
+ printf %s 0.0.1
+ cut -d. -f 2
+ a_minor=0
+ printf %s 0.0.1
+ + cut -d- -f 1
cut -d. -f 3
+ a_patch=1
+ a_pre=
+ includesString 0.0.1 -
+ string=0.0.1
+ substring=-
+ [ 0.0.1 != 0.0.1 ]
+ printf 0
+ return 0
+ [ 0 = 1 ]
+ printf %s 0.0.1-rc
+ cut -d. -f 1
+ b_major=0
+ printf %s 0.0.1-rc
+ cut -d. -f 2
+ b_minor=0
+ printf %s 0.0.1-rc
+ cut -d. -f 3
+ cut -d- -f 1
+ b_patch=1
+ b_pre=
+ includesString 0.0.1-rc -
+ string=0.0.1-rc
+ substring=-
+ [ rc != 0.0.1-rc ]
+ printf 1
+ return 1
+ [ 1 = 1 ]
+ printf %s 0.0.1-rc
+ cut -d- -f 2
+ b_pre=rc
+ unit_types=MAJOR MINOR PATCH
+ a_normalized=0 0 1
+ b_normalized=0 0 1
+ debug Detected: 0 0 1 identifiers:
+ [ debug = debug ]
+ printf DEBUG: %sDetected: 0 0 1 identifiers:  \n
+ debug Detected: 0 0 1 identifiers: rc
+ [ debug = debug ]
+ printf DEBUG: %sDetected: 0 0 1 identifiers: rc \n
+ cursor=1
+ [ 1 -lt 4 ]
+ printf %s 0 0 1
+ cut -d  -f 1
+ a=0
+ printf %s 0 0 1
+ cut -d  -f 1
+ b=0
+ [ 0 != 0 ]
+ printf %s MAJOR MINOR PATCH
+ cut -d  -f 1
+ debug MAJOR are equal
+ [ debug = debug ]
+ printf DEBUG: %sMAJOR are equal \n
+ cursor=2
+ [ 2 -lt 4 ]
+ printf %s 0 0 1
+ cut -d  -f 2
+ a=0
+ printf %s 0 0 1
+ cut -d  -f 2
+ b=0
+ [ 0 != 0 ]
+ printf %s MAJOR MINOR PATCH
+ cut -d  -f 2
+ debug MINOR are equal
+ [ debug = debug ]
+ printf DEBUG: %sMINOR are equal \n
+ cursor=3
+ [ 3 -lt 4 ]
+ printf %s 0 0 1
+ cut -d  -f 3
+ a=1
+ printf %s 0 0 1
+ cut -d  -f 3
+ b=1
+ [ 1 != 1 ]
+ printf %s MAJOR MINOR PATCH
+ cut -d  -f 3
+ debug PATCH are equal
+ [ debug = debug ]
+ printf DEBUG: %sPATCH are equal \n
+ cursor=4
+ [ 4 -lt 4 ]
+ [ -z  ]
+ [ -z rc ]
+ [ -z  ]
+ debug Because releases without pre-release identifiers have higher precedence
+ [ debug = debug ]
+ printf DEBUG: %sBecause releases without pre-release identifiers have higher precedence \n
+ outcome 1
+ result=1
+ printf %s1\n
+ return
DEBUG: Detected: 0 0 1 identifiers:
DEBUG: Detected: 0 0 1 identifiers: rc
DEBUG: MAJOR are equal
DEBUG: MINOR are equal
DEBUG: PATCH are equal
DEBUG: Because releases without pre-release identifiers have higher precedence
1
```
