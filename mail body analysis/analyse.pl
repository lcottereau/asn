
sub remove_headers {
	my $msg = $_[0];
	$msg = substr($msg,index($msg,"Subject:"));
	return substr($msg,index($msg,"\n"));
}

sub remove_javascript {
	my $msg = $_[0];
	$msg =~ s#<script>[\s\S]*?</script>##mig;
	return $msg;
}


sub remove_html {
	my $msg = $_[0];
	$msg =~ s/<[^><]*>//mg;
	return $msg;
}

sub remove_url {
	my $msg = $_[0];
	$msg =~ s#\S+://\S+##mg;
	return $msg;
}

sub remove_mailto {
	my $msg = $_[0];
	$msg =~ s/[Mm]ailto\s?:\s?\S+@\S+//mg;
	return $msg;
}

sub remove_numbers {
	my $msg = $_[0];
	$msg =~ s/\s\d*\s//mg;
	return $msg;
}

sub remove_punctuation {
	my $msg = $_[0];
	$msg =~ s/[\.\*_]+//mg;
	return $msg;
}

sub remove_case {
	my $msg = $_[0];
	return lc $msg;
}

sub remove_whitespaces {
	my $msg = $_[0];
	$msg =~ s/\s+/ /mg;
	return $msg;
}

print "debut de l'analyse\n";

#open (SPAMTEST, "spamtest.htm") or die("not able to open the file spamtest.txt");

#my $msg = "";
#while (defined($temp = <SPAMTEST>)) {
#	$msg .= $temp;
#}

#$msg = remove_headers($msg);
#$msg = remove_html($msg);



#open(SPAMLIST, ">spamlist.txt") or die "can't open the spam list file";
#print SPAMLIST $msg;




use Mail::IMAPClient;

my $imap = Mail::IMAPClient->new( 
		Server 	=> "mail.cs.tcd.ie" ,
		User 	=> "gmspammp" ,
		Password=> "lc2948" ,
) or die "can't connect to server\n";

print "now connected to the SPAM IMAP server\n";

$imap->select(INBOX) or die "can't select the INBOX folder";
print "folder INBOX is now selected\n";

print "There are ". $imap->message_count() . " messages in the INBOX folder.";

open(SPAMLIST, ">analyse.txt") or die "can't open the spam list file";
print SPAMLIST "Original Size;After White Spaces;After Numbers;After URLs;After Punctuation;After Javascript;After HTML\n";
close SPAMLIST;
#print "spamlist.txt is open for writing";
my @msgs = $imap->search("ALL");
$i = 0;
$j = 0;
foreach my $m (@msgs) {
	$i++;
	print "$i\n";
	#last if ($i>30);
	open(SPAMLIST, ">>analyse.txt") or die "can't open the spam list file";
	my $msg = $imap->message_string($m);
	#print $msg if ($i==1);
	#print $size1;
	$msg = remove_headers($msg);
	$msg = remove_case($msg);
	
	$j++ if ($msg =~ /<script>/);
	my $size1 = length($msg);
	
	$msg = remove_whitespaces($msg);
	
	my $size5 = length($msg);
	
	$msg = remove_numbers($msg);
	
	my $size2 = length($msg);
	
	$msg = remove_url($msg);
	$msg = remove_mailto($msg);
	
	my $size3 = length($msg);
	
	$msg = remove_punctuation($msg);
	
	my $size4 = length($msg);
	
	$msg = remove_javascript($msg);
	
	my $size6 = length($msg);
	
	#print $msg."\n--------------------\n" if ($i==5);
	
	$msg = remove_html($msg);
	
	#print $msg if ($i==5);
	
	my $size7 = length($msg);
	
	
	#print $msg. "\n---------------------\n";
	
	print SPAMLIST "$size1;$size5;$size2;$size3;$size4;$size6;$size7\n";
	close SPAMLIST;#print "spamlist.txt is open for writing";

}

$imap->close();
print "disconnected from the mail server\n";
print $j if ($j>0);

