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

		open EX,'<','t/ex/cvsupd' or die $!;
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
		is $s->getline => "bytes_in: 593521664\r\n";
		is $s->getline => "bytes_out: 416476160\r\n";
		is $s->getline => "client:CSUP_1_0/17.0: 213\r\n";
		is $s->getline => "client:SNAP_16_1h/17.0: 5\r\n";
		is $s->getline => "clients: 218\r\n";
		is $s->getline => "collection:ports-all/cvs: 223\r\n";
		is $s->getline => "collections: 223\r\n";
		is $s->getline => "last_bytes_in: 593521664\r\n";
		is $s->getline => "last_bytes_out: 416476160\r\n";
		is $s->getline => "last_clients: 218\r\n";
		is $s->getline => "last_collections: 223\r\n";
		is $s->getline => "status:Finished successfully: 223\r\n";
		alarm 0;
	},
	server => sub {
		my $port = shift;
		exec qq( $bin -b$db -f -l$port --log-level=error -p$pid -w1 cvsupd x:$log );
	},
);

done_testing;

END {
	-f $_ and unlink $_ for $db,$log,$pid;
}

