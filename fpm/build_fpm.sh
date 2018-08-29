#!/bin/bash

package_type="deb"
source="fpm_source"
fpm_scripts="fpm_scripts"
version="1.0.0"
arch="all"
extra_args=""

: ${ITERATION:="0"}
: ${WORKSPACE:="$(pwd)"}

if [[ -d $fpm_scripts ]]; then
  cd $fpm_scripts
  this_dir="$(pwd)"
  VERSION="$((cat VERSION 2>/dev/null || echo -n $version) | head -n1 )"
  ITERATION="$((cat ITERATION 2>/dev/null || echo -n $ITERATION) | head -n1 )"
  NAME="$((cat NAME 2>/dev/null || basename "${WORKSPACE}") | head -n1 )"
  ARCH="$((cat ARCH 2>/dev/null || echo -n $arch) | head -n1 )"
  RPM_PARAMS="$(cat RPM_PARAMS 2>/dev/null | head -n1 )"
  DEB_PARAMS="$(cat DEB_PARAMS 2>/dev/null | head -n1 )"
  COMMON_PARAMS="$(cat COMMON_PARAMS 2>/dev/null | head -n1 )"


  script_args=''
  for script_name in {before,after}-{install,remove,upgrade} ; do
  # We support package type specific directories.
  # First check if pacakge type specific file exists. If it does, use that.
  # Otherwise, look for the file in current directory
    if [[ -f $package_type/$script_name ]]; then
      script_args="${script_args} --${script_name} ${this_dir}/$package_type/${script_name}"
    elif [[ -f $script_name ]]; then
      script_args="${script_args} --${script_name} ${this_dir}/${script_name}"
    fi
  done
  # Validation
  if ! echo "${VERSION}" | egrep -q '^[0-9]+\.[0-9]+\.[0-9]+'; then
    echo "\'${VERSION}\' is not a valid version number."
    exit 1
  fi
  if ! echo "${NAME}" | egrep -q '^[a-zA-Z]+[a-zA-Z0-9_-]+$'; then
    echo "\'${NAME}\' is not a valid package name."
    exit 1
  fi


  # Process any dependencies
  DEPS=""
  depfile_name="$(echo $package_type | tr '[:lower:]' '[:upper:]')_DEPENDENCIES"
  if [[ -f $depfile_name ]]; then
    while read dep; do
        if [[ "${dep}" != "" ]]; then
            DEPS="${DEPS} -d \"${dep}\""
        fi
    done < $depfile_name
  fi

  # check for special DEB_PRE_DEPENDS or DEB_BUILD_DEPENDS files
  if [[ -f "DEB_PRE_DEPENDS" ]]; then
    DEPS="${DEPS} --deb-pre-depends \"$(cat DEB_PRE_DEPENDS)\""
  fi
  if [[ -f "DEB_BUILD_DEPENDS" ]]; then
    DEPS="${DEPS} --deb-build-depends \"$(cat DEB_BUILD_DEPENDS)\""
  fi

  MISC_PARAMS=""
  # Add other misc parameters if special files exist
  if [[ -f LICENSE ]]; then
    MISC_PARAMS="--license \"$(cat LICENSE)\""
  fi
  if [[ -f RPM_SUMMARY && "$package_type" == "rpm" ]]; then
    MISC_PARAMS="${MISC_PARAMS} --rpm-summary \"$(cat RPM_SUMMARY)\""
  fi
  if [[ -f CHANGELOG ]]; then
    MISC_PARAMS="${MISC_PARAMS} --$package_type-changelog ${this_dir}/CHANGELOG"
  fi
  if [[ -f DESCRIPTION ]]; then
    MISC_PARAMS="${MISC_PARAMS} --description \"$(cat DESCRIPTION)\""
  fi

  # Go back to source dir
  cd -
fi
# If ITERATION still isn't set, then use the build #
if [[ -z ${ITERATION} ]]; then
  ITERATION=$BUILD_NUMBER
fi
if ! echo "${ITERATION}" | egrep -q '^[0-9]+$'; then
  echo "\'${ITERATION}\' is not a valid number."
  exit 1
fi
PKG_PARAMS=""
if [[ "$package_type" == "deb" ]]; then
  PKG_PARAMS="${DEB_PARAMS}"
elif [[ "$package_type" == "rpm" ]]; then
  PKG_PARAMS="${RPM_PARAMS}"
else
  echo "'$package_type' is not a valid package type for this method"
  exit 1
fi

mkdir pkg

CMD="fpm -s dir -t ${package_type} -n ${NAME:-${WORKSPACE}} -v ${VERSION:-$version} --iteration ${ITERATION} -a ${ARCH:-$arch} ${script_args} ${PKG_PARAMS} ${DEPS} ${MISC_PARAMS} ${COMMON_PARAMS} $extra_args -p ${WORKSPACE}/pkg/ -C $source"
echo "Running command: '${CMD}'"
eval "${CMD}"

