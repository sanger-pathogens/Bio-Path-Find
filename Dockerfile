FROM ubuntu:12.04.5

ARG DEBIAN_FRONTEND=noninteractive

LABEL maintainer=path-help@sanger.ac.uk

WORKDIR /tmp

# farm3+dpkg directory structure
ARG BIN_DIR=/software/pathogen/external/apps/usr/bin
ARG LOCAL_DIR=/software/pathogen/external/apps/usr/local
RUN mkdir -p $LOCAL_DIR $BIN_DIR /db/updates /db/info \
    && touch /db/status /db/available
ENV PATH=$BIN_DIR:$PATH

# basher
RUN mkdir /tmp/basher
COPY basher /tmp/basher
ARG helper=/tmp/basher/installer.sh
RUN $helper basher_setup

# Versions
ARG CPANM_VERSION=1.6918

# Ubuntu packages
RUN $helper basher_setup \
    \
    && $helper install_cpanm_only $CPANM_VERSION /usr/local/bin \
    \
    && $helper install_uk_locals \
    \
    && $helper apt_install_cleanly \
       libdbd-mysql-perl \
       git \
       wget \
       build-essential \
       libxml2-dev \
       libexpat1-dev \
       libssl-dev \
       libdb-dev


ENV LANG=en_GB.UTF-8
ENV LANGUAGE=en_GB:en
ENV LC_ALL=en_GB.UTF-8

ARG CPANM_VERSION=1.6918

RUN $helper install_cpanm_only $CPANM_VERSION /usr/local/bin \

COPY installer.sh /tmp/basher

