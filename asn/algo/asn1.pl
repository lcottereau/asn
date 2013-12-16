use Digest::SHA1 qw(sha1_base64);

require "asn-common.pl";


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

sub asnCreateSignature {
	my @msg = @_;
	my @body = getBody(@msg);
	
	#print "asn1\n";
	
	$body = join "\n", @body;
	
	$body = remove_case($body);
	$body = remove_whitespaces($body);
	$body = remove_numbers($body);
	$body = remove_url($body);
	$body = remove_mailto($body);
	$body = remove_punctuation($body);
	$body = remove_javascript($body);
	$body = remove_html($body);
	
	$digest = sha1_base64($body);
	
	#print $digest;
	#print $body;
	
	return $digest;
	
}

sub asnSignatureIsSimilar {
	my ($sig1, @msg) = @_;
	return ($sig1 eq asnCreateSignature(@msg));
}


asnCreateSignature(@mail);
