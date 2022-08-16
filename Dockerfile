FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

LABEL maintainer=path-help@sanger.ac.uk


# docker-basher
ARG DOCKER_BASHER_VERSION=1.1.5
RUN apt-get update \
    && apt-get install curl -y -qq \
    && cd /tmp \
    && curl -fsSL  https://github.com/sanger-pathogens/docker-basher/archive/v${DOCKER_BASHER_VERSION}.tar.gz | tar xzf - 
ARG helper=/tmp/docker-basher-${DOCKER_BASHER_VERSION}/docker-basher.sh
RUN $helper basher_setup

# Ubuntu packages
RUN $helper install_uk_locals \
    \
    && $helper apt_install_cleanly \
       libdbd-mysql-perl \
       git \
       wget \
       build-essential \
       libxml2-dev \
       libexpat1-dev \
       libssl-dev \
       libdb-dev \
       cpanminus \
       libmysqlclient-dev \
       perl-doc

# Locals to keep Perl silent
ENV LANG=en_GB.UTF-8
ENV LANGUAGE=en_GB:en
ENV LC_ALL=en_GB.UTF-8

# Dist::Zilla
RUN $helper cpanm_install \
    Dist::Zilla \
    Module::Install

# Backward compatibility issue so enforcing version for now
RUN $helper cpanm_install MooseX::App@1.33


ARG BIO_TRACK_SCHEMA_TAG=d3b367c 
RUN $helper dzil_install_no_test https://gitlab.internal.sanger.ac.uk/sanger-pathogens/Bio-Track-Schema.git "${BIO_TRACK_SCHEMA_TAG}"

ARG BIO_SEQUENCESCAPE_SCHEMA_TAG=eb35104
RUN $helper dzil_install_no_test https://github.com/sanger-pathogens/Bio-Sequencescape-Schema.git "${BIO_SEQUENCESCAPE_SCHEMA_TAG}"

# Metagenomics has complex dependencies, so only taking what we need
ARG BIO_METAGENOMICS_TAG=2da80e0
RUN git clone https://github.com/sanger-pathogens/Bio-Metagenomics.git /tmp/bio-metagenomics \
    && cd /tmp/bio-metagenomics \
    && git checkout "${BIO_METAGENOMICS_TAG}" \
    && rm -rf t bin  lib/Bio/Metagenomics/CommandLine/ lib/Bio/Metagenomics/CreateLibrary.pm lib/Bio/Metagenomics/Genbank.pm  lib/Bio/Metagenomics/FileConvert.pm  lib/Bio/Metagenomics/TaxonRank.pm lib/Bio/Metagenomics/External/Metaphlan.pm lib/Bio/Metagenomics/External/Kraken.pm  \
    && sed -i '14,19 d' dist.ini \
    && dzil install \
    && rm -rf /tmp/bio-metagenomic

# some CPAN modules produce errors, and the install must be forced
# to avoid forcing every install (which in future builds may mask new errors) it's better to force only the problem modules
# this is done by first installing the problem module's dependencies (so that these aren't forced) and afterwards forcing the install of the problem module
RUN   for PROBLEM_MODULE in 'XML::DOM::XPath'; do \
         cpanm --installdeps ${PROBLEM_MODULE}; \
         cpanm --notest XML::DOM::XPath; \
      done

# undocumented Bio-Path-Find dependencies
# if these aren't installed causes Bio::Perl install to fail
# (specific errors manifest with Bio::AutomatedAnnotation::ParseGenesFromGFFs)
# this previously had been hidden as all CPAN installs were being done with --force
RUN   apt-get update && apt-get install --yes 'ncbi-blast+' prodigal parallel hmmer && \
      cpanm Bio::SearchIO::hmmer

# Bio-Path-Find
COPY . /tmp/Bio-Path-Find_BUILD

# RUN cd /tmp/Bio-Path-Find_BUILD \
#     && dzil authordeps --missing | cpanm  \
#     && dzil listdeps --missing | cpanm \
#     && dzil install \
#     && rm -rf /tmp/Bio-Path-Find_BUILD

RUN cd /tmp/Bio-Path-Find_BUILD \
    && dzil authordeps --missing | cpanm
# run cpanm on module one at a time to figure out which one is causing problems
RUN cd /tmp/Bio-Path-Find_BUILD \
    && for MODULE in `dzil listdeps --missing`; do cpanm "$MODULE"; done
RUN cd /tmp/Bio-Path-Find_BUILD \
    && dzil install \
    && rm -rf /tmp/Bio-Path-Find_BUILD

# check pf is installed and in PATH
RUN which pf > /dev/null
