#!/bin/bash

PKG=${1:-faker}
OLD=${2:-4}
NEW=${3:-5}

assert_has() {
  if grep $1 $2 > /dev/null; then
    echo "OK: $2 $3"
  else
    echo "Failed at $2 $3"
    exit 1
  fi
}

assert_absent() {
  if grep $1 $2 > /dev/null; then
    echo "Failed at $2 $3"
    exit 1
  else
    echo "OK: $2 $3"
  fi
}

assert_near() {
  if grep $1 $2 $4 | grep "$3" > /dev/null; then
    echo "OK: $4 $5"
  else
    echo "Failed at $4 $5"
    exit 1
  fi
}

show() {
  echo "Running: $@"; $@
}

section() {
  echo
  echo $1
  echo $1 | tr -c "\n" "="
}

section "Installing fresh packages with ci"
(cd local-library && npm ci)
(cd dependent-project && npm ci)

section "Installing demo package"
show cd dependent-project
show npm install $PKG
  assert_has "faker.*^$NEW" package-lock.json "has $PKG @ $NEW"

section "Installing old version"
show npm install --no-save $PKG@$OLD
  assert_has "faker.*^$NEW" package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "faker" "\"$OLD" node_modules/.package-lock.json "has $PKG @ $OLD"
  assert_has "version.*\"$OLD" node_modules/faker/package.json "has $PKG @ $OLD"

section "Running npm install"
show npm install
  assert_has "faker.*^$NEW" package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "faker" "\"$NEW" node_modules/.package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "faker" "\"$NEW" node_modules/.package-lock.json "has $PKG @ $NEW"

section "Installing symlink dependency"
show npm install ../dependent-project
  assert_absent "ansi_styles" package-lock.json "doesn't have deps of local-library embedded"
  assert_has "local-library" package-lock.json "does have local-library installed"

section "Installing old version again"
show npm install --no-save $PKG@$OLD
  assert_has "faker.*^$NEW" package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "faker" "\"$OLD" node_modules/.package-lock.json "has $PKG @ $OLD"
  assert_has "version.*\"$OLD" node_modules/faker/package.json "has $PKG @ $OLD"

section "Running npm install"
show npm install
  assert_has "faker.*^$NEW" package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "faker" "\"$NEW" node_modules/.package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "faker" "\"$NEW" node_modules/.package-lock.json "has $PKG @ $NEW"

section "Removing symlink dependency"
show npm uninstall local-library
  assert_has "local-library" package-lock.json "has remnant local-library (?)"
