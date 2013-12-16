use XML::Simple;
use Net::SMTP;
require "asn-common.pl";

local $config = XMLin("config.xml");
local $hosts = XMLin($config->{config}->{hosts}->{value});

my ($msg) = @ARGV;

cleanSignatures();
#resetHostStatus();

#print getBestHosts($config->{config}->{nbhosttocontact}->{value});


#foreach my $host (getBestHosts($config->{config}->{nbhosttocontact}->{value})) {
	#sendData($host,"EXC-I");
#	setWaitingHost($host);
#}

#my $new_host = getNewHost();
#sendData($new_host, "EXC-I");
#setWaitingHost($host);
