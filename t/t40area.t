#!perl -w
use strict;
use Imager::Graph::Area;
use lib 't/lib';
use Imager::Font::Test;
use Test::More;
use Imager::Test qw(is_image_similar);

-d 'testout' 
  or mkdir "testout", 0700 
  or die "Could not create output directory: $!";

++$|;

use Imager qw(:handy);

#my $fontfile = 'ImUgly.ttf';
#my $font = Imager::Font->new(file=>$fontfile, type => 'ft2', aa=>1)
#  or plan skip_all => "Cannot create font object: ",Imager->errstr,"\n";
my $font = Imager::Font::Test->new();

my @data1 =
  (
    100, 180, 80, 20, 2, 1, 0.5 ,
  );
my @data2 =
  (
   10, 20, 40, 200, 150, 10, 50,
  );
my @labels = qw(alpha beta gamma delta epsilon phi gi);

plan tests => 4;

my $area = Imager::Graph::Area->new;
ok($area, "creating area chart object");

# this may change output quality too

print "# Imager version: $Imager::VERSION\n";
print "# Font type: ",ref $font,"\n";

$area->add_data_series(\@data1, "Test Area");
$area->add_data_series(\@data2, "Test Area 2");

my $img1 = $area->draw
  (
   #data => \@data,
   labels => \@labels,
   font => $font, 
   title => "Test",
   features => { legend => 1 },
   legend =>
   { 
    valign => "bottom",
    halign => "center",
    orientation => "horizontal",
   },
   area =>
   {
    opacity => 0.8,
   },
   #outline => { line => '404040' },
  )
  or print "# ", $area->error, "\n";

ok($img1, "made the image");

ok($img1->write(file => "testout/t40area1.ppm"),
   "save to testout");

cmpimg($img1, "testimg/t40area1.png");

END {
  unless ($ENV{IMAGER_GRAPH_KEEP_FILES}) {
    unlink "testout/t40area1.ppm";
  }
}

sub cmpimg {
  my ($img, $file, $limit) = @_;

  $limit ||= 10000;

 SKIP:
  {
    $Imager::formats{png}
      or skip("No PNG support", 1);

    my $cmpimg = Imager->new;
    $cmpimg->read(file=>$file)
      or return ok(0, "Cannot read $file: ".$cmpimg->errstr);
    my $diff = Imager::i_img_diff($img->{IMG}, $cmpimg->{IMG});
    is_image_similar($img, $cmpimg, $limit, "Comparison to $file ($diff)");
  }
}
