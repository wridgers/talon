#!/usr/bin/perl

# Logging functions

use strict;
package talonplug::logging;

sub new {
	my $self = { };
	return bless $self;
}

sub on_join {
	my ($self, $irc, $sql, $nick, $host, $channel) = @_;
	my $timestamp = time;
	
	$sql->do("insert into logs (timestamp, nick, host, chan, message) values ('$timestamp', '$nick', '$host', '$channel', 'joined channel.');");
}

sub on_part {
	my ($self, $irc, $sql, $nick, $host, $channel, $qmsg) = @_;
	my $timestamp = time;

	$sql->do("insert into logs (timestamp, nick, host, chan, message) values ('$timestamp', '$nick', '$host', '$channel', 'left channel.');");
}

sub on_quit {
	my ($self, $irc, $sql, $nick, $host, $qmsg) = @_;
	my $timestamp = time;

	$sql->do("insert into logs (timestamp, nick, host, message) values ('$timestamp', '$nick', '$host', 'quit IRC.');");
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host) = @_;

	if ( $message =~ /^!history (.*)/ ) {
		
		my $term = $1;
		$term =~ s/'//g;
		
		my $results = $sql->selectall_arrayref("select * from logs where message like '%$term%' and `chan`='$respond' order by id desc limit 5;");
		if ( $results ) {
			foreach my $row (@$results) {
				my ($id, $time, $nick, $host, $chan, $message) = @$row;

				my ($sec, $min, $hour, $day,$month,$year) = (localtime($time))[0,1,2,3,4,5,6];
				my $ts = "$day/".($month+1)."/".($year+1900)." $hour:$min:$sec";

				$irc->yield( privmsg => $respond => '>> ['.$ts.'] <'.$nick.'> '.$message );
			}
		} else {
			$irc->yield( privmsg => $respond => '>> Nothing found.' );
		}

	} elsif ( $message =~ /^!seen ([a-z0-9]*)/i ) {
		my @res = $sql->selectrow_array("select * from logs where `nick`='$1' and `chan`='$respond' order by id desc limit 1;");

		if (@res) {
			my $seconds = time - $res[1];
			my @parts = gmtime($seconds);
			my $last = sprintf ("%ih %im %is",@parts[7,2,1,0]);

			$irc->yield( privmsg => $respond => '>> '.$res[2].' last seen '.$last.' ago.' ); 
		} else {
			$irc->yield( privmsg => $respond => '>> I have never seen '.$1 );
		}

	} else {
		$message =~ s/'//g;
		my $timestamp = time;

		$sql->do("insert into logs (timestamp, nick, host, chan, message) values ('$timestamp', '$nick', '$host', '$respond', '$message');");
	}

}

sub about {
	return "Chat logging functions, searchable.";
}

sub help {
	return "!history <term> - search history.\n".
		"!seen <nick> - check when nick was last seen.";
}

1;
