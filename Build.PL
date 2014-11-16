#
# $Id: Build.PL 354 2014-11-16 14:25:05Z gomor $
#
use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
   module_name => 'Metabrik',
   license => 'bsd',
   dist_author => 'GomoR <gomor_at_metabrik.org>',
   dist_version_from => 'lib/Metabrik.pm',
   requires => {
   },
   configure_requires => {
      'Module::Build' => 0,
   },
);

$builder->create_build_script;
