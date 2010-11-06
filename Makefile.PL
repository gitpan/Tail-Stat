use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Tail::Stat',
    AUTHOR              => q{Oleg A. Mamontov <oleg@mamontov.net>},
    VERSION_FROM        => 'lib/Tail/Stat.pm',
    ABSTRACT_FROM       => 'lib/Tail/Stat.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'DateTime'           => 0,
        'JSON::XS'           => 0,
        'Log::Dispatch'      => 2.26,
        'POE'                => 0,
        'Pid::File::Flock'   => 0,
        'Sys::Syslog'        => 0.16,
        'Test::More'         => 0,
        'Tie::Hash::Indexed' => 0,
    },
    EXE_FILES           => [ 'bin/tstatd' ],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Tail-Stat-*' },
);

