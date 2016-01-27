
use strict;
use warnings;

use Test::More tests => 17;
use Test::Exception;
use Test::Output;
use Test::Warn;
use Path::Class;
use File::Temp qw( tempdir );
use Cwd;

# set up the "linked" directory for the test suite
use lib 't';

use Test::Setup;

unless ( -d dir( qw( t data linked ) ) ) {
  diag 'creating symlink directory';
  Test::Setup::make_symlinks;
}
use_ok('Bio::Path::Find::DatabaseManager');

use Bio::Path::Find::DatabaseManager;

use Log::Log4perl qw( :easy );

# initialise l4p to avoid warnings
Log::Log4perl->easy_init( $FATAL );

use_ok('Bio::Path::Find::Lane');

#---------------------------------------

# set up a DBM

my $config = {
  db_root           => dir(qw( t data linked )),
  connection_params => {
    tracking => {
      driver       => 'SQLite',
      dbname       => file(qw( t data pathogen_prok_track.db )),
      schema_class => 'Bio::Track::Schema',
    },
  },
};

my $dbm = Bio::Path::Find::DatabaseManager->new(
  config      => $config,
  schema_name => 'tracking',
);

my $database  = $dbm->get_database('pathogen_prok_track');
my $lane_rows = $database->schema->get_lanes_by_id('10018_1', 'lane');

is $lane_rows->count, 50, 'got 50 lanes';

my $lane_row = $lane_rows->first;
$lane_row->database($database);

#---------------------------------------

# check creation without a role

my $lane;
lives_ok { $lane = Bio::Path::Find::Lane->new( row => $lane_row ) }
  'no exception with valid row and no Role';

ok   $lane->has_no_files, '"has_no_files" true';
ok ! $lane->has_files,    '"has_files" false';

# the DatabaseManager should catch this when building the Database objects, but
# we also check in the Lane object to make sure that the root directory is
# visible. If it's not, there might be a probem with filesystem mounts
my $old_hrd = $database->hierarchy_root_dir;
$database->_set_hierarchy_root_dir(dir 'non-existent-dir');

throws_ok { $lane->root_dir }
  qr/can't see the filesystem root/,
  'exception with missing root directory';

$database->_set_hierarchy_root_dir($old_hrd);

is $lane->find_files('fastq'), 0, 'no files found without trait';

#---------------------------------------

# symlinking

# first, see if we can make symlinks in perl on this platform
my $symlink_exists = eval { symlink("",""); 1 }; # see perl doc for symlink

SKIP: {
  skip "can't create symlinks on this platform", 8 unless $symlink_exists;

  # set up a temp directory as the destination
  my $temp_dir = File::Temp->newdir;
  my $symlink_dir = dir $temp_dir;

  # should work
  lives_ok { $lane->make_symlinks( dest => $symlink_dir ) }
    'no exception when creating symlinks';

  my @files_in_temp_dir = $symlink_dir->children;
  is scalar @files_in_temp_dir, 1, 'found 1 link';
  like $files_in_temp_dir[0], qr/10018_1#1/, 'link looks correct';

  # should warn that link already exists
  warning_like { $lane->make_symlinks( dest => $symlink_dir ) }
    { carped => qr/is already a symlink/ },
    'warnings when symlinks already exist';

  # replace the symlink by a real file
  $files_in_temp_dir[0]->remove;
  $files_in_temp_dir[0]->touch;

  warning_like { $lane->make_symlinks( dest => $symlink_dir ) }
    { carped => qr/already exists/ },
    'warning when destination file already exists';

  $files_in_temp_dir[0]->remove;

  # set the permissions on the directory to remove write permission
  chmod 0500, $symlink_dir;

  warning_like { $lane->make_symlinks( dest => $symlink_dir ) }
    { carped => qr/failed to create symlink/ },
    'warnings when destination directory not writeable';

  # re-make the temp dir
  $temp_dir = File::Temp->newdir;
  $symlink_dir = dir $temp_dir;

  # create links in the cwd
  $temp_dir = File::Temp->newdir;
  $symlink_dir = dir $temp_dir;
  my $orig_cwd = cwd;
  chdir $symlink_dir;

  lives_ok { $lane->make_symlinks }
    'no exception when creating symlinks in working directory';

  # should be a link to the directory for the lane in the current working directory
  my $link = dir( $symlink_dir, '10018_1#1' );
  ok -l $link, 'found directory link';

  $link->rmtree;

  # (it would be nice to be able to verify that the link actually points to the
  # intended directory, but because the link is to a relative path, it's never
  # going to resolve properly.)
  $lane->make_symlinks( rename => 1 );

  ok -l dir( $symlink_dir, '10018_1_1' ), 'found renamed dir';

  chdir $orig_cwd;

}

done_testing;

