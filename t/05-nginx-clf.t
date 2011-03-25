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

		open EX,'<','t/ex/nginx' or die $!;
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
		is $s->getline => "http_byte: 4818396\r\n";
		is $s->getline => "http_method_get: 188\r\n";
		is $s->getline => "http_method_head: 0\r\n";
		is $s->getline => "http_method_inc: 0\r\n";
		is $s->getline => "http_method_other: 3\r\n";
		is $s->getline => "http_method_post: 9\r\n";
		is $s->getline => "http_request: 200\r\n";
		is $s->getline => "http_status_1xx: 0\r\n";
		is $s->getline => "http_status_2xx: 175\r\n";
		is $s->getline => "http_status_3xx: 3\r\n";
		is $s->getline => "http_status_404: 13\r\n";
		is $s->getline => "http_status_499: 2\r\n";
		is $s->getline => "http_status_4xx: 15\r\n";
		is $s->getline => "http_status_500: 2\r\n";
		is $s->getline => "http_status_502: 3\r\n";
		is $s->getline => "http_status_5xx: 7\r\n";
		is $s->getline => "http_version_0_9: 3\r\n";
		is $s->getline => "http_version_1_0: 22\r\n";
		is $s->getline => "http_version_1_1: 175\r\n";
		is $s->getline => "last_http_byte: 4818396\r\n";
		is $s->getline => "last_http_request: 200\r\n";
		is $s->getline => "malformed_request: 0\r\n";
		alarm 0;
	},
	server => sub {
		my $port = shift;
		$ENV{ PERL5LIB } = join ':', @INC;
		exec qq($^X $bin -b$db -f -l$port --log-level=error -o clf -p$pid -w1 nginx x:$log);
	},
);

done_testing;

END {
	-f $_ and unlink $_ for $db,$log,$pid;
}

