#!/usr/bin/perl

# Test module, for testing!

use strict;
package talonplug::test;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;

	if ( $message =~ /^!test/ ) {
		$irc->yield( privmsg => $respond => 'Well that works? Apparently so! Yes!');
	}
}

sub about {
	return "Purely a testing module.";
}

sub help {
	return "Your guess is as good as mine.";
}

1;