# Dist::Zilla
RUN $helper cpanm_install \
      https://www.cpan.org/authors/id/A/AD/ADAMK/List-MoreUtils-0.33.tar.gz \
      File::ShareDir::Install@0.09 \
      ExtUtils::MakeMaker@6.98 \
      File::Remove@1.52 \
      Test::Object@0.07 \
      Test::Tester@0.114 \
      Test::NoWarnings@1.04 \
      Params::Util@1.07 \
      Hook::LexWrap@0.24 \
      Test::SubCalls@1.09 \
      Task::Weaken@1.04 \
      IO::String@1.08 \
      Clone@0.34 \
      Class::Inspector@1.28 \
      PPI@1.220 \
      Devel::FindPerl@0.011 \
      Module::Path@0.09 \
      Sub::Install@0.927 \
      Data::OptList@0.109 \
      Sub::Exporter@0.987 \
      String::RewritePrefix@0.006 \
      Try::Tiny@0.20 \
      Test::Fatal@0.010 \
      Test::Requires@0.06 \
      Module::Runtime@0.014 \
      Module::Implementation@0.06 \
      Params::Validate@1.07 \
      Getopt::Long::Descriptive@0.093 \
      Dist::CheckConflicts@0.02 \
      Package::DeprecationManager@0.13 \
      Package::Stash::XS@0.26 \
      MRO::Compat@0.12 \
      Package::Stash@0.34 \
      Class::Load@0.20 \
      Class::Load::XS@0.06 \
      Devel::StackTrace@1.34 \
      Eval::Closure@0.08 \
      Sub::Name@0.05 \
      Carp@1.26 \
      TAP::Harness::Env@3.30 \
      ExtUtils::Helpers@0.021 \
      ExtUtils::Config@0.007 \
      ExtUtils::InstallPaths@0.010 \
      Module::Build::Tiny@0.039 \
      Module::Runtime::Conflicts@0.001 \
      Sub::Exporter::Progressive@0.001010 \
      Devel::GlobalDestruction@0.11 \
      Moose@2.1213 \
      Variable::Magic@0.52 \
      B::Hooks::EndOfScope@0.12 \
      namespace::clean@0.24 \
      namespace::autoclean@0.13 \
      CPAN::Meta::Requirements@2.122 \
      Perl::PrereqScanner@1.018 \
      Test::Deep@0.110 \
      MooseX::SetOnce@0.200001 \
      Module::Build@0.4205 \
      aliased@0.31 \
      Module::Metadata@1.000026 \
      CPAN::Meta::YAML@0.011 \
      JSON::PP@2.27400 \
      Parse::CPAN::Meta@1.4422 \
      CPAN::Meta::Prereqs@2.150005 \
      CPAN::Meta::Check@0.012 \
      Test::CheckDeps@0.010 \
      MooseX::LazyRequire@0.10 \
      File::pushd@1.005 \
      Probe::Perl@0.02 \
      IPC::Run3@0.045 \
      Test::Script@1.07 \
      File::Which@1.09 \
      File::HomeDir@1.00 \
      Tie::IxHash@1.23 \
      MooseX::Role::Parameterized@1.02 \
      MooseX::OneArgNew@0.003 \
      strictures@1.004004 \
      Role::Tiny@1.003004 \
      Class::Method::Modifiers@2.04 \
      Import::Into@1.002000 \
      Moo@1.007000 \
      MooX::Types::MooseLike::Base@0.23 \
      StackTrace::Auto@0.200008 \
      Role::Identifiable::HasIdent@0.005 \
      JSON@2.59 \
      String::Formatter@0.102082 \
      String::Errf@0.006 \
      Role::HasMessage@0.005 \
      Config::MVP::Reader@2.200010 \
      Mixin::Linewise::Readers@0.102 \
      Sub::Uplevel@0.24 \
      Test::Exception@0.35 \
      Carp::Clan@6.04 \
      MooseX::Types@0.35 \
      Data::Section@0.200003 \
      Log::Dispatch::Output@2.39 \
      Log::Dispatch::Array@1.001 \
      Sub::Exporter::GlobExporter@0.003 \
      String::Flogger@1.101243 \
      Log::Dispatchouli@2.006 \
      Capture::Tiny@0.22 \
      Pod::Usage@1.63 \
      IO::TieCombine@1.002 \
      Getopt::Long@2.42 \
      App::Cmd::Tester::CaptureExternal@0.331 \
      Path::Tiny@0.096 \
      Number::Compare@0.03 \
      Text::Glob@0.09 \
      File::Find::Rule@0.33 \
      YAML::Tiny@1.50 \
      LWP::MediaTypes@6.01 \
      Encode::Locale@1.02 \
      URI@1.60 \
      HTTP::Date@6.00 \
      HTML::Tagset@3.20 \
      HTML::Parser@3.69 \
      HTTP::Status@6.00 \
      List::Util@1.45 \
      Net::SSLeay@1.78 \
      Mozilla::CA@20160104 \
      IO::Socket::SSL@2.038 \
      File::Listing@6.04 \
      HTTP::Negotiate@6.00 \
      HTTP::Daemon@6.00 \
      Net::HTTP@6.07 \
      HTTP::Cookies@6.00 \
      WWW::RobotRules@6.01 \
      LWP::UserAgent@6.06 \
      LWP::Protocol::https@6.06 \
      Term::ReadKey@2.31 \
      CPAN::Uploader@0.103004 \
      MooseX::Types::Perl@0.101341 \
      DateTime::Locale@0.45 \
      List::AllUtils@0.03 \
      Class::Singleton@1.4 \
      DateTime::TimeZone@1.75 \
      DateTime@1.12 \
      Pod::Eventual@0.093330 \
      Text::Template@1.46 \
      Software::License@0.103004 \
      ExtUtils::Manifest@1.70 \
      Test::Without::Module@0.17 \
      Cpanel::JSON::XS@2.3404 \
      JSON::MaybeXS@1.001000 \
      Config::INI::Reader@0.019 \
      Config::MVP::Reader::INI@2.101461 \
      Term::Encoding@0.02 \
      File::ShareDir@1.03 \
      Sub::Exporter::ForMethods@0.100050 \
      Dist::Zilla@6.006

RUN $helper cpanm_install \
      Test::Script::Run@0.08 \
      DBD::mysql@4.020

