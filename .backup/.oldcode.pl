#finally, spellcheck it all.
	if ($command eq 0 and $stfu eq 0) {
		my $misspelled = '';
		my $c = 0;


		$arg =~ s/[^a-zA-Z0-9 \-']//gi;

		#strip whitelist
		my $all = $dbh->selectall_arrayref("select * from whitelist");
		foreach my $row (@$all) {
			my ($id, $r) = @$row;

			$arg =~ s/(^| )$r( |$)/ /gi;
		}

		my @allwords = split(/ /, $arg);
		my $numw = @allwords;

		open (WC, 'echo "'.$arg.'" | aspell list |');
		while (<WC>) {
			my $x = $_;
			$x =~ s/\n//g;

			$misspelled = $misspelled." ".$x;
			$c+=1;
		}
		close(WC);

		if ($c > 0) {
			$poeirc->yield( privmsg => $channel => '>> Misspelled:'.$misspelled);
		}

		# update db
		my @check = @{ $dbh->selectall_arrayref("select id from users where `nick`='$nick';") };
		
		if (@check eq 0) {
			$dbh->do("insert into users (nick, words_total, words_errors) values ('$nick', $numw, $c);");
		} else {

			my @res = $dbh->selectrow_array("select id, nick, words_total, words_errors, words_streak from users where `nick`='$nick';");

			my $newtotal = @res[2] + $numw;
			my $newspills = @res[3] + $c;

			my $streak;			
			if ($c eq 0) {
				$streak = @res[4] + $numw;
			} else {
				$poeirc->yield( privmsg => $channel => '>> '.$nick.' broke a streak of '.@res[4].' words!');
				$streak = 0;
			}

			$dbh->do("update users set `words_total`=$newtotal , `words_errors`=$newspills, `words_streak`=$streak where `nick`='$nick';");
			
		}
	}
	
	
	if ( $arg =~ /^!stfu/ ) {
		$command = 1;

		my @res = $dbh->selectrow_array("select * from users where `nick`='$nick' and `isadmin`=1;");
                if (@res) {
			if ($stfu eq 0) {
				$stfu = 1;
				$poeirc->yield( privmsg => $channel => '>> Shuts the fuck up.');
			} else {
				$stfu = 0;
				$poeirc->yield( privmsg => $channel => '>> Spellstats enabled.');
			}
		} else {
			$poeirc->yield( privmsg => $channel => '>> Don\'t tell me to stfu.');
		}
		
	}
	
	if ( $arg =~ /^!stats/ ) {
		$command = 1;
		
		my $nick_longest = 0;
		my $tota_longest = 0;
		my $erro_longest = 0;
		my $stre_longest = 0;

		my $data = $dbh->selectall_arrayref("select id, nick, words_total, words_errors, words_streak, words_percent from users;");
		foreach my $row(@$data) {

			my $len = length(@$row[1]);
			$nick_longest = $len if ($len > $nick_longest);
			$tota_longest = $len if ($len > $tota_longest);

			my $perc = 0;
			if (@$row[2] ne 0) {
				$perc = sprintf( "%.3f", ((@$row[2]-@$row[3])/@$row[2])*100 );
			}

			$dbh->do("update users set `words_percent`=$perc where `nick`='".@$row[1]."';");
		}

		my $spellstats = $dbh->selectall_arrayref("select id, nick, words_total, words_errors, words_streak, words_percent from users order by words_percent desc;");

		my $hn = " "x($nick_longest-4);
		$poeirc->yield( privmsg => $channel => '>>  #  Nick'.$hn.' - Percent - Total - Errors - Streak');
	
		my $place = 1;	
		foreach my $row (@$spellstats) {
			my ($id, $n, $total, $slips, $streak, $percent) = @$row;

			my $nickpad = " "x($nick_longest-length($n));
			my $totapad = " "x(5-length($total));
			my $erropad = " "x(6-length($slips));
			my $strepad = " "x(6-length($streak));
			my $percentpad = " "x(6-length($percent));
	
			$poeirc->yield( privmsg => $channel => '>> ['.$place.'] '.$n.$nickpad.' - '.$percent.'%'.$percentpad.' - '.$totapad.$total.' - '.$erropad.$slips.' - '.$strepad.$streak );
			$place += 1;
		}
	}
	
	if ($arg =~ /^!add ([a-zA-Z\-]*)/i) {
		$command = 1;
		my $addee = $1;

		my @res = @{ $dbh->selectall_arrayref("select * from whitelist where `regex`='$addee';") };
		my $n = @res;
		if ($n eq 0) {
			$dbh->do("insert into whitelist (regex) values ('$addee')");
			$poeirc->yield( privmsg => $channel => '>> '.$addee.' added to whitelist.');
		} else {
			$poeirc->yield( privmsg => $channel => '>> '.$addee.' already in whitelist.');
		}

	}