
install_blast() {
  local version=$1
  local directory=$2

  local archive=ncbi-blast-${version}+-x64-linux.tar.gz
  local url=ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/${version}/${archive}

  download_unarchive "${directory}" "${url}" "${archive}"

  return $?
}

install_cpanm_only() {
  local version=$1
  local directory=$2

  local temp_dir=$(tmp_dir)
  local archive=cpanminus-${version}.tar.gz
  local url=https://github.com/miyagawa/cpanminus/archive/${version}.tar.gz

  apt_install perl make \
  && download_unarchive "$temp_dir" "${url}" "${archive}" \
  && mv "${temp_dir}/cpanminus-${version}/cpanm" "${directory}" \
  && rm -rf "$temp_dir"
  return $?
}


install_samtools() {
  local version=$1
  local install_path=$2

  local archive=samtools-${version}.tar.bz2
  local url=https://sourceforge.net/projects/samtools/files/samtools/${version}/${archive}/download

  apt_install lbzip2 zlib1g libbz2-1.0 libncurses5 liblzma5 build-essential zlib1g-dev libncurses5-dev libbz2-dev liblzma-dev \
  && download_unarchive "${install_path}" "${url}" "${archive}" \
  && chmod 755 "${install_path}/samtools-${version}" \
  && cd "${install_path}/samtools-${version}" \
  && make \
  && apt_purge lbzip2 build-essential zlib1g-dev libncurses5-dev libbz2-dev liblzma-dev

  return $?
}

install_hmmer() {
  local version=$1
  local install_path=$2

  local name="hmmer-${version}"
  local archive="${name}.tar.gz"
  local url="http://eddylab.org/software/hmmer/${archive}"

  apt_install build-essential \
  && download_configure_make_install "${url}" "${archive}" "${name}" --enable-threads --prefix "${install_path}/${name}" \
  && apt_purge build-essential 

  return $?
}

install_rnammer() {
  local version=$1
  local install_path=$2
  local hmmsearch_location=$3

  local archive=rnammer-"${version}".src.tar.Z

  install_archive "${install_path}" "/tmp/${archive}" \
  && sed -i 's:/usr/cbs/bio/src/rnammer-'"${version}"':'"${install_path}"':g' "${install_path}/rnammer" \
  && sed -i 's:/usr/cbs/bio/bin/linux64/hmmsearch:'"${hmmsearch_location}"':g' "${install_path}/rnammer"

  return $?
}

install_aragorn() {
  local version=$1
  local install_path=$2

  local temp_dir=$(tmp_dir)
  local name="aragorn${version}"
  local archive="${name}.tgz"
  local url="http://mbio-serv2.mbioekol.lu.se/ARAGORN/Downloads/${archive}"

  apt_install build-essential \
  && download_unarchive "${temp_dir}" "${url}" "${archive}" \
  && cd "${temp_dir}/${name}" \
  && mkdir -p "${install_path}/${name}" \
  && gcc -O3 -ffast-math -finline-functions -o "${install_path}/${name}/aragorn" "aragorn${version}.c" \
  && chmod -R 755 "${install_path}/${name}" \
  && rm -rf "${temp_dir}" \
  && apt_purge build-essential

  return $?
}

install_tbl2asn() {
  local install_path=$1

  mkdir -p ${install_path} \
  && download_unzip ${install_path} ftp://ftp.ncbi.nih.gov/toolbox/ncbi_tools/converters/by_program/tbl2asn/linux64.tbl2asn.gz tbl2asn.gz \
  && chmod -R 755 ${install_path}

  return $?
}

install_prodigal() {
  local version=$1
  local install_path=$2

  install_direct_download "${install_path}" https://github.com/hyattpd/Prodigal/releases/download/v${version}/prodigal.linux prodigal \
  && chmod -R 755 "${install_path}"

  return $?
}
