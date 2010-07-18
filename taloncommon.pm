#!/usr/bin/perl

package taloncommon;
use strict;

sub is_admin {
	my ($self, $sql, $nick, $host) = @_;
	my @res = $sql->selectrow_array("select id from users where `nick`='$nick' and `isadmin`=1;");

	if (@res) {
		if ( taloncommon->host_match($sql, $nick, $host )) {
			return 1;
		} else {
			return 0;
		}
	} else {
		return 0;
	}
}

sub is_god {
	my ($self, $sql, $nick, $host) = @_;
	my @res = $sql->selectrow_array("select id from users where `nick`='$nick' and `isgod`=1;");
	
	(@res) ? return 1 : return 0;
}

sub host_match {
	my ($self, $sql, $nick, $host) = @_;
	my @res = $sql->selectrow_array("select hostmask from users where `nick`='$nick' limit 1;");
	
	($host =~ /@res[0]/) ? return 1 : return 0;
}

1;
