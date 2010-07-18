#!/usr/bin/perl

# Deep thought

use strict;
package talonplug::dt;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;
	
	if ( $message =~ /^!dt/ ) {
		open(HANDLE, '<talonplug/dt.txt');
		my @thoughts = <HANDLE>;
		close(HANDLE);

		my $len = @thoughts;
		$irc->yield( privmsg => $respond => '>> '.@thoughts[int(rand($len))] );
	}
}

sub about {
	return "Deep Thoughts for Talon.";
}

sub help {
	return "!dt - Spout deep thought.";
}

1;
