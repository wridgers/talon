#!/usr/bin/perl

# Test module, for testing!

use strict;
package talonplug::quotes;

sub new {
	my $self = { };
	return bless $self;
}

sub on_join {
	my ($self, $irc, $sql, $nick, $host, $channel, $host) = @_;

	my $q = $sql->selectall_arrayref("select id, nick, quote from quotes where `nick`='$nick';");

	if (@{$q} > 0) {
		my $len = @{$q};
		my $qn = rand( $len );
		my $id = ${${$q}[$qn]}[0];
		my $text = ${${$q}[$qn]}[2];
		$text =~ s/^ //g;
		$irc->yield( privmsg => $channel => '>> ['.$id.'] "'.$text.'"' );
	}	
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;

	if ( $message =~ /^!addquote ([a-z0-9]*) (.*)/i ) {
		my $qnick = $1;
		my $quote = $2;

		$quote =~ s/'//;
		
		$sql->do("insert into quotes (nick, quote, addby, addhost) values ('$qnick', '$quote', '$nick', '$host');");		
		$irc->yield( privmsg => $respond => '>> Quote added.' );
	}

	if ( $message =~ /^!quote ([a-zA-Z0-9]*)/i ) {
		my $q = $sql->selectall_arrayref("select id, nick, quote from quotes where `nick`='$1';");

		if (@{$q} > 0) {
			my $len = @{$q};
			my $qn = rand( $len );
			my $id = ${${$q}[$qn]}[0];
			my $text = ${${$q}[$qn]}[2];
			$text =~ s/^ //g;
			$irc->yield( privmsg => $respond => '>> ['.$id.'] "'.$text.'"' );
		} else {
			$irc->yield( privmsg => $respond => '>> No quotes in database.' );
		}
	}

	if ( $message =~ /^!quotes ([a-zA-Z0-9]*)/i ) {
		my $q = $sql->selectall_arrayref("select id, nick, quote from quotes where `nick`='$1';");

		foreach my $row ( @$q ) {
			my ( $qn, $nick, $text ) = @$row;			
			$irc->yield( privmsg => $respond => '>> ['.$qn.'] "'.$text.'"' );
		}
	}

}

sub about {
	return "One liner quote module.";
}

sub help {
	return "!addquote <nick> <quote> - add a quote.\n".
		"!quote <nick> - display random quote.\n".
		"!quoteid <id> - show specific quote.\n".
		"!quotes <nick> - show all nick's quotes.";
}

1;
