#
# $Id: Shell.pm,v 13f84766fbc9 2015/01/04 12:08:22 gomor $
#
# core::shell Brik
#
package Metabrik::Core::Shell;
use strict;
use warnings;

our $VERSION = '1.04';

use base qw(Term::Shell Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 13f84766fbc9 $',
      tags => [ qw(core main shell) ],
      attributes => {
         echo => [ qw(0|1) ],
         help_show_brik_commands => [ qw(0|1) ],
         help_show_brik_attributes => [ qw(0|1) ],
         comp_show_brik_attributes => [ qw(0|1) ],
         comp_show_brik_commands => [ qw(0|1) ],
         get_show_brik_attributes => [ qw(0|1) ],
         help_show_inherited => [ qw(0|1) ],
         comp_show_inherited => [ qw(0|1) ],
         # These are used by Term::Shell
         #path_home => [ qw(directory) ],
         #path_cwd => [ qw(directory) ],
         #prompt => [ qw(string) ],
         #_aliases => [ qw(INTERNAL) ],
      },
      attributes_default => {
         echo => 1,
         help_show_brik_commands => 0,
         help_show_brik_attributes => 0,
         comp_show_brik_attributes => 0,
         comp_show_brik_commands => 0,
         get_show_brik_attributes => 0,
         help_show_inherited => 0,
         comp_show_inherited => 0,
      },
      commands => {
         splash => [ ],
         pwd => [ ],
         cmd => [ qw(Cmd) ],
         cmdloop => [ ],
         run_use => [ qw(Brik) ],
         run_help => [ qw(Brik) ],
         run_set => [ qw(Brik Attribute Value) ],
         run_get => [ qw(Brik) ],
         run_run => [ qw(Brik Command) ],
         run_alias => [ qw(alias Cmd) ],
         run_cd => [ qw(directory) ],
         run_code => [ qw(Code) ],
         run_exit => [ ],
      },
      require_modules => {
         'Data::Dump' => [ qw(dump) ],
         'File::HomeDir' => [ ],
         'Cwd' => [ ],
      },
   };
}

sub new {
   # Call Term::Shell new()
   my $self = shift->SUPER::new(@_);

   # Call Metabrik new()
   $self->Metabrik::new(@_);

   # We have to set of default_attributes again normally called by Brik::new():
   # Otherwise default attributes are not set properly because of Perl inheritance scheme
   $self->brik_set_default_attributes;

   # Now write Term::Shell default values we gave, like context, global, log, ...
   my %h = @_;
   for my $k (keys %h) {
      $self->{$k} = $h{$k};
   }

   return $self;
}

sub brik_init {
   my $self = shift;

   my $context = $self->context;

   $self->debug && $self->log->debug("brik_init: start");

   if ($context->is_used('shell::rc')) {
      $self->debug && $self->log->debug("brik_init: load rc file");

      my $cmd = $context->run('shell::rc', 'load');
      for (@$cmd) {
         $self->cmd($_);
      }
   }

   $self->debug && $self->log->debug("brik_init: done");

   return $self->SUPER::brik_init;
}

sub splash {
   my $self = shift;

   my $con = $self->context;

   my $version = $con->run('core::global', 'brik_version');

   my $available_count = keys %{$con->available};
   my $used_count = keys %{$con->used};

   # ASCII art courtesy: http://patorjk.com/software/taag/#p=testall&f=Graffiti&t=MetabriK
   print<<EOF

        ███▄ ▄███▓▓█████▄▄▄█████▓ ▄▄▄       ▄▄▄▄    ██▀███   ██▓ ██ ▄█▀
       ▓██▒▀█▀ ██▒▓█   ▀▓  ██▒ ▓▒▒████▄    ▓█████▄ ▓██ ▒ ██▒▓██▒ ██▄█▒
       ▓██    ▓██░▒███  ▒ ▓██░ ▒░▒██  ▀█▄  ▒██▒ ▄██▓██ ░▄█ ▒▒██▒▓███▄░
       ▒██    ▒██ ▒▓█  ▄░ ▓██▓ ░ ░██▄▄▄▄██ ▒██░█▀  ▒██▀▀█▄  ░██░▓██ █▄
       ▒██▒   ░██▒░▒████▒ ▒██▒ ░  ▓█   ▓██▒░▓█  ▀█▓░██▓ ▒██▒░██░▒██▒ █▄
       ░ ▒░   ░  ░░░ ▒░ ░ ▒ ░░    ▒▒   ▓▒█░░▒▓███▀▒░ ▒▓ ░▒▓░░▓  ▒ ▒▒ ▓▒
       ░  ░      ░ ░ ░  ░   ░      ▒   ▒▒ ░▒░▒   ░   ░▒ ░ ▒░ ▒ ░░ ░▒ ▒░
       ░      ░      ░    ░        ░   ▒    ░    ░   ░░   ░  ▒ ░░ ░░ ░
              ░      ░  ░              ░  ░ ░         ░      ░  ░  ░
                                                 ░

--[ Welcome to Metabrik - Knowledge is in your head, Detail is in the code ]--
--[ Briks available: $available_count ]--
--[ Briks used: $used_count ]--
--[ Version $version ]--

    There is a Brik for that.

EOF
;

   return 1;
}

