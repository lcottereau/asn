use Data::Dumper;

sub isProperASN {
	my @msg = @_;
	my $i = 0;
	while ($i<@msg) {
		if ($msg[$i] =~ /^X-ASN:\s+(\w\w\w-\w)/) {
			return $1;
		} else {
			$i++;
		}
	}
	return 0;
}

sub getHost {
	my @msg = @_;
	for (my $i=0; $i<@msg; $i++) {
		if ($msg[$i] =~ /From\s*:.*\s(\S*@\S*)\s.*/i) {
			return $1;
		}
	}
	return "unknown";
}

sub getBody {
	my @msg = @_;
	my $found = 0;
	while (@msg && (!$found)) {
		$found = ($found || (!($msg[0] =~ /[^ \n\t]/)));
		shift(@msg);
	}
	return @msg;
}

sub addHosts {
	my @new_hosts = @_;
	open(FILEH, '+<', $config->{config}->{hosts}->{value}) or die "couldn't open file";
	my $host_file = "";
	while ($line = <FILEH>) {
		for ($i=0; $i<@new_hosts; $i++) {
			if (index($line,$new_hosts[$i])>-1) {
				splice(@new_hosts,$i,1);
				$i--;
			}
		}
		if ($line =~ /<\/hosts>/) {
			for ($i=0; $i<@new_hosts; $i++) {
				$host_file .= "\<host id=\"$new_hosts[$i]\" lastdate=\"".time."\" score=\"0\" status=\"ok\"/>\n";
			}
		}
		$host_file .= $line;
	}
	seek (FILEH, 0, 0);
	truncate (FILEH, 0);
	print FILEH $host_file;
	close FILEH;
}


sub revokeSignatures {
	my (@sigs) = @_;
	open(FILEH, '+<', $config->{config}->{signatures}->{value}) or die "couldn't open file";
	my $sig_file = "";
	while ($line = <FILEH>) {
		for ($i=0; $i<@sigs; $i++) {
			if (index($line,$sigs[$i])>-1) {
				splice(@sigs,$i,1);
				$i--;
				while (not $line =~ /<\/signature>/) {
					$line = <FILEH>;
				}
				$line = "";
			}
		}
		$sig_file .= $line;
	}
	seek (FILEH, 0, 0);
	truncate (FILEH, 0);
	print FILEH $sig_file;
	close FILEH;
}

sub addSignatures {
	my ($host, @new_sigs) = @_;
	open(FILEH, '+<', $config->{config}->{signatures}->{value}) or die "couldn't open file";
	my $sig_file = "";
	while ($line = <FILEH>) {
		for ($i=0; $i<@new_sigs; $i++) {
			$new_sigs[$i] =~ /(\S)--\S\S\S\S--(.*)/;
			my ($i_hops,$i_sig) = ($1,$2);
			if (index($line,$i_sig)>-1) {
				
				my $hops = $i_hops;
				if ($config->{config}->{sighoptolive}->{value} < $i_hops) {
					$hops = $config->{config}->{sighoptolive}->{value};
				}
				
				$line =~ s/hops=\"$i_hops\"/hops=\"$hops\"/;
				
				splice(@new_sigs,$i,1);
				$i--;
				$same_email = 0;
				while (not $line =~ /<\/signature>/) {
					$same_email = index($line,$host)>-1;
					$sig_file .= $line;
					$line = <FILEH>;
				}
				if (not $same_email) {
					$sig_file .= "\t\t<sender id=\"$host\" date=\"".time."\" />\n";
				}
			}
		}
		if ($line =~ /<\/signatures>/) {
			for ($i=0; $i<@new_sigs; $i++) {
				$new_sigs[$i] =~ /(\S)--(\S\S\S\S)--(.*)/;
				my ($i_hops, $i_algo, $i_sig) = ($1, $2, $3);
				
				my $hops = $i_hops;
				if ($config->{config}->{sighoptolive}->{value} < $i_hops) {
					$hops = $config->{config}->{sighoptolive}->{value};
				}
				
				$sig_file .= "\t<signature id=\"$i_sig\" algo=\"$i_algo\" hops=\"$hops\">\n";
				$sig_file .= "\t\t<sender id=\"$host\" date=\"".time."\" />\n";
				$sig_file .= "\t</signature>\n";
			}
		}
		$sig_file .= $line;
	}
	seek (FILEH, 0, 0);
	truncate (FILEH, 0);
	print FILEH $sig_file;
	close FILEH;
}

