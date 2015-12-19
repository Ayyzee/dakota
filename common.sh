#!/bin/bash
set -o nounset -o pipefail

platform() {
    sysname=
    os_type_linux_regex=".*(L|l)inux.*"
    os_type_darwin_regex=".*(D|d)arwin.*"

    # sysname: first try env var OSTYPE
    if   [[ -n "${OSTYPE-}" && $OSTYPE =~ $os_type_linux_regex ]]; then
        sysname=linux
    elif [[ -n "${OSTYPE-}" && $OSTYPE =~ $os_type_darwin_regex ]]; then
        sysname=darwin
    fi
    # sysname: second try uname cmd
    if [[ -z "${sysname-}" && $(type uname) ]]; then
        name=$(uname -s)
        if   [[ $name =~ $os_type_linux_regex ]]; then
            sysname=linux
        elif [[ $name =~ $os_type_darwin_regex ]]; then
            sysname=darwin
        fi
    fi
    echo $sysname
}
compiler() {
    compiler=
    compiler_clangxx_regex=".*clang\+\+.*"
    compiler_gxx_regex=".*g\+\+.*"

    # compiler: first try env var CXX
    if   [[ -n "${CXX-}" && $CXX =~ $compiler_clangxx_regex ]]; then
        compiler=clang
    elif [[ -n "${CXX-}" && $CXX =~ $compiler_gxx_regex ]]; then
        compiler=gcc
    elif [[ -n "${CXX-}" ]]; then
        echo "attempting to use non-standard c++ compiler $CXX"
        compiler=$CXX
    fi
    # compiler: second try common dirs
    if [[ -z "${compiler-}" ]]; then
        clangxx_glob="/usr/bin/*clang++*"
        gxx_glob="/usr/bin/*g++*"
        clangxx=$(echo $clangxx_glob)
        gxx=$(echo $gxx_glob)
        if   [[ "$clangxx" != "$clangxx_glob" ]]; then
            compiler=clang
        elif [[ "$gxx"     != "$gxx_glob" ]]; then
            compiler=gcc
        fi
    fi
    echo $compiler
}
platform=$(platform)
compiler=$(compiler)

so_ext=so

CP=cp
CPFLAGS="--force --recursive"

LN=ln
LNFLAGS="--symbolic"

MKDIR=mkdir
MKDIRFLAGS="--parents"

RM=rm
RMFLAGS="--force --recursive"
