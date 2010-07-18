#!/usr/bin/perl

# Some simple Google related commands.

use strict;
use WWW::Mechanize;

package talonplug::google;

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;

	if ( $message =~ /^!google (.*)/ ) {
		my $q = $1;

		eval {
			my $mech = WWW::Mechanize->new();
			$mech->get('http://www.google.co.uk/');
			$mech->form_number(1);
			$mech->field('q' => $q);
		
			my $res = $mech->click('btnG');
			my $html = $res->content;

			if ( $html =~ /did not match any documents/ ) {
				$irc->yield( privmsg => $respond => '>> No results found.');
			} else {
				$html =~ /<h3 class=r>(.*?)<\/h3>/;
				my $res = $1;
				$res =~ s/(<em>|<\/em>)//g;
				$res =~ /href="(.*?)"/;
		
				$irc->yield( privmsg => $respond => '>> '.$1);
			}
		};
		if ($@) {
			$irc->yield( privmsg => $respond => '>> An error occured!');
			#$irc->yield( privmsg => $respond => '>> '.$@) if ($config_debug eq 1);
		}
	}

	if ( $message =~ /^!define (.*)/ ) {
		my $q = $1;

		eval {		
			my $mech = WWW::Mechanize->new();

			$mech->get('http://www.google.co.uk/');
			$mech->form_number(1);
			$mech->field('q' => 'define: '.$q);

			my $res = $mech->click('btnG');
			my $html = $res->content;

			if ( $html =~ /No definitions were found for/ ) {
				$irc->yield( privmsg => $respond => '>> Sorry, no results found.');
			} else {
				$html =~ /<ul type="disc" class=std><li>(.*?)(<\/li>|<br>|<li>)/;
				$irc->yield( privmsg => $respond => '>> '.$1);
			}
		};
		if ($@) {
			$irc->yield( privmsg => $respond => '>> An error occured!');
			#$irc->yield( privmsg => $respond => '>> '.$@) if ($config_debug eq 1);
		}
	
	}

	if ( $message =~ /^!gcalc (.*)/ ) {
		my $q = $1;
		
		eval {
			my $mech = WWW::Mechanize->new();

			$mech->get('http://www.google.co.uk/');
			$mech->form_number(1);
			$mech->field('q' => $q);

			my $res = $mech->click('btnG');
			my $html = $res->content;

			if ( $html =~ /More about calculator\./ ) {			
				# style="font-size:138%"><b>the speed of light = 299 792 458 m / s</b>
				$html =~ /font-size:138\%"><b>([^<]*)<\/b>/;
				$irc->yield( privmsg => $respond => '>> '.$1);
			} else {
				$irc->yield( privmsg => $respond => '>> Sorry, no calculator results found.');
			}
		};
		if ($@) {
			$irc->yield( privmsg => $respond => '>> An error occured!');
			#$irc->yield( privmsg => $respond => '>> '.$@) if ($config_debug eq 1);
		}
	}

	if ( $message =~ /^!distance ([a-z0-9- ]*) and ([a-z0-9- ]*)/i ) {
		eval {
			my $from = $1;
			my $to = $2;

			my $mech = WWW::Mechanize->new();
			my $url = 'http://maps.google.co.uk/maps?f=d&source=s_d&saddr='.$from.'&daddr='.$to;
			$mech->get($url);
			my $html = $mech->content;

			if ( $html =~ /We could not calculate directions between/ ) {
				$irc->yield( privmsg => $respond => '>> Cannot find directions!');
			} if ( $html =~ /Did you mean/ ) {
				$irc->yield( privmsg => $respond => '>> Please be more specific!');
			} else {
				$html =~ /<div id=dir_title>(.*?)<\/div>(.*?)<b>(.*?)<\/b>(.*?)<b>(.*?)<\/b>/;
				my $text = $1;
				my $miles = $3;
				my $time = $5;

				$miles =~ s/&(.*?);//gi;

				$irc->yield( privmsg => $respond => '>> '.$miles.' - about '.$time);
				$irc->yield( privmsg => $respond => '>> '.$url);
			}

		};
		if ($@) {
			$irc->yield( privmsg => $respond => '>> An error occured!');
			#$irc->yield( privmsg => $respond => '>> '.$@) if ($config_debug eq 1);
		}

	}
}

sub about {
	return "Adds extensive Google related commands.";
}

sub help {
	return "!google <query> - perform Google search.\n".
		"!distance <x> and <y> - distance between x and y.\n".
		"!gcalc <query> - finds Google calculator results.\n".
		"!define <phrase> - use Google to define a phrase's meaning.";
}

1;