sub pwd {
   my $self = shift;

   return $self->{path_cwd};
}

#
# Term::Shell stuff
#
use IO::All;

our $AUTOLOAD;

sub AUTOLOAD {
   my $self = shift;
   my (@args) = @_;

   if ($AUTOLOAD !~ /^Metabrik::Core::Shell::run_/) {
      return 1;
   }

   (my $alias = $AUTOLOAD) =~ s/^Metabrik::Core::Shell:://;

   if ($self->debug) {
      $self->log->debug("autoload[$AUTOLOAD] alias[$alias] args[@args]");
   }

   #my $aliases = $self->_aliases;
   my $aliases = $self->{_aliases};
   if (exists($aliases->{$alias})) {
      my $cmd = $aliases->{$alias};
      return $self->cmd(join(' ', $cmd, @args));
   }

   return 1;
}

# Converts Windows path
sub _convert_path {
   my ($path) = @_;

   $path =~ s/\\/\//g;

   return $path;
}

#
# Term::Shell::main stuff
#
use Cwd;
use File::HomeDir;

sub _update_path_home {
   my $self = shift;

   #$self->path_home(_convert_path(home()));
   $self->{path_home} = _convert_path(File::HomeDir->my_home);

   return 1;
}

sub _update_path_cwd {
   my $self = shift;

   my $cwd = _convert_path(Cwd::getcwd());
   $self->debug && $self->log->debug("cwd [$cwd]");
   #my $home = $self->path_home;
   my $home = $self->{path_home};
   $self->debug && $self->log->debug("home [$home]");
   $cwd =~ s/^$home/~/;

   #$self->path_cwd($cwd);
   $self->{path_cwd} = $cwd;

   return 1;
}

sub _update_prompt {
   my $self = shift;
   my ($prompt) = @_;

   if (defined($prompt)) {
      #$self->prompt($prompt);
      $self->{prompt} = $prompt;
   }
   else {
      #my $cwd = $self->path_cwd;
      my $cwd = $self->{path_cwd};

      my $prompt = "Meta:$cwd> ";
      #my $prompt = "Meta> ";
      if ($^O =~ /win32/i) {
         $prompt =~ s/> /\$ /;
      }
      elsif ($< == 0) {
         $prompt =~ s/> /# /;
      }

      #$self->prompt($prompt);
      $self->{prompt} = $prompt;
   }

   return 1;
}

sub init {
   my $self = shift;

   $|++;

   $SIG{INT} = sub {
      $self->debug && $self->log->debug("init: INT caught");
      $self->run_exit;
      return 1;
   };

   $self->_update_path_home;
   $self->_update_path_cwd;
   $self->_update_prompt;

   # Default: 'us,ue,md,me', see `man 5 termcap' and Term::Cap
   # See also Term::ReadLine LoadTermCap() and ornaments() subs.
   $self->term->ornaments('md,me');

   return $self;
}

sub prompt_str {
   my $self = shift;

   #return $self->prompt;
   return $self->{prompt};
}

sub cmdloop {
   my $self = shift;

   $self->{stop} = 0;
   $self->preloop;

   my @lines = ();
   while (defined(my $line = $self->readline($self->prompt_str))) {
      push @lines, $line;

      if ($line =~ /\\\s*$/) {
         $self->_update_prompt('.. ');
         next;
      }

      # Multiline edition finished, we can remove the `\' char before joining
      for (@lines) {
         s/\\\s*$//;
      }

      $self->debug && $self->log->debug("cmdloop: lines[@lines]");

      $self->cmd(join('', @lines));
      @lines = ();
      $self->_update_prompt;

      last if $self->{stop};
   }

   $self->run_exit;

   return $self->postloop;
}

