#!/usr/bin/perl

# Core functions

use strict;
use taloncommon;


package talonplug::core;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;


	if (taloncommon->is_admin($sql, $nick, $host)) {

		if ( $message =~ /^!join ([^ ]*)/ ) {
			$irc->yield( join => $1 );
			$irc->yield( privmsg => $respond => '>> Joining '.$1 );
		}	

		if ( $message =~ /^!part/ ) {
			$irc->yield( part => $respond );
		}
	
	
		if ( $message =~ /^!(op|deop|hop|dehop|voice|devoice)/i ) {
			my $todo = lc $1;
			my $whoto;
			my $mode;

			if ( $message =~ /^!(op|deop|hop|dehop|voice|devoice) ([a-z0-9]*)/i ) {
				$whoto = $2;
			} else {
				$whoto = $nick;
			}

			$mode = '+o' if $todo eq 'op';
			$mode = '-o' if $todo eq 'deop';
			$mode = '+h' if $todo eq 'hop';
			$mode = '-h' if $todo eq 'dehop';
			$mode = '+v' if $todo eq 'voice';
			$mode = '-v' if $todo eq 'devoice';

			$irc->yield( mode => $respond => $mode => $whoto );
		}
	

		if ($message =~ /^!quit/i) {

			$irc->yield( quit => "Quit command issued by $nick." );
			$sql->disconnect();

			exit 0;
		}
	}
	
}

sub about {
	return "Core functions of Talon.";
}

sub help {
	return 	"!join <chan> - join a channel.\n".
		"!part <chan> - part a channel.\n".
		"!quit - quit server.\n".
		"!op <nick> - op nick.\n".
		"!deop <nick> - deop nick.\n".
		"!voice <nick> - voice nick.\n".
		"!devoice <nick> - devoice nick.\n".
		"!hop <nick> - halfop nick.\n".
		"!dehop <nick - dehalfop nick.";
}

1;
