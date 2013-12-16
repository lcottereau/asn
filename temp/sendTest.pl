use Net::SMTP;


my $smtp = Net::SMTP->new("mail.cs.tcd.ie") or die "new";
$smtp->mail("laurent.cottereau@cs.tcd.ie") or die "mail";
$smtp->recipient("cotterel@cs.tcd.ie") or die "rcpt";
$smtp->data() or die "data";
$smtp->datasend("To: <clark@minet.net>\n") or die "send";
$smtp->datasend("From: <laurent.cottereau@cs.tcd.ie>\n") or die "send";
$smtp->datasend("Subject: ASN protocol messages\n") or die "send";
$smtp->datasend("X-ASN: EXC-I\n") or die "send";
$smtp->datasend("\n") or die "send";
$smtp->datasend("hosts:\ntest@test.com\nsignatures:\n1--ASN1--laurentcottereau\n\n---------------\net boum") or die "send";
$smtp->dataend or die "end";

$smtp->quit or die "quit";

print "mail envoyé";

