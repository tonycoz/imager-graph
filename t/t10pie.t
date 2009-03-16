#!perl -w
use strict;
use Imager::Graph::Pie;
use lib 't/lib';
use Imager::Font::Test;
use Test::More;

-d 'testout' 
  or mkdir "testout", 0700 
  or die "Could not create output directory: $!";

++$|;

use Imager qw(:handy);

#my $fontfile = 'ImUgly.ttf';
#my $font = Imager::Font->new(file=>$fontfile, type => 'ft2', aa=>1)
#  or plan skip_all => "Cannot create font object: ",Imager->errstr,"\n";
my $font = Imager::Font::Test->new();

my @data = ( 100, 180, 80, 20, 2, 1, 0.5 );
my @labels = qw(alpha beta gamma delta epsilon phi gi);

plan tests => 34;

my $pie = Imager::Graph::Pie->new;
ok($pie, "creating pie chart object");

# this may change output quality too

print "# Imager version: $Imager::VERSION\n";
print "# Font type: ",ref $font,"\n";

my $img1 = $pie->draw(data=>\@data, labels=>\@labels, font=>$font, 
		      title=>{ text=>'Imager::Graph::Pie', size=>32 },
		      features=>{ outline=>1, labels=>1, pieblur=>0, },
                      outline=>{ line => '404040' },
		     );

ok($img1, "drawing first pie chart")
  or print "# ",$pie->error,"\n";
cmpimg($img1, "testimg/t10_pie1.png", 196880977);
$img1->write(file=>'testout/t10_pie1.ppm')
  or die "Cannot save pie1: ",$img1->errstr,"\n";

my $img2 = $pie->draw(data=>\@data,
		      labels=>\@labels,
		      font=>$font, 
		      title=>{ text=>'Imager::Graph::Pie', size=>36 },
		      features=>{ labelspconly=>1, _debugblur=>1,
                                  legend=>1 },
                      legend=>{ border=>'000000', fill=>'C0C0C0', },
                      fills=>[ qw(404040 606060 808080 A0A0A0 C0C0C0 E0E0E0) ],
		     );

ok($img2, "drawing second pie chart")
  or print "# ",$pie->error,"\n";
cmpimg($img2, "testimg/t10_pie2.png", 255956289);
$img2->write(file=>'testout/t10_pie2.ppm')
  or die "Cannot save pie2: ",$img2->errstr,"\n";

my $img3 = $pie->draw(data=>\@data, labels=>\@labels,
		      font=>$font, style=>'fount_lin', 
		      features=>[ 'legend', 'labelspconly', ],
		      legend=>{ valign=>'center' });
ok($img3, "third chart")
  or print "# ",$pie->error,"\n";
$img3->write(file=>'testout/t10_lin_fount.ppm')
  or die "Cannot save pie3: ",$img3->errstr,"\n";
cmpimg($img3, "testimg/t10_lin_fount.png", 180_000);

my $img4 = $pie->draw(data=>\@data, labels=>\@labels,
		      font=>$font, style=>'fount_rad', 
		      features=>[ 'legend', 'labelspc', ],
		      legend=>{ valign=>'bottom', 
				halign=>'left',
				border=>'000080' });
ok($img4, "fourth chart")
  or print "# ",$pie->error,"\n";
$img4->write(file=>'testout/t10_rad_fount.ppm')
  or die "Cannot save pie3: ",$img4->errstr,"\n";
cmpimg($img4, "testimg/t10_rad_fount.png", 120_000);

my $img5 = $pie->draw(data=>\@data, labels=>\@labels,
		      font=>$font, style=>'mono', 
		      features=>[ 'allcallouts', 'labelspc' ],
		      legend=>{ valign=>'bottom', 
				halign=>'right' });
ok($img5, "fifth chart")
  or print "# ",$pie->error,"\n";
$img5->write(file=>'testout/t10_mono.ppm')
  or die "Cannot save pie3: ",$img5->errstr,"\n";
cmpimg($img5, "testimg/t10_mono.png", 550_000);

