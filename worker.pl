#!/usr/bin/perl 
use strict;
use warnings;

$| = 1;
my $timeout = 1;

sub read_msg_or_timeout {
  my ($fh) = @_;
  my $n;
  my $char = "";
  my $msg;

  eval {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm $timeout;

    while (sysread($fh, $char, 1)) {
      if ($char eq ':') {
	sysread($fh, $msg, int($n));
	return $msg;
      } else {
	$n .= $char;
      }
    }

    alarm 0;
  };

  return "";
}

open(my $out, ">", "perl.out") || die $!;

my $pidmsg = "{pid:$$}";
my $pidmsglen = length($pidmsg);

while (1) {
  print "$pidmsglen:$pidmsg";
  print "9:heartbeat";
  print "8:amessage";
  print "9:heartbeat";
  print "8:amessage";
  print "9:heartbeat";
  print "8:amessage";
  print "9:heartbeat";
  print "8:amessage";
  print "9:heartbeat";
  print "8:amessage";

  my $msg = read_msg_or_timeout(*STDIN);
  if ($msg eq "ping") {
    print $out "$msg\n";
  }
}

