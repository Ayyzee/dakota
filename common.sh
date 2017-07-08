#!/bin/bash
set -o nounset -o pipefail

at() {
    keys=("${!1}")
    vals=("${!2}")
    key=$3
    for (( i=0; i < ${#keys[@]}; i++ )); do
        if [[ $key == "${keys[$i]}" ]]; then
            echo "${vals[$i]}"
            return 0
        fi
    done
    echo "$0: error: could not find value for key '$key'" 1>&2
    return 1
}
os_names[0]="linux";          os_names[1]="darwin"
os_regexs[0]=".*(L|l)inux.*"; os_regexs[1]=".*(D|d)arwin.*"

platform() {
    # first try env var OSTYPE
    for name in ${os_names[@]}; do
        regex=$(at os_names[@] os_regexs[@] $name)
        if [[ -n "${OSTYPE-}" && $OSTYPE =~ $regex ]]; then
            echo $name
            return 0
        fi
    done
    # second try uname cmd
    if [[ $(type uname) ]]; then
        name=$(uname -s)
        regex=$(at os_names[@] os_regexs[@] $name)
        if [[ $name =~ $regex ]]; then
            echo $name
            return 0
        fi
    fi
    echo "$0: error: could not determine platform" 1>&2
    return 1
}
compiler_names[0]="clang";              compiler_names[1]="gcc"
compiler_regexs[0]=".*clang\+\+.*";     compiler_regexs[1]=".*g\+\+.*"
compiler_globs[0]="/usr/bin/*clang++*"; compiler_globs[1]="/usr/bin/*g++*"

compiler() {
    if (( 0 < $# )); then
        CXX=$1
    fi

    # first try env var CXX
    for name in ${compiler_names[@]}; do
        regex=$(at compiler_names[@] compiler_regexs[@] $name)
        if [[ -n "${CXX-}" && $CXX =~ $regex ]]; then
            echo $name
            return 0
        elif [[ -n "${CXX-}" ]]; then
            echo $CXX
            return 0
        fi
    done

    # second try common dirs
    if [[ -z "${compiler-}" ]]; then
        for name in ${compiler_names[@]}; do
            glob=$(at compiler_names[@] compiler_globs[@] $name)
            match=$(echo $glob)
            if [[ "$match" != "$glob" ]]; then
                echo $name
                return 0
            fi
        done
    fi
    echo "$0: error: could not determine compiler" 1>&2
    return 1
}

CP=cp
CPFLAGS="--force --recursive"

LN=ln
LNFLAGS="--force --symbolic"

MKDIR=mkdir
MKDIRFLAGS="--parents"

RM=rm
RMFLAGS="--force --recursive"

DESTDIR=

INSTALL_PREFIX=/usr/local
INSTALL_BINDIR=$INSTALL_PREFIX/bin
INSTALL_LIBDIR=$INSTALL_PREFIX/lib
INSTALL_INCLUDEDIR=$INSTALL_PREFIX/include

so_ext=so

if [[ "darwin" == "$(platform)" ]]; then
    CPFLAGS="-fr"
    LNFLAGS="-fs"
    MKDIRFLAGS="-p"
    RMFLAGS="-fr"
    so_ext=dylib
fi
