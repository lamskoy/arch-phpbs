#!/bin/bash
set -e -o pipefail
#
declare -rgi build_sums=0
declare -rgi build_sourcepkg=0
#
declare -rg min_php=53
declare -rg max_php=81
#
declare -g packages=""
declare -g positional=()

# declares
declare -rg source_file="PKGBUILD_template.sh"

# exports
export SRCPKGDEST="${SRCPKGDEST:-packages-src}"
export PKGDEST="${PKGDEST:-packages}"
export LOGDEST="${LOGDEST:-logs}"
export SRCDEST="${SRCDEST:-sources}"

_error_message() {
    echo -e "\e[31mError: ${1}\e[0m";
}
_mode_message() {
    echo -e "\e[33m[MODE] ${1}\e[0m"
}
_build_message() {
    echo -e "\e[33m[BUILD] ${1}\e[0m"
}
_info_message() {
    echo -e "[\e[32mINFO\e[0m] ${1}\e[0m"
}
_cmd_message() {
    echo -e "[\e[34mCMD\e[0m] ${1}\e[0m"
}
_dir_message() {
    echo -e "[\e[34mDIR\e[0m] ${1}\e[0m"
}

_create_dir() {
    if [ ! -d "${1}" ]; then
        mkdir -p "${1}";
    fi
    if [ ! -d "${1}" ]; then
        _error_message "Cannot create/find directory ${1}"
        exit 1;
    fi
}

_process_package() {
    local phpbase=${1}
    local suffix=${2}
    package_name="php${phpbase}${suffix}"

    local newbuildfile='';
    _mode_message "Building ${package_name}"
    newbuildfile=$(mktemp "phpbuilder.XXXXXX")
    if [[ $? -ne 0 ]]; then
        _error_message "Cannot create temp file";
        exit 1;
    fi
    _info_message "Using temproray PKGBUILD file ${newbuildfile} for ${package_name}"
    cp "${source_file}" "${newbuildfile}"
    if [[ $? -ne 0 ]]; then
        _error_message "Cannot copy file to ${newbuildfile}";
        exit 1;
    fi
    sed -e "s/%PHPBASE%/${phpbase}/g; s/%SUFFIX%/${suffix}/g; s/[\t ]*$//g; s/\t/    /g" \
        -i "${newbuildfile}"
    builddir=$(mktemp -d "phpbuilder.XXXXXX")
    if [[ $? -ne 0 ]]; then
        _error_message "Cannot create temp dir for ${package_name}";
        exit 1;
    fi
    if ((build_sums)); then
        _info_message "Updating PKGBUILD ${newbuildfile} with sums for ${package_name}"
        BUILDDIR="${builddir}" \
            makepkg -g -p "${newbuildfile}" >> "${newbuildfile}"
        if [[ $? -ne 0 ]]; then
            _error_message "Error while building package sums file for ${package_name}";
            _cmd_message "Last command: makepkg -g -p ${newbuildfile} >> ${newbuildfile}";
            _dir_message "Last builddir: ${builddir}"
            exit 1;
        fi 
    fi 
    if ((build_sourcepkg)); then
        _info_message "Building source package from ${newbuildfile} for ${package_name}"
        BUILDDIR="${builddir}" \
            makepkg -Sf -p "${newbuildfile}"
        if [[ $? -ne 0 ]]; then
            _error_message "Error while building source package";
            _dir_message "Last buildfile: ${newbuildfile}";
            _dir_message "Last builddir: ${builddir}"
            exit 1;
        fi
    fi
    _info_message "Building binary package from ${newbuildfile} for ${package_name}"
    if ((build_sums)); then
        BUILDDIR="${builddir}" \
            makepkg --nocheck -Lsfc -p "${newbuildfile}"
    else
        BUILDDIR="${builddir}" \
            makepkg --skipinteg --nocheck -Lsfc -p "${newbuildfile}"
    fi
    if [[ $? -eq 0 ]];
        then rm -rf "${builddir}" "${newbuildfile}";
    else
        _error_message "Error while building binary package";
        _dir_message "Last buildfile: ${newbuildfile}";
        _dir_message "Last builddir: ${builddir}"
        exit 1;
    fi
}

_main() {
    local phpbase;
    local suffix;
    IFS=',' read -a package_versions <<< "$packages"
    _counter="${#package_versions[@]}"

    if [[ $_counter -eq 0 ]]; then
        _error_message "No package versions provided"
        exit 1;
    fi
    _create_dir "${SRCPKGDEST}"
    _create_dir "${PKGDEST}"
    _create_dir "${LOGDEST}"
    _create_dir "${SRCDEST}"
    _info_message "Packages will be built to: \e[32m${PKGDEST}\e[0m"
    _info_message "Source packages will be built to: \e[32m${SRCPKGDEST}\e[0m"
    _info_message "Logs will be written to: \e[32m${LOGDEST}\e[0m"
    _info_message "Additional source code downloaded to: \e[32m${SRCDEST}\e[0m"
    for i in "${package_versions[@]}"; do
        IFS="@" read phpbase suffix <<<$(echo -e "${i}")
        phpbase=$(echo $phpbase | sed -E 's/[a-zA-Z_\-]+//g')
        if ((phpbase < min_php && phpbase > max_php)); then
            _error_message "Cannot detect php base in ${i} expression";
            exit 1;
        fi
        _process_package ${phpbase} ${suffix}
    done
    _info_message "Packages are built to: \e[32m${PKGDEST}\e[0m"
    _info_message "Source packages are be built to: \e[32m${SRCPKGDEST}\e[0m"
}

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -p|--packages)
      packages="$2"
      shift
      shift
      ;;
    -s|--sources)
      build_sourcepkg=1
      shift
      ;;
    *)
      positional+=("$1")
      shift
      ;;
  esac
done
set -- "${positional[@]}"

_main;