sub getData {
	my ($host, @body) = @_;
	
	my @new_hosts, @new_sigs;
	push @new_hosts, $host;
	my ($ind_host,$ind_sig) = (0,0);
	for ($i=0;$i<@body;$i++) {
		if ($body[$i] =~ /hosts:/) {
			$ind_host=1;
			$ind_sig=0;
		} else {if ($body[$i] =~ /signatures:/) {
			$ind_host=0;
			$ind_sig=1;
		} else {if ($body[$i] =~ /^\s*$/) {
			$ind_host=0;
			$ind_sig=0;
		} else {if ($ind_host) {
			if ($body[$i] =~ /^\t([^\s\n]*)\n$/) {
				push @new_hosts, $1;
			}
		} else {if ($ind_sig) {
			if ($body[$i] =~ /^\t([^\s\n]*)\n$/) {
				push @new_sigs, $1;
			}
		}}}}}
	}
	addHosts(@new_hosts);
	addSignatures($host, @new_sigs);
}

sub getLowestIndex {
	my @list = @_;
	$lowest = 0;
	for ($i=1;$i<@list;$i++) {
		if ($list[$i]<$list[$lowest]) {
			#print "lower\n";
			$lowest = $i ;
		}
	}
	return $lowest;
}

sub getBestHosts {
	my ($nb) = @_;
	my @best;
	my $hosts = XMLin($config->{config}->{hosts}->{value});
	foreach my $hst (keys %{$hosts->{host}}) {
		if ($nb>@best) {
			push(@best, $hst);
		} else {
			my @bestscores;
			for (my $i=0; $i<@best; $i++) {
				push @bestscores, $hosts->{host}->{$best[$i]}->{score};
			}
			my $lowest = getLowestIndex(@bestscores);
			if ($hosts->{host}->{$hst}->{score} > $bestscores[$lowest]) {
				$best[$lowest]=$hst;
			}
		}
	}
	return @best;
}

sub getLatestSigs {
	my $signatures = XMLin($config->{config}->{signatures}->{value});
	my @latest_sigs;
	foreach my $sig (keys %{$signatures->{signature}}) {
		if ($signatures->{signature}->{$sig}->{hops}) {
			my $new_hops = $signatures->{signature}->{$sig}->{hops} - 1;
			if ($new_hops) { 
				push @latest_sigs, "$new_hops--$signatures->{signature}->{$sig}->{algo}--$sig";
			}
		}
	}
	return @latest_sigs;
}

sub getSignatureScore {
	my ($sig, $signatures) = @_;
	%sig = %{$signatures->{signature}->{$sig}};
	my $score = 0;
	#print Dumper $signatures->{signature}->{$sig};
	#print %{$sig{sender}}." - ";
	if (${$sig{sender}}{id}) {
		hasScoredSpam(${$sig{sender}}{id});
		return 1;
	} else {
		print "they have scored ";
		print keys %{$sig{sender}};
		hasScoredSpam(keys %{$sig{sender}});
		return scalar keys %{$sig{sender}};
	}
}

sub sendData {
	my ($host,$header) = @_;
	my @hosts = getBestHosts($config->{config}->{nbhosttosend}->{value});
	my @sigs = getLatestSigs();
	
	my $body = "hosts:\n";
	for (my $i=0; $i<@hosts; $i++) {
		$body .= "$hosts[$i]\n";
	}
	$body .= "signatures:\n";
	for (my $i=0; $i<@sigs; $i++) {
		$body .= "$sigs[$i]\n";
	}
	
	$body .= "\n--------------\nIf you don't know what the AntiSpamNetwork is, please ignore this message\n";
	
	print $body;
	
	my $smtp = Net::SMTP->new($config->{config}->{smtpserver}->{value});
	
	my $email = $config->{config}->{email}->{value};
	#print $email."\n";
	
	$smtp->mail($email) or die "pb with to";
	$smtp->recipient($host) or die "pb with rcpt $!";
	
	$smtp->data() or die "pb with data";
	$smtp->datasend("To: $host\n") or die "pb with data";
	$smtp->datasend("From: ".$config->{config}->{email}->{value}."\n") or die "pb with data";
	$smtp->datasend("Subject: ASN protocol message\n") or die "pb with data";
	$smtp->datasend("X-ASN: $header\n") or die "pb with data";
	$smtp->datasend("\n") or die "pb with data";
	$smtp->datasend($body) or die "pb with data";
	$smtp->dataend() or die "pb with end";
	
	$smtp->quit;
}

