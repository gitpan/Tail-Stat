#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::TCP;


my $bin = 'bin/tstatd';
my $db  = 't/db';
my $log = 't/log';
my $pid = 't/pid';

die 'tstatd not found' unless -f $bin && -x _;

-f $_ and unlink $_ for $db,$log,$pid;

$SIG{ ALRM } = sub { die 'test timed out' };

open FH,'>',$log or die $!; close FH;

test_tcp(
	client => sub {
		my $s = IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => shift );

		alarm 1;
		print $s "zones\n";
		is $s->getline => "a:x\r\n";
		alarm 0;

		open EX,'<','t/ex/clamd' or die $!;
		open FH,'>>',$log or die $!;
		print FH do { local $/=<EX> };
		close EX; close FH;
		sleep 2;

		my $len = (stat $log)[7];

		alarm 1;
		print $s "files x\n";
		like $s->getline => qr"^$len:$len:/.*/t/log";
		alarm 0;

		alarm 1;
		print $s "stats x\n";
		is $s->getline => "clean: 1207\r\n";
		is $s->getline => "last_clean: 1207\r\n";
		is $s->getline => "last_malware: 8\r\n";
		is $s->getline => "malware: 8\r\n";
		is $s->getline => "malware:Exploit.HTML.IFrame-8: 4\r\n";
		is $s->getline => "malware:Suspect.DoubleExtension-zippwd-9: 1\r\n";
		is $s->getline => "malware:Worm.NetSky-14: 3\r\n";
		alarm 0;
	},
	server => sub {
		my $port = shift;
		exec qq( $bin -b$db -f -l$port --log-level=error -o type -p$pid -w1 clamd x:$log );
	},
);

done_testing;

END {
	-f $_ and unlink $_ for $db,$log,$pid;
}