#
# Term::Shell::run stuff
#
sub run_exit {
   my $self = shift;

   my $context = $self->context;

   if ($context->is_used('shell::history')) {
      $context->run('shell::history', 'write');
   } 

   return $self->stoploop;
}

sub comp_exit {
   return ();
}

sub run_alias {
   my $self = shift;
   my ($alias, @cmd) = @_;

   #my $aliases = $self->_aliases;
   my $aliases = $self->{_aliases};

   if (! defined($alias)) {
      for my $this (keys %$aliases) {
         (my $alias = $this) =~ s/^run_//;
         $self->log->info(sprintf("%-10s \"%s\"", $alias, $aliases->{$this}));
      }

      return 1;
   }

   $aliases->{"run_$alias"} = join(' ', @cmd);
   #$self->_aliases($aliases);
   $self->{_aliases} = $aliases;

   $self->add_handler("run_$alias");

   return 1;
}

sub comp_alias {
   return ();
}

sub run_cd {
   my $self = shift;
   my ($dir, @args) = @_;

   if (defined($dir)) {
      if ($dir =~ /^~$/) {
         #$dir = $self->path_home;
         $dir = $self->{path_home};
      }
      if (! -d $dir) {
         return $self->log->error("cd: $dir: can't cd to this");
      }
      chdir($dir);
      $self->_update_path_cwd;
   }
   else {
      #chdir($self->path_home);
      chdir($self->{path_home});
      $self->_update_path_cwd;
   }

   $self->_update_prompt;

   return 1;
}

sub comp_cd {
   my $self = shift;
   my ($word, $line, $start) = @_;

   return $self->catch_comp_sub($word, $start, $line);
}

sub run_code {
   my $self = shift;

   my $context = $self->context;

   my $line = $self->line;
   $line =~ s/^code\s+//;

   if (! length($line)) {
      return $self->log->info('code <code>');
   }

   $self->debug && $self->log->debug("run_code: code[$line]");

   my $r = $context->do($line);
   if (! defined($r)) {
      return $self->log->error("run_code: unable to execute Code [$line]");
   }

   if ($self->echo) {
      $self->page(Data::Dump::dump($r)."\n");
   }

   return $r;
}

sub comp_code {
   my $self = shift;
   my ($word, $line, $start) = @_;

   return $self->catch_comp_sub($word, $start, $line);
}

sub run_use {
   my $self = shift;
   my ($brik, @args) = @_;

   my $context = $self->context;

   if (! defined($brik)) {
      return $self->log->info('use <brik>');
   }

   my $r;
   # If Brik starts with a minuscule, we want to use Brik in Metabrik sens.
   # Otherwise, it is a use command in the Perl sens.
   if ($brik =~ /^[a-z]/ && $brik =~ /::/) {
      $r = $context->use($brik) or return;
      if ($r) {
         $self->log->verbose("use: Brik [$brik] success");
      }
   }
   else {
      return $self->run_code($brik, @args);
   }

   return $r;
}

sub comp_use {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $self->context;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my @comp = ();

   # We want to find available Briks by using completion
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      my $available = $context->available;
      if ($self->debug && ! defined($available)) {
         $self->log->debug("\ncomp_use: can't fetch available Briks");
         return ();
      }

      for my $a (keys %$available) {
         push @comp, $a if $a =~ /^$word/;
      }
   }

   return @comp;
}

sub run_help {
   my $self = shift;
   my ($brik) = @_;

   my $context = $self->context;

   if (! defined($brik)) {
      return $self->SUPER::run_help;
   }
   else {
      if ($context->is_used($brik)) {
         my $used_brik = $context->used->{$brik};

         my $attributes = $used_brik->brik_attributes;
         my $commands = $used_brik->brik_commands;

         if (! $self->help_show_inherited) {
            $attributes = $used_brik->brik_properties->{attributes};
            $commands = $used_brik->brik_properties->{commands};
         }

         my $brik_attributes = Metabrik->brik_properties->{attributes};
         my $brik_commands = Metabrik->brik_properties->{commands};

         for my $attribute (keys %$attributes) {
            if (! $context->get('core::shell', 'help_show_brik_attributes')) {
               next if exists($brik_attributes->{$attribute});
            }
            my $help = $used_brik->brik_help_set($attribute);
            $self->log->info($help) if defined($help);
         }

         for my $command (keys %$commands) {
            if (! $context->get('core::shell', 'help_show_brik_commands')) {
               next if exists($brik_commands->{$command});
            }
            my $help = $used_brik->brik_help_run($command);
            $self->log->info($help) if defined($help);
         }
      }
      else {
         # We return to standard help() method
         return $self->SUPER::run_help($brik);
      }
   }

   return 1;
}

