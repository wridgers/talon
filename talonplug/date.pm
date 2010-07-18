#!/usr/bin/perl

## Date/Time module for Talon IRC bot.

use strict;
package talonplug::date;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;


	if ( $message =~ /^!(date|time)/ ) {
		$irc->yield( privmsg => $respond => '>> Date: '.`date`);
	}

	if ( $message =~ /^!epoch/ ) {
		my $epoch = `date +%s`;
		$irc->yield( privmsg => $respond => '>> '.$epoch);
	}
}

sub about {
	return "A simple plugin to get current date and time, including Unix Epoch time.";
}

sub help {
	return "!(date|time) - returns date and time.\n!epoch - returns Unix Epoch time.";
}


1;
