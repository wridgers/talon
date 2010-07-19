#!/usr/bin/perl

# Greets

use strict;
package talonplug::greets;

sub new {
	my $self = { };
	return bless $self;
}

sub on_join {
	my ($self, $irc, $sql, $nick, $host, $channel, $host) = @_;

	my @greets = ( 'Welcome to #chan, #nick!... twat...',
			'Who the fuck are you #nick?',
			'*moves away from aids infected #nick*',
			'#nick, from all of us here in #chan - fuck you!',
			'#nick, ask about his aids.',
			'#nick, you are not welcome here.',
			'You\'re a prick #nick, and no one likes you.',
			'I fucked #nick\'s mother.' );

	if ($nick =~ /conrad/i or $nick =~ /connie/i ) {
		$irc->yield( privmsg => $channel => '>> Welcome to #maths Mr Cock!' );		# A little Talon easteregg ;-)
	} else {
		my $w3rds = $greets[rand @greets];
		$w3rds =~ s/#nick/$nick/g;
		$w3rds =~ s/#chan/$channel/g;

		#$irc->yield( privmsg => $channel => '>> '.$w3rds );				# Insult greets, comment out if you want.
		$irc->yield( privmsg => $channel => '>> Welcome to '.$channel.', '.$nick.'!' );

		my $title = $sql->selectrow_array("select title from users where `nick`='$nick';");
		if ($title) {
			$irc->yield( privmsg => $channel => '>> '.$title);
		}
	}

	#$irc->yield( mode => $channel => '+v' => $nick );					# Defunt in regard to automode?
}

sub about {
	return "Greets and voices.";
}

sub help {
	return "None interactive.";
}

1;
