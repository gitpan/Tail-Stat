#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Tail::Stat' );
    use_ok( 'Tail::Stat::Plugin' );
    use_ok( 'Tail::Stat::Plugin::nginx' );
}

diag( "Testing Tail::Stat $Tail::Stat::VERSION, Perl $], $^X" );

