
package Bio::Path::Find::Lane::Role::Data;

# ABSTRACT: a role that adds pathfind-specific functionality to the B::P::F::Lane class

use Moose::Role;
use Path::Class;
use Carp qw( carp );

with 'Bio::Path::Find::Lane::Role::Stats';

=head1 DESCRIPTION

This L<Role|Moose::Role> provides functionality to
L<Lanes|Bio::Path::Find::Lane>, allowing them to find statistics and files for
sequencing data. This C<Role> provides the following methods for finding
files:

=over

=item _get_fastq

=item _get_corrected

=back

both of which are used for C<pathfind>-like searching for files.

The C<Role> also provides a mapping between filetype and file extension, via
the L<_build_filetype_extensions> builder. The mapping is:

  fastq     => '.fastq.gz',
  bam       => '*.bam',
  pacbio    => '*.h5',
  corrected => '*.corrected.*',

Finally, the C<Role> provides builders for attributes that generate stats about
sequencing lanes:

=over

=item _build_stats_header

=item _build_stats

=back

again, both of which are used to generate stats as provided by C<pathfind>.

=cut

#-------------------------------------------------------------------------------
#- builders --------------------------------------------------------------------
#-------------------------------------------------------------------------------

# build mapping between filetype and file extension. The mapping is specific
# to data files related to lanes, such as fastq or bam.

sub _build_filetype_extensions {
  {
    fastq     => '.fastq.gz',
    bam       => '*.bam', # NOTE no wildcard in mapping in original PathFind
    pacbio    => '*.h5',
    corrected => '*.corrected.*',
  };
}

#-------------------------------------------------------------------------------

# build an array of headers for the statistics display
#
# required by the Stats Role

sub _build_stats_headers {
  my $self = shift;

  return [
    'Study ID',
    'Sample',
    'Lane Name',
    'Cycles',
    'Reads',
    'Bases',
    'Map Type',
    'Reference',
    'Reference Size',
    'Mapper',
    'Mapstats ID',
    'Mapped %',
    'Paired %',
    'Mean Insert Size',
    'Depth of Coverage',
    'Depth of Coverage sd',
    'Adapter %',
    'Transposon %',
    'Genome Covered',
    'Duplication Rate',
    'Error Rate',
    'NPG QC',
    'Manual QC',
    'No. Het SNPs',
    '% Het SNPs (Total Genome)',
    '% Het SNPs (Genome Covered)',
    '% Het SNPs (Total No. of SNPs)',
    'QC Pipeline',
    'Mapping Pipeline',
    'Archiving Pipeline',
    'SNP Calling Pipeline',
    'RNASeq Pipeline',
    'Assembly Pipeline',
    'Annotation Pipeline',
  ];
}

#-------------------------------------------------------------------------------

# collect together the fields for the statistics display
#
# required by the Stats Role

sub _build_stats {
  my $self = shift;

  # shortcut to a hash containing Bio::Track::Schema::Result objects
  my $t = $self->_tables;

  return [
    $t->{project}->ssid,
    $t->{sample}->name,
    $t->{lane}->name,
    $t->{lane}->readlen,
    $t->{lane}->raw_reads,
    $t->{lane}->raw_bases,
    $self->_map_type,
    defined $t->{assembly} ? $t->{assembly}->name           : undef,
    defined $t->{assembly} ? $t->{assembly}->reference_size : undef,
    defined $t->{mapper}   ? $t->{mapper}->name             : undef,
    defined $t->{mapstats} ? $t->{mapstats}->mapstats_id    : undef,
    $self->_mapping_is_complete
      ? $self->_percentage( $t->{mapstats}->reads_mapped, $t->{mapstats}->raw_reads )
      : '0.0',
    $self->_mapping_is_complete
      ? $self->_percentage( $t->{mapstats}->reads_paired, $t->{mapstats}->raw_reads )
      : '0.0',
    $t->{mapstats}->mean_insert,
    $self->_depth_of_coverage,
    $self->_depth_of_coverage_sd,
    $self->_adapter_percentage,
    $self->_transposon_percentage,
    $self->_genome_covered,
    $self->_duplication_rate,
    $self->_error_rate,
    $t->{lane}->npg_qc_status,
    $t->{lane}->qc_status,
    $self->_het_snp_stats, # returns 4 values
    $self->pipeline_status('qc'),
    $self->pipeline_status('mapped'),
    $self->pipeline_status('stored'),
    $self->pipeline_status('snp_called'),
    $self->pipeline_status('snp_called'),
    $self->pipeline_status('assembled'),
    $self->pipeline_status('annotated'),
  ];
}

#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

sub _get_fastq {
  my $self = shift;

  $self->log->trace('looking for fastq files');

  # we have to save a reference to the "latest_files" relationship for each
  # lane before iterating over it, otherwise DBIC will continually return the
  # first row of the ResultSet
  # (see https://metacpan.org/pod/DBIx::Class::ResultSet#next)
  my $files = $self->row->latest_files;

  FILE: while ( my $file = $files->next ) {
    my $filename = $file->name;

    # for illumina, the database stores the names of the fastq files directly.
    # For pacbio, however, the database stores the names of the bax files. Work
    # out the names of the fastq files from those bax filenames
    $filename =~ s/\d\.ba[xs]\.h5$/fastq.gz/
      if $self->row->database->name =~ m/pacbio/;

    my $filepath = file( $self->symlink_path, $filename );

    if ( $filepath =~ m/fastq/ and
         $filepath !~ m/pool_1.fastq.gz/ ) {

      # the filename here is obtained from the database, so the file really
      # should exist on disk. If it doesn't exist, if the symlink in the root
      # directory tree is broken, we'll show a warning, because that indicates
      # a fairly serious mismatch between the two halves of the tracking system
      # (database and filesystem)
      unless ( -e $filepath ) {
        carp "ERROR: database says that '$filepath' should exist but it doesn't";
        next FILE;
      }

      $self->_add_file($filepath);
    }
  }
}

#-------------------------------------------------------------------------------

sub _get_corrected {
  my $self = shift;

  $self->log->trace('looking for "corrected" files');

  my $filename = $self->row->hierarchy_name . '.corrected.fastq.gz';
  my $filepath = file( $self->symlink_path, $filename );

  $self->_add_file($filepath) if -e $filepath;
}

#-------------------------------------------------------------------------------

1;

