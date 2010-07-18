#!/usr/bin/perl

# Net module

use strict;
use Math::Round;
package talonplug::netmon;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;
	
	if ( $message =~ /^!net/ ) {
		my $interface = 'eth0';

		my $rxo = `cat /sys/class/net/$interface/statistics/rx_bytes`;
		my $txo = `cat /sys/class/net/$interface/statistics/tx_bytes`;

		sleep(2);

		my $rxn = `cat /sys/class/net/eth0/statistics/rx_bytes`;
		my $txn = `cat /sys/class/net/eth0/statistics/tx_bytes`;
		my $rx = Math::Round::nearest(.01, ($rxn-$rxo)/1024/2 );
		my $tx = Math::Round::nearest(.01, ($txn-$txo)/1024/2 );
	
		$irc->yield( privmsg => $respond => '>> '.$interface.': tx@'.$tx.' kB/s | rx@'.$rx.' kB/s');
	}
														        
}

sub about {
	return "Network monitor module.";
}

sub help {
	return "!net <interface> - show up/down speeds.";
}

1;
