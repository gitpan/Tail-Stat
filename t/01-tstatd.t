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

test_tcp(
	client => sub {
		my $s = IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => shift );

		alarm 1;
		print $s "zones\n";
		is $s->getline => "a:x\r\n";
		alarm 0;
	},
	server => sub {
		my $port = shift;
		exec qq( $bin -b$db -f -l$port --log-level=error -p$pid apache x:$log );
	},
);

done_testing;

END {
	-f $_ and unlink $_ for $db,$log,$pid;
}

