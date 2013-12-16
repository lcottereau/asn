use Digest::SHA1 qw(sha1_base64);

require "asn-common.pl";

sub asnCreateSignature {
	my @msg = @_;
	my @body = getBody(@msg);
	
	$digest = sha1_base64(@body);
	
	#print $digest;
	
	#print @body;
	return $digest;
}

sub asnSignatureIsSimilar {
	my ($sig1, @msg) = @_;
	return ($sig1 eq asnCreateSignature(@msg));
}


asnCreateSignature(@mail);
