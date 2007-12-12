#!perl -w
use strict;
use Imager::Graph::Pie;
use Test::More;

-d 'testout' 
  or mkdir "testout", 0700 
  or die "Could not create output directory: $!";

++$|;

my $testnum = 1;

use Imager qw(:handy);

my $fontfile = 'ImUgly.ttf';
my $font = Imager::Font->new(file=>$fontfile, type => 'ft2', aa=>1)
  or plan skip_all => "Cannot create font object: ",Imager->errstr,"\n";

my @data = ( 100, 180, 80, 20, 2, 1, 0.5 );
my @labels = qw(alpha beta gamma delta epsilon phi gi);

plan tests => 11;

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
                      legend=>{ border=>'000000', fill=>'FF8080', },
                      fills=>[ qw(404040 606060 808080 A0A0A0 C0C0C0 E0E0E0) ],
		     );

ok($img2, "drawing second pie chart")
  or print "# ",$pie->error,"\n";
cmpimg($img2, "testimg/t10_pie2.png", 255956289);
$img2->write(file=>'testout/t10_pie2.ppm')
  or die "Cannot save pie2: ",$img2->errstr,"\n";

my ($im_version) = $Imager::VERSION =~ /(\d\.[\d_]+)/;
{
  $im_version > 0.38
    or skip("very old Imager", 6);
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
