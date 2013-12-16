use XML::Simple;
use Net::SMTP;
require "asn-common.pl";

local $config = XMLin("config.xml");

my ($msg) = @ARGV;

### following lines is only for tests ###
open MSGFILE, $msg;
my @msg = <MSGFILE>;
close MSGFILE;
### end of testing configuration ###

my ($asn_com) = isProperASN(@msg); 
if ($asn_com) {
	
	#############	The mail is proper ASN protocol	##################
	my @body = getBody (@msg);
	my $host = getHost (@msg);
	
	if ($asn_com =~ /EXC-I/) {
		getData($host,@body);
		sendData($host,"EXC-R");
	}
	if ($asn_com =~ /EXC-R/) {
		hostReceived($host);
		getData(@body);
	}
	if ($asn_com = /ALG-I/) {
		#sendAlgo();
	}
	if ($asn_com =~ /ALG-R/) {
		#getAlgo($body);
	}
	
} else {
	
	############	The protocol is not recognised  #################
	############	doing nothing will discard the msg	#########
}
