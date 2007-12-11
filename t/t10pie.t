#!perl -w
use strict;
use Imager::Graph::Pie;

-d 'testout' 
  or mkdir "testout", 0700 
  or die "Could not create output directory: $!";

++$|;
print "1..11\n";

my $testnum = 1;

use Imager qw(:handy);

# setting this to another font file will cause failed tests
# but may produce nicer text
my $fontfile; # = '/mnt/c/windows/fonts/arial.ttf';

my @data = ( 100, 180, 80, 20, 2, 1, 0.5 );
my @labels = qw(alpha beta gamma delta epsilon phi gi);

my $pie = Imager::Graph::Pie->new;
ok($pie, "creating pie chart object");

# this may change output quality too
#Imager::Font->priorities('ft2');
$fontfile = 'ImUgly.ttf' unless $fontfile and -e $fontfile;
my $font = Imager::Font->new(file=>$fontfile, aa=>1)
  or die "Cannot create font object: ",Imager->errstr,"\n";

print "# Imager version: $Imager::VERSION\n";
print "# Font type: ",ref $font,"\n";

my $img1 = $pie->draw(data=>\@data, labels=>\@labels, font=>$font, 
		      title=>{ text=>'Imager::Graph::Pie', size=>32 },
		      features=>{ outline=>1, labels=>1, pieblur=>0, },
                      outline=>{ line => '404040' },
		     )
  or print "# ",$pie->error,"\n";

ok($img1, "drawing first pie chart");
cmpimg($img1, "testimg/t10_pie1.png", 196880977);
unlink('testout/t10_pie1.png');
$img1->write(file=>'testout/t10_pie1.png')
  or die "Cannot save pie1: ",$img1->errstr,"\n";

my $img2 = $pie->draw(data=>\@data,
		      labels=>\@labels,
		      font=>$font, 
		      title=>{ text=>'Imager::Graph::Pie', size=>36 },
		      features=>{ labelspconly=>1, _debugblur=>1,
                                  legend=>1 },
                      legend=>{ border=>'000000', fill=>'FF8080', },
                      fills=>[ qw(404040 606060 808080 A0A0A0 C0C0C0 E0E0E0) ],
		     )
  or print "# ",$pie->error,"\n";

ok($img2, "drawing second pie chart");
cmpimg($img2, "testimg/t10_pie2.png", 255956289);
unlink('testout/t10_pie2.png');
$img2->write(file=>'testout/t10_pie2.png')
  or die "Cannot save pie2: ",$img2->errstr,"\n";

my ($im_version) = $Imager::VERSION =~ /(\d\.[\d_]+)/;
if ($im_version > 0.38) {
  my $img3 = $pie->draw(data=>\@data, labels=>\@labels,
                        font=>$font, style=>'fount_lin', 
                        features=>[ 'legend', 'labelspconly', ],
                        legend=>{ valign=>'center' });
  ok($img3, "third chart");
  $img3->write(file=>'testout/t10_lin_fount.png')
    or die "Cannot save pie3: ",$img3->errstr,"\n";
  cmpimg($img3, "testimg/t10_lin_fount.png", 180_000);

  my $img4 = $pie->draw(data=>\@data, labels=>\@labels,
                        font=>$font, style=>'fount_rad', 
                        features=>[ 'legend', 'labelspc', ],
                        legend=>{ valign=>'bottom', 
                                  halign=>'left',
                                  border=>'000080' });
  ok($img4, "fourth chart");
  $img4->write(file=>'testout/t10_rad_fount.png')
    or die "Cannot save pie3: ",$img4->errstr,"\n";
  cmpimg($img4, "testimg/t10_rad_fount.png", 120_000);

  my $img5 = $pie->draw(data=>\@data, labels=>\@labels,
                        font=>$font, style=>'mono', 
                        features=>[ 'allcallouts', 'labelspc' ],
                        legend=>{ valign=>'bottom', 
                                  halign=>'right' });
  ok($img5, "fifth chart");
  $img5->write(file=>'testout/t10_mono.png')
    or die "Cannot save pie3: ",$img5->errstr,"\n";
  cmpimg($img5, "testimg/t10_mono.png", 550_000);
}
else {
  skip("Imager not new enough", 6);
}

sub ok {
  my ($test, $comment) = @_;

  if ($test) {
    print "ok ",$testnum++," # $comment\n";
  }
  else {
    print "not ok ",$testnum++," # $comment\n";
  }
}

sub skip {
  my ($comment, $count) = @_;

  $count ||= 1;
  for (1..$count) {
    print "ok ",$testnum++," # skipped $comment\n";
  }
}

sub cmpimg {
  my ($img, $file, $limit) = @_;

  $limit ||= 10000;

  if ($Imager::formats{png}) {
    my $cmpimg = Imager->new;
    $cmpimg->read(file=>$file)
      or return ok(0, "Cannot read $file: ".$cmpimg->errstr);
    my $diff = Imager::i_img_diff($img->{IMG}, $cmpimg->{IMG});
    ok($diff < $limit, "Comparison to $file ($diff)");
  }
  else {
    skip("no png support");
  }
}
