#!perl
# inspired by perl's cmpVERSION
use strict;
use warnings;
use Test::More;
use ExtUtils::MakeMaker;
use File::Spec::Functions 'devnull';

-d ".git"
   or plan skip_all => "Not a git tree";

chomp(my $base_tag = `git describe --abbrev=0`);

my @changed = grep /\.pm$/ && m(/),
  `git diff --name-only $base_tag --diff-filter=ACMRTUXB`;

chomp @changed;

plan tests => scalar @changed;

my @need_update;
for my $file (@changed) {
  my $orig_content = get_file_from_git($file, $base_tag);
  my $orig_version = eval { MM->parse_version(\$orig_content) };
  my $curr_version = eval { MM->parse_version($file) };

  if ($curr_version ne "undef" && $orig_version ne "undef") {
    cmp_ok($curr_version, '>', $orig_version, "$file - out of date");
  }
  elsif ($orig_version ne "undef") {
    fail("$file - version was removed");
  }
  elsif ($curr_version eq "undef") {
    fail("$file - has no version");
  }
  else {
    pass($file);
  }
}

sub get_file_from_git {
    my ($file, $tag) = @_;
    local $/;
    my $null = devnull();
    return scalar `git --no-pager show $tag:$file 2>$null`;
}
