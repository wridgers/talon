#!/usr/bin/perl

# Mylife module, for FML, MLIA and MLIG

use strict;
package talonplug::mylife;

use WWW::Mechanize;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;
	
	if ( $message =~ /^!fml/ ) {
		my $url = 'http://api.betacie.com/view/random/?key=readonly&language=en';
		my $mech = new WWW::Mechanize();
		$mech->get($url);
		my $out = $mech->content;

		$out =~ /<item id="([0-9]*)">(.*)<\/item>/;
		my $flid = $1;
		my $tmp = $2;

		$tmp =~ /<text>(.*)<\/text>/;
		my $fml = $1;

		$fml =~ s/\&quot\;/\"/g;

		$irc->yield(privmsg => $respond => '>> ['.$flid.'] '.$fml);
	}

	if ( $message =~ /^!mlia/ ) {
		$irc->yield(privmsg => $respond => '>> MLIA - code me.');
	}

	if ( $message =~ /^!mlig/ ) {
		$irc->yield(privmsg => $respond => '>> MLIG - code me.');
	}

}

sub about {
	return "Interface for FML, MLIA and MLIG.";
}

sub help {
	return "!fml - random FML\n".
		"!mlia - random MLIA\n".
		"!mlig - random MLIG";
}

1;
