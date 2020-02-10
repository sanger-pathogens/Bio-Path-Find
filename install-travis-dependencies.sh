#!/bin/bash

start_dir=$(pwd)
cpanm --local-lib=${PWD}/perl_modules local::lib && eval $(perl -I ${PWD}/perl_modules/lib/perl5/ -Mlocal::lib=${PWD}/perl_modules)

cpanm --notest \
  Dist::Zilla \
  Module::Install \
  MooseX::App@1.33

git clone https://github.com/sanger-pathogens/Bio-Metagenomics.git
git clone https://github.com/sanger-pathogens/Bio-Track-Schema.git
git clone https://github.com/sanger-pathogens/Bio-Sequencescape-Schema.git

cd Bio-Track-Schema
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest
dzil install

cd ../Bio-Sequencescape-Schema
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest
dzil install

cd ../Bio-Metagenomics
rm -rf t bin  lib/Bio/Metagenomics/CommandLine/ lib/Bio/Metagenomics/CreateLibrary.pm lib/Bio/Metagenomics/Genbank.pm  lib/Bio/Metagenomics/FileConvert.pm  lib/Bio/Metagenomics/TaxonRank.pm lib/Bio/Metagenomics/External/Metaphlan.pm lib/Bio/Metagenomics/External/Kraken.pm
sed -i '14,19 d' dist.ini
dzil install


cd $start_dir
dzil authordeps --missing | cpanm --notest
dzil listdeps --missing | cpanm --notest

