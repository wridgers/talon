#!/usr/bin/perl

use strict;

# External modules
use DBI;
use POE;
use POE::Component::IRC;
use Module::Load;
use Module::Refresh;
use Config::Simple;
use Getopt::Std;

# Load talon common subs.
use taloncommon;

# Get command line options.
my (%opts, $cfile);
getopts('hc:', \%opts);

# Create the hash array 'stack'.
# my %stack;

# Set command trigger.
# %stack{'trigger'} = "!";

usage() if $opts{'h'};

$cfile = 'default.conf';
$cfile = $opts{'c'} if ($opts{'c'});

my $cfg = new Config::Simple('conf/'.$cfile);
print "[config] Loaded conf/$cfile.\n";

## Before we go any farther, lets see if the database exists
unless (-e $cfg->param('db')) { print "Unable to start. Database missing. Maybe you should check the README.\n"; exit; }

# Setup SQLite database.
my $dbh = DBI->connect("dbi:SQLite:dbname=".$cfg->param('db'),"","",{AutoCommit => 1, PrintError => 1});

# Modules hash array.
my %modules = ( );

# Load all modules in talonplug, ignore skipped in config.
## pass the dbh to load for modules that require sql
load_all_modules($dbh);

# Initiate connection to IRC server.
print "[kernel] Creating connection to IRC server...\n";
print '[kernel] '.$cfg->param('server').':'.$cfg->param('port').' as '.$cfg->param('nick')."\n";

# Spawn.
my $poeirc = POE::Component::IRC->spawn( 	Nick => $cfg->param('nick'),
						Server => $cfg->param('server'),
						Port => $cfg->param('port'),
						UseSSL => $cfg->param('ssl') )
	or die "[kernel] Cannot connect to server.\n";

POE::Session->create(
	package_states => [
		main => [ qw( _default _start irc_001 irc_public irc_msg irc_join irc_part irc_quit) ]
	],
	heap => { poeirc => $poeirc }
);

POE::Kernel->run();
print "[kernel] Kernel initiated\n";

##################################################################
##################################################################