# dzil plugins
RUN $helper cpanm_install \
      IPC::System::Simple@1.21 \
      Scope::Guard@0.20 \
      String::Truncate@1.100600 \
      autobox@2.79 \
      syntax@0.004 \
      Syntax::Keyword::Junction@0.003004 \
      Moose::Autobox@0.13 \
      Pod::Elemental@0.103001 \
      Pod::Elemental::PerlMunger@0.200002 \
      Pod::Weaver@4.004 \
      Dist::Zilla::Plugin::PodWeaver@4.006 \
      Exporter::Tiny@0.042 \
      Type::Utils@1.000005 \
      Dist::Zilla::Role::GitConfig@0.92 \
      Version::Next@0.002 \
      MooseX::Has::Sugar@0.05070421 \
      Sort::Versions@1.5 \
      Git::Wrapper@0.029 \
      File::chdir@0.1008 \
      MooseX::CoercePerAttribute@0.802 \
      MooseX::Types::Common::String@0.001008 \
      MooseX::AttributeShortcuts@0.019 \
      MooseX::Types::Stringlike@0.003 \
      MooseX::Types::Path::Tiny@0.011 \
      Dist::Zilla::PluginBundle::Git@2.025 \
      Dist::Zilla::Role::PluginBundle::PluginRemover@0.103 \
      Safe::Isa@1.000004 \
      Class::Data::Inheritable@0.08 \
      Exception::Class@1.38 \
      Text::Diff@1.41 \
      Test::Differences@0.61 \
      Tree::DAG_Node@1.11 \
      Test::Warn@0.24 \
      Test::Most@0.34 \
      Hash::Merge::Simple@0.051 \
      Dist::Zilla::Util::ConfigDumper@0.003006 \
      Dist::Zilla::Role::MetaProvider::Provider@2.001002 \
      Data::Dump@1.22 \
      Dist::Zilla::Plugin::MetaProvides::Package@2.003001 \
      Dist::Zilla::Plugin::Test::ReportPrereqs@0.020 \
      Dist::Zilla::Plugin::Test::Compile@2.051 \
      Path::Iterator::Rule@1.008 \
      Dist::Zilla::Plugin::RunExtraTests@0.025 \
      Test::Pod@1.48 \
      Pod::Simple::HTML@3.29 \
      Pod::Markdown@2.002 \
      Dist::Zilla::Role::FileWatcher@0.005 \
      Dist::Zilla::Plugin::ReadmeAnyFromPod@0.150250 \
      Config::MVP::Slicer@0.302 \
      Dist::Zilla::Role::PluginBundle::Config::Slicer@0.201 \
      Dist::Zilla::PluginBundle::Starter@0.004 \
      Path::Class@0.32

# bio track schema
RUN $helper cpanm_install \
      DBD::SQLite@1.46 \
      String::CamelCase@0.02 \
      Class::Unload@0.08 \
      Lingua::EN::Inflect::Number@1.12 \
      Data::Dumper::Concise@2.020 \
      Config::Any@0.23 \
      Context::Preserve@0.01 \
      Class::XSAccessor@1.16 \
      Class::Accessor::Grouped@0.10010 \
      Hash::Merge@0.12 \
      SQL::Abstract@1.77 \
      Data::Compare@1.22 \
      Module::Find@0.11 \
      Class::Accessor@0.34 \
      Class::Accessor::Chained@0.01 \
      Data::Page@2.02 \
      Class::C3@0.23 \
      Class::C3::Componentised@1.001000 \
      DBIx::Class@0.08250 \
      Lingua::PT::Stemmer@0.01 \
      Lingua::Stem::It@0.02 \
      Lingua::Stem::Snowball::No@1.2 \
      Text::German@0.06 \
      Lingua::Stem::Snowball::Se@1.2 \
      Lingua::Stem::Fr@0.02 \
      Lingua::Stem::Snowball::Da@1.01 \
      Lingua::Stem::Ru@0.01 \
      Lingua::Stem@0.84 \
      Memoize::ExpireLRU@0.55 \
      Lingua::EN::Tagger@0.24 \
      Lingua::EN::FindNumber@1.2 \
      Lingua::EN::Number::IsOrdinal@0.04 \
      Lingua::EN::Inflect::Phrase@0.18 \
      Text::Unidecode@0.04 \
      String::ToIdentifier::EN@0.11 \
      DBIx::Class::IntrospectableM2M@0.001001 \
      DBIx::Class::Schema::Loader@0.07039 \
      File::Slurp@9999.19 \
      MooseX::MarkAsMethods@0.15 \
      MooseX::NonMoose@0.25 \
      Tie::ToObject@0.03 \
      Data::Visitor@0.28 \
      YAML@0.90 \
      Package::Variant@1.001004 \
      Parse::RecDescent@1.967009 \
      XML::Writer@0.623 \
      SQL::Translator@0.11016 \
      Test::MockTime@0.12 \
      boolean@0.32 \
      Module::Util@1.09 \
      DateTime::Format::Natural@1.02 \
      Set::Infinite@0.65 \
      DateTime::Set@0.31 \
      DateTime::Event::Recurrence@0.16 \
      DateTime::Event::ICal@0.11 \
      DateTime::Format::ICal@0.09 \
      DateTime::Format::Strptime@1.54 \
      Class::Factory::Util@1.7 \
      DateTime::Format::Builder@0.81 \
      DateTime::Format::Flexible@0.25 \
      DateTimeX::Easy@0.089 \
      DateTime::Format::SQLite@0.11 \
      DBIx::Class::Schema::PopulateMore@0.17 \
      Data::UUID@1.219 \
      DBIx::Class::UUIDColumns@0.02006 \
      DateTime::Format::MySQL@0.04 \
      DBICx::TestDatabase@0.04 \
      DBIx::Class::DynamicDefault@0.04 \
      Time::Warp@0.5 \
      DBIx::Class::TimeStamp@0.14 \
      MooseX::Attribute::ENV@0.02 \
      Test::DBIx::Class@0.41 

