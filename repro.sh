#!/bin/bash

PKG=${1:-faker}
OLD=${2:-4}
NEW=${3:-5}

set -e

RED=$(tput setaf 1)
RESET=$(tput sgr0)

showerr() {
  echo "${RED}$1${RESET}"
}

assert_has() {
  if grep $1 $2 > /dev/null; then
    echo "OK: $2 $3"
  else
    showerr "Failed at $2 $3"
    return 1
  fi
}

assert_absent() {
  if grep $1 $2 > /dev/null; then
    showerr "Failed at $2 $3"
    return 1
  else
    echo "OK: $2 $3"
  fi
}

assert_near() {
  if grep $1 $2 $4 | grep "$3" > /dev/null; then
    echo "OK: $4 $5"
  else
    showerr "Failed at $4 $5"
    return 1
  fi
}

assert() {
  msg=$1
  shift;
  if $@ > /dev/null; then
    echo "OK: $msg"
  else
    showerr "Failed at $msg"
    return 1
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

reinit() {
  dir=$1
  shift
  rm -rf $dir
  mkdir $dir
  (cd $dir && npm init -y && npm install --save $@)
}

section "Reinitializing"
reinit local-library chalk
reinit dependent-project

section "Installing demo package"
show cd dependent-project
show npm install --save $PKG
  assert_has "$PKG.*^$NEW" package-lock.json "has $PKG @ $NEW"

section "Installing old version"
show npm install --no-save $PKG@$OLD
  assert_has "$PKG.*^$NEW" package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "$PKG" "\"$OLD" node_modules/.package-lock.json "has $PKG @ $OLD"
  assert_has "version.*\"$OLD" node_modules/$PKG/package.json "has $PKG @ $OLD"

section "Running npm install"
show npm install
  assert_has "$PKG.*^$NEW" package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "$PKG" "\"$NEW" node_modules/.package-lock.json "has $PKG @ $NEW"
  assert_has "version.*\"$NEW" node_modules/$PKG/package.json "has $PKG @ $NEW"

section "Installing symlink dependency"
show npm install --save ../local-library
  assert_absent "ansi_styles" package-lock.json "doesn't have deps of local-library embedded"
  assert_has "local-library" package-lock.json "does have local-library installed"

section "Installing old version after installing symlink"
show npm install --no-save $PKG@$OLD
  assert_has "$PKG.*^$NEW" package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "$PKG" "\"$OLD" node_modules/.package-lock.json "has $PKG @ $OLD"
  assert_has "version.*\"$OLD" node_modules/$PKG/package.json "has $PKG @ $OLD"

section "Running npm install after installing symlink"
show npm install
  assert_has "$PKG.*^$NEW" package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "$PKG" "\"$NEW" node_modules/.package-lock.json "has $PKG @ $NEW"
  assert_has "version.*\"$NEW" node_modules/$PKG/package.json "has $PKG @ $NEW"

section "Removing symlink dependency"
show npm uninstall local-library
  assert_has "local-library" package-lock.json "has remnant local-library (?)" || echo "(Skipping, not critical)"
  assert "local-library removed from node_modules" test ! -f node_modules/local-library

section "Installing old version after removing symlink"
show npm install --no-save $PKG@$OLD
  assert_has "$PKG.*^$NEW" package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "$PKG" "\"$OLD" node_modules/.package-lock.json "has $PKG @ $OLD"
  assert_has "version.*\"$OLD" node_modules/$PKG/package.json "has $PKG @ $OLD"

section "Running npm install after removing symlink"
show npm install
  assert_has "$PKG.*^$NEW" package-lock.json "has $PKG @ $NEW"
  assert_near -A1 "$PKG" "\"$NEW" node_modules/.package-lock.json "has $PKG @ $NEW"
  assert_has "version.*\"$NEW" node_modules/$PKG/package.json "has $PKG @ $NEW"
