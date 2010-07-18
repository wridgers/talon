#!/usr/bin/perl

# TV show information

use strict;
use WWW::Mechanize;
package talonplug::tv;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;
	
	if ( $message =~ /^!tv ([a-zA-Z0-9 ]*)/ ) {
		my $q = $1;

		eval {
			my $mech = WWW::Mechanize->new();

			$mech->get('http://www.tvrage.com/feeds/search.php?show='.$q);
			my $xml = $mech->content;
			
			$xml =~ /<showid>([0-9]*?)<\/showid>\n<name>(.*?)<\/name>\n<link>(.*?)<\/link>\n<country>(.*?)<\/country>/;
			my $showid = $1;
			my $showname = $2;
			my $showlink = $3;
			my $showcountry = $4;

			$mech->get($showlink);
			my $html = $mech->content;

# <b>Latest Episode: </b></td><td><table cellspacing='0' cellpadding='0'><tr><td valign='top' width='250'><span  onmouseover="showToolTip2(event,'Kidney Now! (May/14/2009)');return false;" onmouseout="hideToolTip2();"  style='width: 250px; padding:0px 0px 0px 0px; font-size: 11px;  height: 12px;white-space: wrap;position: relative;display: block;overflow: hidden;'><a href='/30_Rock/episodes/780776/3x22'>58: 3x22 -- Kidney Now!</a> (May/14/2009) </span>

			$html =~ /<b>Latest Episode: (.*?)'>([^<]*)<\/a>([^<]*)<\/span>/;
			my $latest = $2.' '.$3;

			$html =~ /<b>Next Episode: (.*?)'>([^<]*)<\/a>([^<]*)<\/span>/;
			my $next = $2.' '.$3;

			$irc->yield( privmsg => $respond => '>> '.$showname.' ('.$showid.') - '.$showcountry );
			$irc->yield( privmsg => $respond => '>> URL: '.$showlink);
			$irc->yield( privmsg => $respond => '>> Latest: '.$latest);
			$irc->yield( privmsg => $respond => '>> Next: '.$next);

		};
		if ($@) {
			$irc->yield( privmsg => $respond => '>> An error occured!');
			print '>> '.$@."\n";
		}
	}	
}

sub about {
	return "Show information from tvrage.com about TV shows.";
}

sub help {
	return "!tv <show> - show information about show from tvrage.";
}

1;