# bio path find
RUN $helper cpanm_install \
      Archive::Zip@1.37 \
      Config::General@2.52 \
      IO::Tty@1.10 \
      Expect@1.21 \
      IO::Interactive@0.0.6 \
      Log::Log4perl@1.41 \
      MooseX::Types::Path::Class@0.06 \
      MooseX::App@1.33 \
      IO::Scalar@2.110 \
      MooseX::Log::Log4perl@0.47 \
      MooseX::Singleton@0.29 \
      MooseX::StrictConstructor@0.19 \
      MooseX::Traits@0.12 \
      String::Approx@3.27 \
      UNIVERSAL::isa@1.20120726 \
      UNIVERSAL::can@1.20120726 \
      Test::MockObject@1.20120301 \
      Class::MethodMaker@2.18 \
      Term::ProgressBar@2.17 \
      Term::ProgressBar::Quiet@0.31 \
      Term::ProgressBar::Simple@0.03 \
      Test::LWP::UserAgent@0.026 \
      Test::Output@1.03 \
      Text::CSV_XS@1.21 \
      Text::Aligner@0.10 \
      Text::Table@1.130

# Automated Annotation dependency
RUN $helper cpanm_install \
      Text::CSV@1.32 \
      XML::NamespaceSupport@1.09 \
      XML::SAX::Base@1.07 \
      XML::SAX@0.99 \
      XML::Parser@2.44 \
      XML::SAX::Expat@0.40 \
      XML::Simple@2.22 \
      Env::Path@0.19 \
      File::Slurper@0.008 \
      Bio::Seq  \
      Bio::SeqFeature::Generic \
      Bio::PrimarySeq \
      Bio::SeqIO  \
      Bio::SearchIO  \
      Bio::Tools::GFF  \
      Bio::Perl  \
      Bio::AutomatedAnnotation@1.182770

RUN $helper dzil_install_no_test https://github.com/sanger-pathogens/Bio-Track-Schema.git master

RUN $helper dzil_install_no_test https://github.com/sanger-pathogens/Bio-Sequencescape-Schema.git master

RUN git clone https://github.com/sanger-pathogens/Bio-Metagenomics.git /tmp/bio-metagenomics \
    && cd /tmp/bio-metagenomics \
    && rm -rf t bin  lib/Bio/Metagenomics/CommandLine/ lib/Bio/Metagenomics/CreateLibrary.pm lib/Bio/Metagenomics/Genbank.pm  lib/Bio/Metagenomics/FileConvert.pm  lib/Bio/Metagenomics/TaxonRank.pm lib/Bio/Metagenomics/External/Metaphlan.pm lib/Bio/Metagenomics/External/Kraken.pm  \
    && sed -i '14,19 d' dist.ini \
    && dzil install \
    && rm -rf /tmp/bio-metagenomic

COPY . /tmp/Bio-Path-Find_BUILD
RUN cd /tmp/Bio-Path-Find_BUILD \
    && dzil install \
    && rm -rf /tmp/Bio-Path-Find_BUILD

