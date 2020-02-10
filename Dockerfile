FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

LABEL maintainer=path-help@sanger.ac.uk


# docker-basher
ARG DOCKER_BASHER_VERSION=0.0.1
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
       libmysqlclient-dev

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
RUN $helper dzil_install_no_test https://github.com/sanger-pathogens/Bio-Track-Schema.git "${BIO_TRACK_SCHEMA_TAG}"

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

# Bio-Path-Find
COPY . /tmp/Bio-Path-Find_BUILD
RUN cd /tmp/Bio-Path-Find_BUILD \
    && dzil authordeps --missing | cpanm --notest \
    && dzil listdeps --missing | cpanm --notest \
    && dzil install \
    && rm -rf /tmp/Bio-Path-Find_BUILD