my $img6 = $pie->draw(data=>\@data, labels=>\@labels,
		      font=>$font, style=>'fount_lin', 
		      features=>[ 'allcallouts', 'labelspc', 'legend' ],
		      legend=>
		      {
		       valign=>'top', 
		       halign=>'center',
		       orientation => 'horizontal',
		       fill => { solid => Imager::Color->new(0, 0, 0, 32) },
		       patchborder => undef,
		       #size => 30,
		      });
ok($img6, "sixth chart")
  or print "# ",$pie->error,"\n";
$img6->write(file=>'testout/t10_hlegend.ppm')
  or die "Cannot save pie6: ",$img5->errstr,"\n";
cmpimg($img6, "testimg/t10_hlegend.png", 550_000);

{
  # RT #34813
  # zero sized segments were drawn to cover the whole circle
  my @data = ( 10, 8, 5, 0.000 );
  my @labels = qw(alpha beta gamma);
  
  my $img = $pie->draw
    (
     data => \@data, 
     labels => \@labels, 
     font => $font,
     features => [ 'legend', 'labelspc', 'outline' ],
    );
  ok($img, "create graph with no 'others'");
  ok($img->write(file => 'testout/t10_noother.ppm'),
     "save it");
  cmpimg($img, 'testimg/t10_noother.png', 500_000);
}

{ # RT #535
  # no font parameter would crash
  my $im = $pie->draw
    (
     data => \@data,
     title => 'test',
    );
  ok(!$im, "should fail to produce titled graph with no font");
  like($pie->error, qr/title\.font/, "message should mention which font");

  $im = $pie->draw
    (
     labels => \@labels,
     data => \@data,
     features => [ 'legend' ],
    );
  ok(!$im, "should fail to produce legended graph with no font");
  like($pie->error, qr/legend\.font/, "message should mention which font");

  $im = $pie->draw
    ( 
     data => \@data,
     labels => \@labels,
     features => [ 'legend' ],
     legend => { orientation => "horizontal" },
    );
  ok(!$im, "should fail to produce horizontal legended graph with no font");
  like($pie->error, qr/legend\.font/, "message should mention which font");

  $im = $pie->draw
    (
     data => \@data,
     labels => \@labels,
    );
  ok(!$im, "should fail to produce labelled graph with no font");
  like($pie->error, qr/label\.font/, "message should mention which font");

  $im = $pie->draw
    (
     data => \@data,
     labels => \@labels,
     features => [ 'allcallouts' ],
     label => { font => $font },
    );
  ok(!$im, "should fail to produce callout labelled graph with no font");
  like($pie->error, qr/callout\.font/, "message should mention which font");

  # shouldn't need to set label font if doing all callouts
  $im = $pie->draw
    (
     data => \@data,
     labels => \@labels,
     features => [ 'allcallouts' ],
     callout => { font => $font },
    );
  ok($im, "should produce callout labelled graph with only callout font")
    or print "# ", $pie->error, "\n";

  # shouldn't need to set callout font if doing all labels
  $im = $pie->draw
    (
     data => [ 1, 1, 1 ],
     labels => [ qw/a b c/ ],
     label => { font => $font }
    );
  ok($im, "should produce label only graph with only label font");
}

{
  # draw with an empty data array is bad
  # problem reported and fixed by Patrick Michaud
  my $im = $pie->draw(data => []);
  ok(!$im, "fail to draw with empty data");
  like($pie->error, qr/No values/, "message appropriate");
}

{ # pie charts can't represent negative values
  # problem reported and fixed by Patrick Michaud
  my $im = $pie->draw(data => [ 10, -1, 10 ]);
  ok(!$im, "fail to draw with negative value");
  is($pie->error, "Data index 1 is less than zero", "check message");
}

{ # pie can't represent all zeros
  # problem reported and fixed by Patrick Michaud
  my $im = $pie->draw(data => [ 0, 0, 0 ]);
  ok(!$im, "fail to draw with all zero values");
  is($pie->error, "Sum of all data values is zero", "check message");
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
    cmp_ok($diff, '<', $limit, "Comparison to $file ($diff)");
  }
}