sub isSpam {
	my ($score) = @_;
	return ($score > $config->{config}->{spamthread}->{value});
}

sub getNewHost {
	foreach my $host (keys %{$hosts->{host}}) {
		if ($hosts->{host}->{$host}->{score}==0) {
			return $host;
		}
	}
}

sub hostReceived {
	my ($host) = @_;
	changeHostStatus($host, "waiting", "ok");
}



sub setWaitingHost {
	my ($host) = @_;
	changeHostStatus($host, "ok", "waiting");
}

sub changeHostStatus {
	my ($host, $oldstatus, $newstatus) = @_;
	open(FILEH, '+<', $config->{config}->{hosts}->{value}) or die "couldn't open file";
	my $host_file = "";
	while ($line = <FILEH>) {
		if (index($line,$host)>-1) {
			$line =~ s/status=\"$oldstatus\"/status=\"$newstatus\"/;
		}
		$host_file .= $line;
	}
	seek (FILEH, 0, 0);
	truncate (FILEH, 0);
	print FILEH $host_file;
	close FILEH;
}

sub resetHostStatus {
	open(FILEH, '+<', $config->{config}->{hosts}->{value}) or die "couldn't open file";
	my $host_file = "";
	while ($line = <FILEH>) {
		if ($line =~ /status=\"waiting\"/) {
			print "waiting";
			$line =~ /score=\"([^\"]*)\"/;
			my $new_score = $1 - 1;
			$line =~ s/status=\"waiting\"/status=\"ok\"/;
			$line =~ s/score=\"[^\"]*\"/score=\"$new_score\"/;
		}
		$host_file .= $line;
	}
	seek (FILEH, 0, 0);
	truncate (FILEH, 0);
	print FILEH $host_file;
	close FILEH;
}

sub hasScoredSpam {
	my (@scorers) = @_;
	open(FILEH, '+<', $config->{config}->{hosts}->{value}) or die "couldn't open file";
	my $host_file = "";
	while ($line = <FILEH>) {
		for ($i=0; $i<@scorers; $i++) {
			if (index($line,$scorers[$i])>-1) {
				splice(@scorers,$i,1);
				$i--;
				$line =~ /score=\"([^\"]*)\"/;
				my $new_score = $1 +5;
				$line =~ s/score=\"[^\"]*\"/score=\"$new_score\"/;
			}
		}
		$host_file .= $line;
	}
	seek (FILEH, 0, 0);
	truncate (FILEH, 0);
	print FILEH $host_file;
	close FILEH;
}

sub cleanSignatures {
	open(FILEH, '+<', $config->{config}->{signatures}->{value}) or die "couldn't open file";
	my $sig_file = "";
	while ($line = <FILEH>) {
		if (index($line,"<signature")>-1) {
			my $temp_sig_file = "";
			my $latest_date = 0;
			while (index($line, "</signature>")==-1) {
				if ($line =~ /date=\"(\d*)\"/) {
					#print "$1\n";
					if ($latest_date < $1) {
						#print "plus ancienne";
						$latest_date = $1;
					}
				}
				$temp_sig_file .= $line;
				$line = <FILEH>;
			}
			$temp_sig_file .= $line;
			$line = "";
			if ($latest_date+$config->{config}->{siglifetime}->{value} > time) {
				$sig_file .= $temp_sig_file;
			} else {
				print "too old: ".($latest_date+$config->{config}->{siglifetime}->{value})."\n";
			}
		}
		$sig_file .= $line;
	}
	seek (FILEH, 0, 0);
	truncate (FILEH, 0);
	print FILEH $sig_file;
	close FILEH;
}

sub isWhitelisted {
	my ($host) = @_;
	open(FILEH, '+<', $config->{config}->{whitelist}->{value}) or die "couldn't open file";
	while ($line = <FILEH>) {
		if ($line =~ /id=\"$host\"/) {
			#print $line;
			close FILEH;
			return 1;
		}
	}
	close FILEH;
	return 0;
}

1;
