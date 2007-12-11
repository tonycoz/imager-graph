#!perl -w
use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.08;";
# 1.08 required for coverage_class support
plan skip_all => "Test::Pod::Coverage 1.08 required for POD coverage" if $@;

all_pod_coverage_ok();
