#!perl -w
use strict;
use Imager::Graph::Line;
use lib 't/lib';
use Imager::Font::Test;
use Test::More;
use Imager::Graph::Test 'cmpimg';

-d 'testout' 
  or mkdir "testout", 0700 
  or die "Could not create output directory: $!";

++$|;

my @warned;
local $SIG{__WARN__} =
  sub {
    print STDERR $_[0];
    push @warned, $_[0]
  };


use Imager qw(:handy);

plan tests => 4;

#my $fontfile = 'ImUgly.ttf';
#my $font = Imager::Font->new(file=>$fontfile, type => 'ft2', aa=>1)
#  or plan skip_all => "Cannot create font object: ",Imager->errstr,"\n";
my $font = Imager::Font::Test->new();

my @data = (1 .. 1000);
my @labels = qw(alpha beta gamma delta epsilon phi gi);

my $line = Imager::Graph::Line->new();
ok($line, "creating line chart object");

$line->add_data_series(\@data);
$line->set_labels(\@labels);

my $img1 = $line->draw();
ok($img1, "drawing line chart");

$img1->write(file=>'testout/t30_points.ppm') or die "Can't save img1: ".$img1->errstr."\n";
cmpimg($img1, 'testimg/t30_points.png', 200_000);

unless (is(@warned, 0, "should be no warnings")) {
  diag($_) for @warned;
}
