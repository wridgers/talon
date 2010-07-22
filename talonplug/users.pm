#!/usr/bin/perl

# User functions

use strict;
use taloncommon;
package talonplug::users;

## onload
sub new {
	eval {
		## test if database contains users table, 
		## if true, move on silently
		## if false, print warning and generate table from schema
		#create table users (
		#	id		integer primary key,
		#	nick		text,
		#	password	text,
		#	hostmask	text,
		#	title		text,
		#	email		text,
		#	automode	text,
		#	isbanned	integer default 0,
		#	isadmin		integer default 0,
		#	isgod		integer default 0
		#);
	}
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;

	if ( taloncommon->is_admin($sql, $nick, $host) ) {
		
		if ( $message =~ /^!adduser ([a-z0-9]*)/i ) {
			$sql->do("insert into users (nick) values ('$1');");
			$irc->yield( privmsg => $respond => '>> User '.$1.' added.');
		}

		if ( $message =~ /^!deluser ([a-z0-9]*)/i ) {
			$sql->do("delete from users where `nick`='$1';");
			$irc->yield( privmsg => $respond => '>> User '.$1.' deleted.');
		}

		if ( $message =~ /^!edituser ([a-z0-9]*) ([a-z0-9_]*) ([a-z0-9+-]*)/i ) {
			my $n = $1;
			my $t = $2;
			my $v = $3;

			$sql->do("update users set `$t`='$v' where `nick`='$n';");
			$irc->yield( privmsg => $respond => '>> User '.$n.' edited.');
		}

	}
	
	if ( $message =~ /^!user ([a-zA-Z0-9]*)/ ) {
		my $nk = $1;
		
		my @data = $sql->selectrow_array("select id,nick,hostmask,isadmin,title,automode from users where `nick`='$nk';");

		if (@data) {
			if (@data[3] eq 1) {
				$irc->yield( privmsg => $respond => '>> User: '.@data[1].'*');
			} else {
				$irc->yield( privmsg => $respond => '>> User: '.@data[1]);
			}

			$irc->yield( privmsg => $respond => '>> Title: '.@data[4]) if @data[4] ne '';
			$irc->yield( privmsg => $respond => '>> Host: '.@data[2]) if @data[2] ne '';
			$irc->yield( privmsg => $respond => '>> Automode: '.@data[5]) if @data[5] ne '';
		} else {
			$irc->yield( privmsg => $respond => '>> No such user.');
		}
	}

	if ( $message =~ /^!title (.*)/ ) {
		my $title = $1;
		$title =~ s/'//g;
		#print "$title\n";
		
		my @res = $sql->selectrow_array("select id from users where `nick`='$nick';");
		if (@res) {
			$sql->do("update users set `title`='$title' where `nick`='$nick';");
			$irc->yield( privmsg => $respond => '>> Title set.');
		} else {
			$irc->yield( privmsg => $respond => '>> No such user.');
		}
	}
	
}

sub on_join {
	my ($self, $irc, $sql, $nick, $host, $channel, $host) = @_;
	
	my @res = $sql->selectrow_array("select automode from users where `nick`='$nick';");
	if (@res) {
		$irc->yield( mode => $channel => @res[0] => $nick );
	}
}

sub about {
	return "Functions to manage users.";
}

sub help {
	return "!user <nick> - show user info.\n".
		"!title - set own title.\n".
		"!adduser <nick> - add a user.\n".
		"!deluser <nick> - delete user.\n".
		"!edituser <nick> <var> <val> - edit user.";
}

1;
