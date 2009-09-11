use inc::Module::Install;
name 'PerlX-Range';
all_from 'lib/PerlX/Range.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';

auto_include;
WriteAll;
