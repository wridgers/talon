#!/usr/bin/perl

# HTTP functions

use strict;
use WWW::Mechanize;
package talonplug::http;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;
	
	if ( $message =~ /(http:\/\/[^ ]*)/ ) {
		eval {
			my $url = $1;
			my $mech = WWW::Mechanize->new();
			$mech->get($url);
			my $html = $mech->content;

			$html =~ /<title([^>]*)>(.*?)<\/title>/i;
			my $title = $2;

			print "[debug] $url -> $title\n";

			if ($title ne $url and $title ne '') {
				$irc->yield( privmsg => $respond => '>> '.$title);
			}
		};
		if ($@) {
			$irc->yield( privmsg => $respond => '>> An error occured!');
			print '>> '.$@."\n";
		}
	}
	

}

sub about {
	return "Http functions.";
}

sub help {
	return "None. Will print titles of urls.";
}

1;
