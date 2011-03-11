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

		open EX,'<','t/ex/apache' or die $!;
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
		is $s->getline => "http_byte: 1332496\r\n";
		is $s->getline => "http_method_get: 143\r\n";
		is $s->getline => "http_method_head: 3\r\n";
		is $s->getline => "http_method_inc: 3\r\n";
		is $s->getline => "http_method_other: 2\r\n";
		is $s->getline => "http_method_post: 49\r\n";
		is $s->getline => "http_request: 200\r\n";
		is $s->getline => "http_status_1xx: 0\r\n";
		is $s->getline => "http_status_2xx: 187\r\n";
		is $s->getline => "http_status_3xx: 3\r\n";
		is $s->getline => "http_status_404: 5\r\n";
		is $s->getline => "http_status_499: 0\r\n";
		is $s->getline => "http_status_4xx: 7\r\n";
		is $s->getline => "http_status_500: 3\r\n";
		is $s->getline => "http_status_502: 0\r\n";
		is $s->getline => "http_status_5xx: 3\r\n";
		is $s->getline => "http_version_0_9: 2\r\n";
		is $s->getline => "http_version_1_0: 190\r\n";
		is $s->getline => "http_version_1_1: 5\r\n";
		is $s->getline => "last_http_byte: 1332496\r\n";
		is $s->getline => "last_http_request: 200\r\n";
		is $s->getline => "malformed_request: 0\r\n";
		alarm 0;
	},
	server => sub {
		my $port = shift;
		$ENV{ PERL5LIB } = join ':', @INC;
		exec qq( $bin -b$db -f -l$port --log-level=error -o clf -p$pid -w1 apache x:$log );
	},
);

done_testing;

END {
	-f $_ and unlink $_ for $db,$log,$pid;
}

