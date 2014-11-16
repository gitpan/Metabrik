#
# $Id: Makefile.PL 354 2014-11-16 14:25:05Z gomor $
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
   },
);