sub load_all_modules {
	my ($dbh) = @_;
	my @s = split(/,/, $cfg->param('skip'));
	print "[modules] Skip: ".$cfg->param('skip')."\n";

	while ( <talonplug/*.pm> ) {
		$_ =~ /talonplug\/([^.]*)\.pm/;
		my $m = $1;

		if (not grep {$_ eq $m} @s) {
			if ( check_module($m) eq 1 ) {
				load 'talonplug::'.$m;
				$modules{$m} = "talonplug::$m"->new($dbh); ##pass dbh in case of sql
				print "[modules] Loaded $m\n";
			} else {
				print "[modules] $m contains errors.\n";
			}
		}
	}
}

sub check_module {
	Module::Refresh->unload_module('talonplug::'.$1);
	my $data;

	open( HANDLE, '<talonplug/'.$1.'.pm' );
	while (<HANDLE>) {
		$data = $data.$_;
	}
	close(HANDLE);
	eval $data;
	if ($@) {
		my @err = split(/\n/, $@);
		print '[error] '.$_."\n" foreach(@err);
		return $@;
	}

	Module::Refresh->unload_module('talonplug::'.$1);

	return 1;	
}

sub module_panic {
	my ( $m, $channel, $err ) = @_;

	if ( $channel ne 0 ) {
		$poeirc->yield( privmsg => $channel => '>> Module '.$m.' auto unloaded due to error.');
		$poeirc->yield( privmsg => $channel => '>> '.$_) foreach($err);
	}

	print '[error] '.$_."\n" foreach($err);
	delete $modules{$m};
}

##################################################################
##################################################################

sub _start {
	my $heap = $_[HEAP];
	my $poeirc = $heap->{poeirc};

	$poeirc->yield( register => 'all' );
	$poeirc->yield( connect => { } );

	return;
}

sub _default {
	my ($event, $args) = @_[ARG0 .. $#_];
	my @output = ( "$event: " );

	for my $arg (@$args) {
		if ( ref $arg eq 'ARRAY' ) {
			push( @output, '[' . join(' ,', @$arg ) . ']' );
		} else {
			push ( @output, "'$arg'" );
		}
	}

	return 0;
}

sub irc_001 {
	my $sender = $_[SENDER];
	my $poeirc = $sender->get_heap();

	print "[kernel] Connected!\n";
	print "[kernel] Ident with nickserv\n";	
	$poeirc->yield(privmsg => 'nickserv' => 'identify '.$cfg->param('nickserv') );
	
	my @chans = split(/,/, $cfg->param('chans'));
	foreach(@chans) {
		$poeirc->yield( join => $_);
		print "[kernel] Joined $_\n";
	}

	return;
}

sub irc_public {
	my ($sender, $who, $where, $message) = @_[SENDER, ARG0 .. ARG2];
	my @who = split(/!/, $who);
	my $channel = $where->[0];

	global_commands( $who[0], $who[1], $channel, $message );
}

sub irc_msg {
	my ($sender, $who, $where, $message) = @_[SENDER, ARG0 .. ARG2];
	my @who = split(/!/, $who);

	global_commands( @who[0], @who[1], @who[0], $message );

	foreach my $m (values %modules) {
		eval {
			if ( $m->can('on_private') ) {
				$m->on_private($poeirc, $dbh, $message, @who[0]);
			}
		};
		if ($@) {
			module_panic($m, @who[0], $@);
		}
	}
}

sub irc_join {
	my ($who, $channel) = @_[ ARG0 .. ARG1 ];
	my @who = split(/!/, $who);

	foreach my $m (values %modules) {
		eval {
			if ( $m->can('on_join') ) {
				$m->on_join($poeirc, $dbh, @who[0], @who[1], $channel);
			}
		};
		if ($@) {
			module_panic($m, $channel, $@);
		}
	}
}

sub irc_part {
	my ($who, $channel, $qmsg) = @_[ ARG0 .. ARG2 ];
	my @who = split(/!/, $who);

	foreach my $m (values %modules) {
		eval {
			if ( $m->can('on_part') ) {
				$m->on_part($poeirc, $dbh, @who[0], @who[1], $channel, $qmsg);
			}
		};
		if ($@) {
			module_panic($m, $channel, $@);
		}
	}
}

sub irc_quit {
	my ($who, $qmsg) = @_[ ARG0 .. ARG1 ];
	my @who = split(/!/, $who);

	foreach my $m (values %modules) {
		eval {
			if ( $m->can('on_quit') ) {
				$m->on_quit($poeirc, $dbh, @who[0], @who[1], $qmsg);
			}
		};
		if ($@) {
			module_panic($m, 0, $@);
		}
	}
}

######################################################################
######################################################################
######################################################################

sub global_commands {

	my ( $nick, $host, $channel, $message ) = @_;

	eval {
		## ADMIN ONLY COMMANDS
		if (taloncommon->is_admin($dbh, $nick, $host)) {

			if ( $message =~ /^!check/ ) {
				if ($message =~ /^!check ([^ ]*)/ ) {
					my $n = $1;
					my $p = "talonplug/$1.pm";
					my $m = "talonplug::$1";

					if (-e $p) {
						if ( check_module($n) eq 1 ) {
							$poeirc->yield( privmsg => $channel => '>> '.$m.' is fine!' );
						} else {
							my @err = split(/\n/, $@);
							$poeirc->yield( privmsg => $channel => '>> '.$_ ) foreach(@err);
						}
						
					} else {
						$poeirc->yield( privmsg => $channel => '>> No such module');
					}

				} else {
					$poeirc->yield( privmsg => $channel => '>> !check <module>');	
				}
			}


			if ( $message =~ /^!flush/ ) {
				Module::Refresh->unload_module('talonplug::'.$_) foreach (keys %modules);
				%modules = ();
				$poeirc->yield( privmsg => $channel => '>> Flushed modules');

				print "[modules] Flushed\n";
			}

			if ( $message =~ /^!reload/ ) {
				Module::Refresh->unload_module('talonplug::'.$_) foreach (keys %modules);
				%modules = ();

				load_all_modules();	
				$poeirc->yield( privmsg => $channel => '>> Reloaded all modules');

				print "[modules] Reloaded\n";
			}

			if ( $message =~ /^!refresh/ ) {
				Module::Refresh->refresh;
				$poeirc->yield( privmsg => $channel => '>> Refreshed');
				print "[modules] Rehashed\n";
			}

			if ( $message =~ /^!load ([^ ]*)/ ) {
				if (-e "talonplug/$1.pm") {
					if (exists $modules{$1}) {
						$poeirc->yield( privmsg => $channel => '>> '.$1.' is already loaded!' );
					} else {
						if ( check_module($1) eq 1 ) {
							load 'talonplug::'.$1;
							Module::Refresh->refresh_module('talonplug::'.$1);
	
							$modules{$1} = "talonplug::$1"->new();
							print '[modules] Loaded '.$1."\n";

							$poeirc->yield( privmsg => $channel => '>> Loaded '.$1 );
						} else {
							$poeirc->yield( privmsg => $channel => '>> '.$1.' contains errors!' );
						}
					}
				} else {
					$poeirc->yield( privmsg => $channel => '>> '.$1.' doesn\'t exist!' );
				}
			}

			if ( $message =~ /^!unload ([^ ]*)/ ) {
				if (-e "talonplug/$1.pm") {
					if (exists $modules{$1}) {
						Module::Refresh->unload_module('talonplug::'.$1);
						delete $modules{$1};

						$poeirc->yield( privmsg => $channel => '>> Unloaded '.$1 );
						print '[modules] Unloaded '.$1."\n";
					} else {	
						$poeirc->yield( privmsg => $channel => '>> '.$1.' isn\'t loaded!' );
					}
				} else {
					$poeirc->yield( privmsg => $channel => '>> '.$1.' doesn\'t exist!' );
				}
			}

			if ( $message =~ /^!modules/ ) {
				while ( my ($name, $plug) = each (%modules)) {
					$poeirc->yield( privmsg => $channel => '>> '.$name.' - '.$plug->about() );
				}
			}

		}

		if ( $message =~ /^!help/ ) {
			if ( $message =~ /^!help ([^ ]*)/ ) {
				if (exists $modules{$1}) {
					my @h = split(/\n/, $modules{$1}->help());

					$poeirc->yield( privmsg => $channel => '>> '.$_ ) foreach (@h);
				} else {
					$poeirc->yield( privmsg => $channel => '>> No such module!' );
				}
			} else {
				$poeirc->yield( privmsg => $channel => '>> !help <module>');

				my $topics = '';
				while ( my ($name, $plug) = each (%modules)) {
					$topics = $topics.', '.$name;
				}
				$topics =~ s/^, //;

				$poeirc->yield( privmsg => $channel => '>> Modules: '.$topics);
			}
		}

		## END ADMIN ONLY COMMANDS

		if ( $message =~ /^!about/ ) {
			if ( $message =~ /^!about ([^ ]*)/ ) {
				my $aboutmod = $1;
				
				if (exists $modules{$aboutmod}) {
					$poeirc->yield( privmsg => $channel => '>> '.$aboutmod.' - '.$modules{$aboutmod}->about() );
				} else {
					$poeirc->yield( privmsg => $channel => '>> No such module!' );
				}
			} else {
				$poeirc->yield( privmsg => $channel => '>> Powered by Talon v0.6.');
				$poeirc->yield( privmsg => $channel => '>> Written in Perl. Database managed with SQLite.');
				$poeirc->yield( privmsg => $channel => '>> http://github.com/mindfuzz/talon');
			}
		}

		# Proccess all modules.
		foreach my $m (values %modules) {
			eval {
				if ( $m->can('on_public') ) {
					$m->on_public($poeirc, $dbh, $message, $nick, $channel, $host);
				}
			};
			if ($@) {
				module_panic($m, $channel, $@);
			}
		}

	};
	if ($@) {
		$poeirc->yield( privmsg => $channel => '>> An error occured!');
		$poeirc->yield( privmsg => $channel => '>> '.$@);
		print '[error] '.$@."\n";
	}

	return;
}

#########################################################################################


sub usage {
	die <<EOH
Usage: $0 [options]

Options:
	-h		Show help
	-c [cfgfile]	Specify config file, default to default.conf
EOH
}
