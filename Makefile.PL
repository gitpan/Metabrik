#
# $Id: Makefile.PL 358 2014-11-22 16:06:30Z gomor $
#
use ExtUtils::MakeMaker;

require v5.6.1;

WriteMakefile(
   NAME => 'Metabrik',
   VERSION_FROM => 'lib/Metabrik.pm',
   LICENSE => 'bsd',
   ABSTRACT_FROM => 'lib/Metabrik.pm',
   AUTHOR => 'GomoR <gomor_at_metabrik.org>',
   PREREQ_PM => {
      'local::lib' => 0,
      'Class::Gomor' => 0,
      'IO::All' => 0,
      'Data::Dump' => 0,
      'Lexical::Persistence' => 0,
      'File::HomeDir' => 0,
      'Module::Reload' => 0,
      'Term::Shell' => 0,
      'Term::ANSIColor' => 0,
      'File::Find' => 0,
      'Cwd' => 0,
   },
);
