use XML::Simple;
require "asn-common.pl";

local $config = XMLin("config.xml");
local $signatures = XMLin($config->{config}->{signatures}->{value});
local $algorithms = XMLin($config->{config}->{algorithms}->{value});

my (@mail) = <STDIN>;


### following lines is only for tests ###
#open MSGFILE, $mail;
#my @mail = <MSGFILE>;
#close MSGFILE;
### end of testing configuration ###

my $score=0;

if (isWhitelisted(getHost(@mail))) {
	print "whitelisted\n";
	exit 0;
}

foreach my $sig (keys %{$signatures->{signature}}) {
	my $algo = $signatures->{signature}->{$sig}->{algo};
	require $algorithms->{algorithm}->{$algo}->{url};
	if (asnSignatureIsSimilar($sig, @mail)) {
		$score += getSignatureScore($sig, $signatures);
	}
}
if (isSpam($score)) {
	print "this is spam\n";
	exit 1;
} else {
	print "this is not spam\n";
	exit 0;
}
