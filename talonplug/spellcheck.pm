#!/usr/bin/perl

# Spell checking

use strict;
package talonplug::spellcheck;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;
	
	if ($message =~ /^!sc ([a-zA-Z\-]*)/i) {
		my $word = $1;
		
		open (SC, 'echo "'.$word.'" | aspell -a|');
		while(<SC>) {
			if ($_ =~ /^&/ ) {
				$irc->yield( privmsg => $respond => ">> $_");
			}

			if ($_ =~ /^\*/ ) {
				$irc->yield( privmsg => $respond => '>> '.$word.' is the correct spelling.');
			}
		}
		close(SC);
	}
}

sub about {
	return "Spell checking with aspell.";
}

sub help {
	return "!sc <word> - spellcheck word with aspell.";
}

1;
