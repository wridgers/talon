#!/usr/bin/perl

# TinyURL functions

use strict;
use WWW::Shorten::TinyURL;

package talonplug::tinyurl;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;
	
	if ( $message =~ /^!tiny (http:\/\/[^ ]*)/ ) {
		my $url = $1;
		my $short_url = WWW::Shorten::TinyURL::makeashorterlink($url);
		$irc->yield( privmsg => $respond => '>> '.$short_url);
	}

	if ( $message =~ /((http:\/\/tinyurl\.com|http:\/\/www\.tinyurl\.com)[^ ]*)/ ) {
		my $url = $1;
		my $long_url = WWW::Shorten::TinyURL::makealongerlink($url);
		$irc->yield( privmsg => $respond => '>> '.$long_url);
	}
		
}

sub about {
	return "Interact with TinyURL.com";
}

sub help {
	return "!tiny <url> - make a url tiny.\n".
		"Detected TinyURLs will be lengthened.";
}

1;
