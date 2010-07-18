#!/usr/bin/perl

# Maths functions

use strict;
package talonplug::maths;

use IO::CaptureOutput 'qxx';

sub new {
	my $self = { };
	return bless $self;
}

sub on_public {
	my ($self, $irc, $sql, $message, $nick, $respond, $host ) = @_;
	
	if ($message =~ /^> ([a-zA-Z0-9\-+*\/\(\)^%!\[\]\.,{}=_#:; ]*)/i) {
		my $in = $1;
		$in =~ s/(dir|shell|system|rmdir|ls|mkdir|rename|unlink)[^\n]*//g;
		$in =~ s/(umask|mkfifo|readdir|popen|fork|cd|chdir|getpw|pwd)[^\n]*//g;

		if ( $in =~ /^([ ]*)$/ ) {
			$irc->yield( privmsg => $respond => "No input." );
		} else {
			my $ans = 'octave -q --eval "'.$in.'"';

			open (PS, "$ans |");
			while ( <PS> ) {
				$irc->yield( privmsg => $respond => "$_");
			}

			close(PS);
		}
	}

	if ($message =~ /^: (.*)/i) {
		my $in = $1;

		# make $in safe
		open( FILE, '<talonplug/mathematica.txt' );
		while (<FILE>) {
			my $l = $_;
			if ( $in =~ /$l/i ) {
				$irc->yield( privmsg => $respond => '>> Bad input!');
				return;
			}
		}
		close(FILE);

		my $command = 'math -run "\$Messages={OutputStream[\"stderr\", 2]};'.
				'WriteString[\"stderr\", ToString[ToExpression[\"'.$in.'\"], InputForm]];Quit[];"';

		my ($stdout, $stderr, $ok) = qxx( $command );

		$irc->yield( privmsg => $respond => $stderr);
	}
	
	if ( $message =~ /^!msearch (.*)/ ) {
		my $query = $1;


	}
}

sub about {
	return "A plugin to add maths functions.";
}

sub help {
	return "> (equation) - do calculation.\n".
		": (stuff) - Mathematica.";
}

1;
