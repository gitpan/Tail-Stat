use inc::Module::Install;

name           'Tail-Stat';
all_from       'lib/Tail/Stat.pm';
license        'perl';

requires       'DateTime'           => 0;
requires       'JSON::XS'           => 0;
requires       'Log::Dispatch'      => 2.26;
requires       'POE'                => 0;
requires       'Pid::File::Flock'   => 0;
requires       'Sys::Syslog'        => 0.16;
requires       'Tie::Hash::Indexed' => 0;

test_requires  'Test::More'         => 0;

auto_install;

WriteAll;

