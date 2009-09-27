use 5.010; #because of use warnings
use warnings;
use inc::Module::Install;

use ExtUtils::Depends;

name 'PerlX-Range';
all_from 'lib/PerlX/Range.pm';

configure_requires 'ExtUtils::Depends', '0.302';
configure_requires 'B::Hooks::OP::Check', '0.18';

requires 'B::Hooks::EndOfScope';
requires 'B::Hooks::OP::Check';

tests 't/*.t';
author_tests 'xt';

repository 'http://github.com/gugod/PerlX-Range';

build_requires 'Test::More' => 0.88;
uto_include;

my $pkg = ExtUtils::Depends->new('PerlX::Range', 'B::Hooks::OP::Check');
$pkg->add_xs("Range.xs");
$pkg->add_pm("lib/PerlX/Range.pm" => '$(INST_LIB)/PerlX/Range.pm');

makemaker_args($pkg->get_makefile_vars);

WriteAll;