sub comp_help {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my @comp = ();

   # We want to find help for used briks by using completion
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      my @handlers = keys %{$self->{handlers}};
      my @used = keys %{$self->context->used};
      for my $a (@handlers, @used) {
         next unless length($a);
         push @comp, $a if $a =~ /^$word/;
      }
   }

   return @comp;
}

sub run_set {
   my $self = shift;
   my ($brik, $attribute, $value) = @_;

   my $context = $self->context;

   if (! defined($brik) || ! defined($attribute) || ! defined($value)) {
      return $self->log->info("set <brik> <attribute> <value>");
   }

   my $r = $context->set($brik, $attribute, $value);
   if (! defined($r)) {
      return $self->log->error("set: unable to set Attribute [$attribute] for Brik [$brik]");
   }

   return $r;
}

sub comp_set {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $self->context;

   # Completion is for used Briks only
   my $used = $context->used;
   if (! defined($used)) {
      $self->debug && $self->log->debug("comp_set: can't fetch used Briks");
      return ();
   }

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);

   if ($self->debug) {
      $self->log->debug("word[$word] line[$line] start[$start] count[$count]");
   }

   my $brik = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for used Briks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$used) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brik Attributes
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_set: Brik [$brik] not used");
            return ();
         }
      }

      my $brik_attributes = Metabrik->brik_properties->{attributes};
      my $attributes = $used->{$brik}->brik_attributes;

      if (! $self->comp_show_inherited) {
         $attributes = $used->{$brik}->brik_properties->{attributes};
      }

      for my $attribute (keys %$attributes) {
         if (! $context->get('core::shell', 'comp_show_brik_attributes')) {
            next if exists($brik_attributes->{$attribute});
         }
         push @comp, $attribute;
      }
   }
   # We want to complete entered Attribute
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_set: Brik [$brik] not used");
            return ();
         }
      }

      my $brik_attributes = Metabrik->brik_properties->{attributes};
      my $attributes = $used->{$brik}->brik_attributes;

      if (! $self->comp_show_inherited) {
         $attributes = $used->{$brik}->brik_properties->{attributes};
      }

      for my $attribute (keys %$attributes) {
         if (! $context->get('core::shell', 'comp_show_brik_attributes')) {
            next if exists($brik_attributes->{$attribute});
         }
         if ($attribute =~ /^$word/) {
            push @comp, $attribute;
         }
      }
   }
   # Else, default completion method on remaining word
   else {
      return $self->catch_comp_sub($word, $start, $line);
   }

   return @comp;
}

sub run_get {
   my $self = shift;
   my ($brik, $attribute) = @_;

   my $context = $self->context;

   # get is called without args, we display everything
   if (! defined($brik)) {
      my $used = $context->used or return;

      for my $brik (sort { $a cmp $b } keys %$used) {
         my $attributes = $used->{$brik}->brik_attributes or next;
         for my $attribute (sort { $a cmp $b } keys %$attributes) {
            if (! $context->get('core::shell', 'get_show_brik_attributes')) {
               if ($attribute =~ /^(?:shell|context|log|global|init_done|debug)$/) {
                  next;
               }
            }
            $self->log->info("$brik $attribute ".$context->get($brik, $attribute));
         }
      }
   }
   # get is called with only a Brik as an arg, we show its Attributes
   elsif (defined($brik) && ! defined($attribute)) {
      my $used = $context->used or return;

      if (! exists($used->{$brik})) {
         return $self->log->error("get: Brik [$brik] not used");
      }

      my %printed = ();
      my $attributes = $used->{$brik}->brik_attributes;
      for my $attribute (sort { $a cmp $b } keys %$attributes) {
         if (! $context->get('core::shell', 'get_show_brik_attributes')) {
            if ($attribute =~ /^(?:shell|context|log|global|init_done|debug)$/) {
               next;
            }
         }
         my $print = "$brik $attribute ".$context->get($brik, $attribute);
         $self->log->info($print) if ! exists($printed{$print});
         $printed{$print}++;
      }
   }
   # get is called with is a Brik and an Attribute
   elsif (defined($brik) && defined($attribute)) {
      my $used = $context->used or return;

      if (! exists($used->{$brik})) {
         return $self->log->error("get: Brik [$brik] not used");
      }

      if (! $used->{$brik}->brik_has_attribute($attribute)) {
         return $self->log->error("get: Attribute [$attribute] does not exist for Brik [$brik]");
      }

      $self->log->info("$brik $attribute ".$context->get($brik, $attribute));
   }

   return 1;
}

