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
    sysname=

    # sysname: first try env var OSTYPE
    for name in ${os_names[@]}; do
        regex=$(at os_names[@] os_regexs[@] $name)
        if [[ -n "${OSTYPE-}" && $OSTYPE =~ $regex ]]; then
            sysname=$name
        fi
    done
    # sysname: second try uname cmd
    if [[ -z "${sysname-}" && $(type uname) ]]; then
        name=$(uname -s)
        regex=$(at os_names[@] os_regexs[@] $name)
        if   [[ $name =~ $regex ]]; then
            sysname=$name
        fi
    fi
   echo $sysname
}
compiler() {
    if (( 0 < $# )); then
        CXX=$1
    fi
    compiler=
    compiler_clangxx_regex=".*clang\+\+.*"
    compiler_gxx_regex=".*g\+\+.*"

    # compiler: first try env var CXX
    if   [[ -n "${CXX-}" && $CXX =~ $compiler_clangxx_regex ]]; then
        compiler=clang
    elif [[ -n "${CXX-}" && $CXX =~ $compiler_gxx_regex ]]; then
        compiler=gcc
    elif [[ -n "${CXX-}" ]]; then
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

CP=cp
CPFLAGS="--force --recursive"

LN=ln
LNFLAGS="--force --symbolic"

MKDIR=mkdir
MKDIRFLAGS="--parents"

RM=rm
RMFLAGS="--force --recursive"

so_ext=so

if [[ "darwin" == "$(platform)" ]]; then
    CPFLAGS="-fr"
    LNFLAGS="-fs"
    MKDIRFLAGS="-p"
    RMFLAGS="-fr"
    so_ext=dylib
fi
