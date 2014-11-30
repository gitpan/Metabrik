#
# $Id: Log.pm 360 2014-11-25 06:50:22Z gomor $
#
# core::log Brik
#
package Metabrik::Core::Log;
use strict;
use warnings;

our $VERSION = '1.02';

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 360 $',
      tags => [ qw(core main log) ],
      attributes => {
         color => [ qw(0|1) ],
         level => [ qw(0|1|2|3) ],
      },
      attributes_default => {
         color => 1,
         level => 1,
      },
      commands => {
         info => [ qw(string) ],
         verbose => [ qw(string) ],
         warning => [ qw(string) ],
         error => [ qw(string) ],
         fatal => [ qw(string) ],
         debug => [ qw(string) ],
      },
      require_modules => {
         'Term::ANSIColor' => [ ],
      },
   };
}

sub _msg {
   my $self = shift;
   my ($brik, $msg) = @_;

   $msg ||= 'undef';

   $brik =~ s/^metabrik:://i;

   return lc($brik).": $msg\n";
}

sub warning {
   my $self = shift;
   my ($msg, $caller) = @_;

   if ($self->color) {
      print Term::ANSIColor::MAGENTA(), "[!] ", Term::ANSIColor::RESET();
   }
   else {
      print "[!] ";
   }

   print $self->_msg(($caller) ||= caller(), $msg);

   return 1;
}

sub error {
   my $self = shift;
   my ($msg, $caller) = @_;

   if ($self->color) {
      print Term::ANSIColor::RED(), "[-] ", Term::ANSIColor::RESET();
   }
   else {
      print "[-] ";
   }

   print $self->_msg(($caller) ||= caller(), $msg);

   return 0;
}

sub fatal {
   my $self = shift;
   my ($msg, $caller) = @_;

   if ($self->color) {
      print Term::ANSIColor::RED(), "[F] ", Term::ANSIColor::RESET();
   }
   else {
      print "[F] ";
   }

   die($self->_msg(($caller) ||= caller(), $msg));
}

sub info {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 0;

   if ($self->color) {
      print Term::ANSIColor::GREEN(), "[+] ", Term::ANSIColor::RESET();
   }
   else {
      print "[+] ";
   }

   $msg ||= 'undef';

   print "$msg\n";

   return 1;
}

sub verbose {
   my $self = shift;
   my ($msg, $caller) = @_;

   return 1 unless $self->level > 1;

   if ($self->color) {
      print Term::ANSIColor::YELLOW(), "[*] ", Term::ANSIColor::RESET();
   }
   else {
      print "[*] ";
   }

   print $self->_msg(($caller) ||= caller(), $msg);

   return 1;
}

sub debug {
   my $self = shift;
   my ($msg, $caller) = @_;

   # We have a conflict between the method and the accessor,
   # we have to identify which one is accessed.

   # If no message defined, we want to access the Attribute
   if (! defined($msg)) {
      return $self->{debug};
   }
   else {
      # If $msg is either 1 or 0, we want to set the Attribute
      if ($msg =~ /^(?:1|0)$/) {
         return $self->{debug} = $msg;
      }
      else {
         return 1 unless $self->level > 2;

         if ($self->color) {
            print Term::ANSIColor::CYAN(), "[D] ", Term::ANSIColor::RESET();
         }
         else {
            print "[D] ";
         }

         print $self->_msg(($caller) ||= caller(), $msg);
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Core::Log - core::log Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
