install_uk_locals() {
  apt_install locales \
  && locale-gen en_GB.UTF-8 \
  && apt_purge
}

tmp_dir() {
 local dir=$(mktemp -d -t basher-XXXXXXXXXX)
 echo $dir
}

cpan_install() {
  cpanm --notest "${@}"
}

install_archive() {
  local directory=$1
  local archive=$2

  mk_cd_dir "${directory}" && unarchive "${archive}"
  return $?

}

install_direct_download() {
  local directory=$1
  local url=$2
  local archive=$3

  mk_cd_dir "${directory}" \
  && download "${url}" "${archive}"
}

download_unarchive() {
  local directory=$1
  local url=$2
  local archive=$3

  mk_cd_dir "${directory}" \
    && download "${url}" "${archive}" \
    && unarchive "${archive}"
  return $?
}

download_unzip() {
  local directory=$1
  local url=$2
  local archive=$3

  mk_cd_dir "${directory}" \
    && download "${url}" "${archive}" \
    && gunzip "${archive}"
  return $?

}
mk_cd_dir() {
  local directory=$1

  mkdir -p "${directory}" && cd "${directory}"

  return $?
}

download() {
  local url=$1
  local archive=$2

  wget --no-check-certificate --progress=dot:giga "${url}" -O "${archive}"
  return $?
}

unarchive() {
  local archive=$1

  tar xf "${archive}" && rm "${archive}"
  return $?
}

apt_install_cleanly() {
  apt_install "${@}" \
  && apt_purge
}

apt_install() {
  export DEBIAN_FRONTEND=noninteractive

  ( fast_mode || apt-get update ) \
  && apt-get install -y -qq "${@}" \
  && ( fast_mode || apt-get clean ) \
  && ( fast_mode || rm -rf /var/lib/apt/lists/* )
  return $?  
}

apt_purge() {
  export DEBIAN_FRONTEND=noninteractive

  apt-get purge -y -qq "${@}"  \
  && ( fast_mode || apt-get -y -qq autoremove )
}

basher_setup() {
  fast_mode && apt-get update
  apt_install wget apt-utils
}

fast_mode() {
  [[ "${BASHER_FAST}" == "true" || "${BASHER_FAST}" == "TRUE" ]] && return 0
  return 1
}

link_executables() {
  local source=$1
  local destination=$2

  mk_cd_dir "${destination}" \
  && find "${source}" -perm -111 -type f -exec readlink -f {} \; | xargs -L1 -I {} ln -s {} .
  return $?
}

link_selected_executables() {
  local source=$1; shift
  local destination=$1; shift

  if [[ -z "${destination}" ]]; then
    return 0
  fi

  mk_cd_dir "${destination}"
  if [[ "$?" != "0" ]]; then
    return 1
  fi
  for var in "${@}"; do
    find "${source}" -perm -111 -type f -name "$var" -exec readlink -f {} \; | xargs -L1 -I {} ln -s {} .
    status=( "${PIPESTATUS[@]}" )
    if [[ "${status[0]}" != "0" || "${status[1]}" != "0" ]]; then
      echo "Failed to process executable $var"
      return 1
    fi
  done 
  return 0
}

cpanm_install() {
  cpanm --notest "${@}" \
  && rm -rf /root/.cpanm
}

configure_make_install() {
  local build_dir=$1; shift

  cd "${build_dir}" \
  && ./configure  "${@}" \
  && make \
  && make install
  return $?
}

download_configure_make_install() {
  local url=$1; shift
  local archive=$1; shift
  local build_dir=$1; shift
  local temp_dir=$(tmp_dir)

  download_unarchive "${temp_dir}" "${url}" "${archive}" \
  && configure_make_install "${temp_dir}/${build_dir}" "${@}" \
  && rm -rf "${temp_dir}"
  return $?
}

_git_clone() {
  local directory=$1
  local url=$2
  local branch=$3

  mkdir -p "${directory}" \
  && git clone "${url}" "${directory}" \
  && ( [[ "$branch" == "master" ]] || ( cd "${directory}" && git checkout $branch ) )

  return $?
}

_dzil_install() {
  local directory=$1
  local command=$2

  cd "${directory}" \
  && ( [ ! -z ${command+x} ] || dzil install ) \
  && ( [ -z ${command+x} ] || dzil install --install-command "$command" ) 

  return $?
}

dzil_install() {
  local url=$1
  local branch=$2
  local command=$3

  local temp_dir=$(tmp_dir)
 
  _git_clone "${temp_dir}" "${url}" "${branch}" \
  && cd "${temp_dir}" \
  && _dzil_install "${temp_dir}" "${command}" \
  && rm -rf "${temp_dir}"

  return $?
}

dzil_install_no_test() {
  local url=$1
  local branch=$2

  dzil_install "${url}" "${branch}" "cpanm --notest ."

  return $?
}