sub comp_get {
   my $self = shift;

   return $self->comp_set(@_);
}

sub run_run {
   my $self = shift;
   my ($brik, $command, @args) = @_;

   my $context = $self->context;

   if (! defined($brik) || ! defined($command)) {
      return $self->log->info("run <brik> <command> [ <arg1> <arg2> .. <argN> ]");
   }

   my $r = $context->run($brik, $command, @args);
   if (! defined($r)) {
      return $self->log->error("run: unable to execute Command [$command] for Brik [$brik]");
   }

   if ($self->echo) {
      $self->page(Data::Dump::dump($r)."\n");
   }

   return $r;
}

sub comp_run {
   my $self = shift;
   my ($word, $line, $start) = @_;

   my $context = $self->context;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   $self->debug && $self->log->debug("comp_run: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   # Completion is for used Briks only
   my $used = $context->used;
   if (! defined($used)) {
      $self->debug && $self->log->debug("comp_run: can't fetch used Briks");
      return ();
   }

   my $brik = defined($words[1]) ? $words[1] : undef;

   my @comp = ();

   # We want completion for used Briks
   if (($count == 1)
   ||  ($count == 2 && length($word) > 0)) {
      for my $a (keys %$used) {
         push @comp, $a if $a =~ /^$word/;
      }
   }
   # We fetch Brik Commands
   elsif ($count == 2 && length($word) == 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_run: Brik [$brik] not used");
            return ();
         }
      }

      my $brik_commands = Metabrik->brik_properties->{commands};
      my $commands = $used->{$brik}->brik_commands;

      if (! $self->comp_show_inherited) {
         $commands = $used->{$brik}->brik_properties->{commands};
      }

      for my $command (keys %$commands) {
         if (! $context->get('core::shell', 'comp_show_brik_commands')) {
            next if exists($brik_commands->{$command});
         }
         push @comp, $command;
      }
   }
   # We want to complete entered Command and Attributes
   elsif ($count == 3 && length($word) > 0) {
      if ($self->debug) {
         if (! exists($used->{$brik})) {
            $self->log->debug("comp_run: Brik [$brik] not used");
            return ();
         }
      }

      my $brik_commands = Metabrik->brik_properties->{commands};
      my $commands = $used->{$brik}->brik_commands;

      if (! $self->comp_show_inherited) {
         $commands = $used->{$brik}->brik_properties->{commands};
      }

      for my $command (keys %$commands) {
         if (! $context->get('core::shell', 'comp_show_brik_commands')) {
            next if exists($brik_commands->{$command});
         }
         if ($command =~ /^$word/) {
            push @comp, $command;
         }
      }
   }
   # Else, default completion method on remaining word
   else {
      return $self->catch_comp_sub($word, $start, $line);
   }

   return @comp;
}

#
# Term::Shell::catch stuff
#
sub catch_run {
   my $self = shift;
   my (@args) = @_;

   # Default to execute Perl commands
   return $self->run_code(@args);
}

