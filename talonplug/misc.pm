#!/usr/bin/perl

# Misc functions

use strict;
use WWW::Mechanize;
use Math::Round;
package talonplug::misc;

sub new {
	my $self = { };
	return bless $self;
}

sub on_join {
	my ($self, $irc, $sql, $nick, $host, $channel) = @_;
}

sub on_part {
	my ($self, $irc, $sql, $nick, $host, $channel, $qmsg) = @_;
}

sub on_quit {
	my ($self, $irc, $sql, $nick, $host, $qmsg) = @_;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;
	
	if ( $message =~ /^!hug/ ) {
		if ($message =~ /^!hug (.*)/ ) {
			$irc->yield( ctcp => $respond => 'ACTION hugs '.$1 );
		} else {
			$irc->yield( ctcp => $respond => 'ACTION hugs '.$nick );
		}
	}

	if ( $message =~ /^!hostcheck/ ) {
		if (taloncommon->host_match($sql, $nick, $host)) {
			$irc->yield( privmsg => $respond => '>> Accepted. You can execute admin commands.');
		} else {
			$irc->yield( privmsg => $respond => '>> Denied. Your host does not match.');
		}
	}
	
	if ( $message =~ /^@([^ ]*) (.*)/i ) {
		my $c = $1;
		my $message = $2;
		
		$message =~ s/Gauss is my/I am duppy's/i;		# Another little easter egg.

		$irc->yield( privmsg => $c => $message);
	}

}

sub about {
	return "Misc functions.";
}

sub help {
	return "Unknown.";
}

1;
