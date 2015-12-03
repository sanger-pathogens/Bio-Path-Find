
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Output;
use Test::Warn;
use Path::Class;
use File::Temp qw( tempdir );
use Archive::Tar;
use Cwd;
use Compress::Zlib;
use Digest::MD5 qw( md5_hex );

use Bio::Path::Find::Finder;

# don't initialise l4p here because we want to test that command line logging
# is correctly set up by the AppRole

use_ok('Bio::Path::Find::App::PathFind');

# set up a temp dir where we can write the archive
my $temp_dir = File::Temp->newdir;
dir( $temp_dir, 't' )->mkpath;
my $orig_cwd = getcwd;
symlink( "$orig_cwd/t/data", "$temp_dir/t/data") == 1
  or die "ERROR: couldn't link data directory into temp directory";
chdir $temp_dir;

# create a test log file and make sure it isn't already there
my $test_log = file($temp_dir, '_pathfind_test.log');
$test_log->remove;

#-------------------------------------------------------------------------------

# check filename collection

my %params = (
  environment      => 'test',
  config_file      => 't/data/12_pathfind_archiving/test.conf',
  id               => '10018_1',
  type             => 'lane',
  no_progress_bars => 1,
);

my $pf;
lives_ok { $pf = Bio::Path::Find::App::PathFind->new(%params) }
  'got a new pathfind app object';

# get the lanes using the Finder directly
my $f = Bio::Path::Find::Finder->new(
  environment => 'test',
  config_file => 't/data/12_pathfind_archiving/test.conf',
  lane_role   => 'Bio::Path::Find::Lane::Role::PathFind',
);

my $lanes = $f->find_lanes( ids => [ '10018_1' ], type => 'lane', filetype => 'fastq' );
is scalar @$lanes, 50, 'found 50 lanes with ID 10018_1 using Finder';

my @expected_filenames;
foreach my $lane ( @$lanes ) {
  push @expected_filenames, $lane->all_files;
}

# check against filenames from the app
my $got_filenames;
stdout_unlike { $got_filenames = $pf->_collect_filenames($lanes) }
  qr/finding files:\s+\d+\%/,
  'no progress bar for _collect_filenames when "no_progress_bars" true';

is_deeply $got_filenames, \@expected_filenames,
  'got expected list of filenames from _collect_filenames';

# check the progress bar, sort of
$params{no_progress_bars} = 0;
$pf = Bio::Path::Find::App::PathFind->new(%params);

stderr_like { $pf->_collect_filenames($lanes) }
  qr/finding files:\s+\d+\%/,
  'got progress bar for _collect_filenames';

#-------------------------------------------------------------------------------

# check the creation of a tar archive

%params = (
  environment      => 'test',
  config_file      => 't/data/12_pathfind_archiving/test.conf',
  id               => '10018_1',
  type             => 'lane',
  no_progress_bars => 1,
);

lives_ok { $pf = Bio::Path::Find::App::PathFind->new(%params) }
  'got a new pathfind app object';

my $archive;
lives_ok { $archive = $pf->_build_archive(\@expected_filenames) }
  'no problems adding files to archive';

my @archived_files = $archive->list_files;

is scalar @archived_files, 50, 'got expected number of files in archive';
is $archived_files[0], '10018_1/10018_1#1_1.fastq.gz', 'first file looks right';
is $archived_files[-1], '10018_1/10018_1#51_1.fastq.gz', 'last file looks right';

my $gzipped_data = $archive->get_content('10018_1/10018_1#1_1.fastq.gz');
my $raw_data = Compress::Zlib::memGunzip($gzipped_data);
is $raw_data, "some data\n", 'first file has expected content';

#---------------------------------------

# check the exception when we try to add a non-existent file to the archive

push @expected_filenames, file('bad_filename');

warnings_like { $pf->_build_archive(\@expected_filenames) }
  [
    { carped => qr/No such file:/ },
    { carped => qr/No such file in archive/ },
    { carped => qr/couldn't rename/ },
  ],
  'warnings when adding bogus file to archive';

pop @expected_filenames;

#---------------------------------------

# check renaming of files in the archive
%params = (
  environment      => 'test',
  config_file      => 't/data/12_pathfind_archiving/test.conf',
  id               => '10018_1',
  type             => 'lane',
  no_progress_bars => 1,
  rename           => 1,
);

lives_ok { $pf = Bio::Path::Find::App::PathFind->new(%params) }
  'no exception with "rename" option';

lives_ok { $archive = $pf->_build_archive(\@expected_filenames) }
  'no problems adding files to archive';

@archived_files = $archive->list_files;

is scalar @archived_files, 50, 'got expected number of files in archive';
is scalar( grep(m/\#/, @archived_files) ), 0, 'filenames have been renamed';

#-------------------------------------------------------------------------------

# check compression

%params = (
  environment      => 'test',
  config_file      => 't/data/12_pathfind_archiving/test.conf',
  id               => '10018_1',
  type             => 'lane',
  no_progress_bars => 1,
);

$pf = Bio::Path::Find::App::PathFind->new(%params);

my $data = file('t/data/12_pathfind_archiving/test_data.txt')->slurp;
my $compressed_data = $pf->_compress_data($data);
my $compressed_data_copy = $compressed_data; # because memGunzip hoses its input...
my $uncompressed_compressed_data = Compress::Zlib::memGunzip($compressed_data_copy);

is $uncompressed_compressed_data, $data, 'data same before and after compression';

is md5_hex($uncompressed_compressed_data), '8611ce14475a877d3acdbccf319360e1',
  'MD5 for uncompressed data is correct';

#-------------------------------------------------------------------------------

# check writing

my $filename = file( 'non-existent-dir', 'output.txt.gz' );

throws_ok { $pf->_write_data($compressed_data, $filename) }
  qr/couldn't write output file/,
  'exception when writing to non-existent directory';

$filename = file( $temp_dir, 'output.txt.gz' );

# write out the compressed tar file that we generated earlier
lives_ok { $pf->_write_data($compressed_data, $filename) }
  'no exception when writing file to valid directory';

my $slurped_file = $filename->slurp;
my $uncompressed_slurped_data = Compress::Zlib::memGunzip $slurped_file;

is $uncompressed_slurped_data, $data, 'file written to disk matches original';

#-------------------------------------------------------------------------------

# TODO integration tests. Check _make_archive.

$DB::single = 1;

done_testing;

chdir $orig_cwd;

exit;