# Taken from file::find Brik, to make core::shell independant from it.
sub _file_find {
   my $self = shift;
   my ($path) = @_;

   my @dirs = ();
   my @files = ();

   my $dirpattern = '.*';
   my $filepattern = '.*';

   # Handle finding of directories
   my @tmp_dirs = ();
   eval {
      @tmp_dirs = io($path)->all_dirs;
   };
   if ($@) {
      if ($self->debug) {
         chomp($@);
         $self->log->debug("all: $path: dirs: $@");
      }
      return { directories => [], files => [] };
   }
   for my $this (@tmp_dirs) {
      if ($this =~ /$dirpattern/) {
         push @dirs, "$this/";
      }
   }

   # Handle finding of files
   my @tmp_files = ();
   eval {
      @tmp_files = io($path)->all_files;
   };
   if ($@) {
      if ($self->debug) {
         chomp($@);
         $self->log->debug("all: $path: files: $@");
      }
      return { directories => [], files => [] };
   }
   for my $this (@tmp_files) {
      if ($this =~ /$filepattern/) {
         push @files, "$this";
      }
   }

   @dirs = map { s/^\.\///; $_ } @dirs;  # Remove leading dot slash
   @files = map { s/^\.\///; $_ } @files;  # Remove leading dot slash

   return {
      directories => \@dirs,
      files => \@files,
   };
}

# 1. $word - The word the user is trying to complete.
# 2. $line - The line as typed by the user so far.
# 3. $start - The offset into $line where $word starts.
sub catch_comp_sub {
   my $self = shift;
   # Strange, we had to reverse order for $start and $line only for catch_comp() method.
   my ($word, $start, $line) = @_;

   my $context = $self->context;

   my $attribs = $self->term->Attribs;
   $attribs->{completion_suppress_append} = 1;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   $self->debug && $self->log->debug("catch_comp: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   # Be default, we will read the current directory
   if (! length($word)) {
      $word = '.';
   }

   $self->debug && $self->log->debug("catch_comp: DEFAULT: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   my @comp = ();

   # We don't use $word here, because the $ is stripped. We have to use $word[-1]
   # We also check against $line, if we have a trailing space, the word was complete.
   if ($last =~ /^\$/ && $line !~ /\s+$/) {
      my $variables = $context->variables;

      for my $this (@$variables) {
         $this =~ s/^\$//;
         #$self->debug && $self->log->debug("variable[$this] start[$start]");
         if ($this =~ /^$word/) {
            push @comp, $this;
         }
      }
   }
   else {
      my $path = '.';

      #my $home = $self->path_home;
      my $home = $self->{path_home};
      $word =~ s/^~/$home/;

      if ($word =~ /^(.*)\/.*$/) {
         $path = $1 || '/';
      }

      #$self->debug && $self->log->debug("path[$path]");

      my $found = $self->_file_find($path);

      for my $this (@{$found->{files}}, @{$found->{directories}}) {
         #$self->debug && $self->log->debug("check[$this]");
         if ($this =~ /^$word/) {
            push @comp, $this;
         }
      }
   }

   return @comp;
}

# 1. $word - The word the user is trying to complete.
# 2. $line - The line as typed by the user so far.
# 3. $start - The offset into $line where $word starts.
# The true default completion method for Term::Shell when no comp_* matched.
# Ugly, we should merge with comp_catch_sub().
# Bug from Term::Shell: $start is not an offset in that case.
sub catch_comp {
   my $self = shift;
   # Strange, we had to reverse order for $start and $line only for catch_comp() method.
   my ($word, $start, $line) = @_;

   my $context = $self->context;

   my $attribs = $self->term->Attribs;
   $attribs->{completion_suppress_append} = 1;

   my @words = $self->line_parsed($line);
   my $count = scalar(@words);
   my $last = $words[-1];

   $self->debug && $self->log->debug("catch_comp: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   # Be default, we will read the current directory
   if (! length($start)) {
      $start = '.';
   }

   $self->debug && $self->log->debug("catch_comp: DEFAULT: words[@words] | word[$word] line[$line] start[$start] | last[$last]");

   my @comp = ();

   # We don't use $start here, because the $ is stripped. We have to use $word[-1]
   # We also check against $line, if we have a trailing space, the word was complete.
   if ($last =~ /^\$/ && $line !~ /\s+$/) {
      my $variables = $context->variables;

      for my $this (@$variables) {
         $this =~ s/^\$//;
         #$self->debug && $self->log->debug("variable[$this] start[$start]");
         if ($this =~ /^$start/) {
            push @comp, $this;
         }
      }
   }
   else {
      my $path = '.';

      #my $home = $self->path_home;
      my $home = $self->{path_home};
      $start =~ s/^~/$home/;

      if ($start =~ /^(.*)\/.*$/) {
         $path = $1 || '/';
      }
      $self->debug && $self->log->debug("path[$path]");

      my $found = $self->_file_find($path);

      for my $this (@{$found->{files}}, @{$found->{directories}}) {
         #$self->debug && $self->log->debug("check[$this]");
         if ($this =~ /^$start/) {
            push @comp, $this;
         }
      }
   }

   return @comp;
}

1;

__END__

=head1 NAME

Metabrik::Core::Shell - core::shell Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
