use 5.010; #because of use warnings
use warnings;
use inc::Module::Install;

use ExtUtils::Depends;

name 'PerlX-Range';
all_from 'lib/PerlX/Range.pm';

requires 'B::Hooks::EndOfScope';
requires 'B::Hooks::OP::Check' => '0.18';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More' => 0.88;
auto_include;

my $pkg = ExtUtils::Depends->new('PerlX::Range', 'B::Hooks::OP::Check');
$pkg->add_xs("Range.xs");
$pkg->add_pm("lib/PerlX/Range.pm" => '$(INST_LIB)/PerlX/Range.pm');

makemaker_args($pkg->get_makefile_vars);

WriteAll;
