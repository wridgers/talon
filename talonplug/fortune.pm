#!/usr/bin/perl

# Fortune module!

use strict;
package talonplug::fortune;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;
	
	if ( $message =~ /^!decide (.*)/ ) {
		my @res = split(/ or /, $1);
			
		$irc->yield(privmsg => $respond => @res[rand($#res + 1)]);
	}

	if ( $message =~ /^!8ball/ ) {
		my @resp = ( 'As I see it, yes', 'It is certain', 'It is decidedly so', 'Most likely', 'Outlook good',
			'Signs point to yes', 'Without a doubt', 'Yes', 'Yes - definitely', 'You may rely on it',
			'Reply hazy, try again', 'Ask again later', 'Better not tell you now', 'Cannot predict now',
			'Concentrate and ask again', 'Don\'t count on it', 'My reply is no', 'My sources say no',
			'Outlook not so good', 'Very doubtful' );

		$irc->yield(privmsg => $respond => $resp[rand($#resp + 1)]);
	}
}

sub about {
	return "Fortune commands";
}

sub help {
	return "!decide x or y (or z ...) - pick between x or y (or z).\n".
		"!8ball - 8ball fortune.";
}

1;
