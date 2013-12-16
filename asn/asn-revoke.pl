use XML::Simple;
#use Data::Dumper;

require "asn-common.pl";

local $config = XMLin("config.xml");
local $algo = XMLin($config->{config}->{algorithms}->{value});

require $algo->{algorithm}->{$config->{config}->{defaultalgo}->{value}}->{url};

my ($mail) = @ARGV;


### following lines is only for tests ###
open MSGFILE, $mail;
my @mail = <MSGFILE>;
close MSGFILE;
### end of testing configuration ###


my $new_sig = asnCreateSignature(@mail);

revokeSignatures($new_sig);

