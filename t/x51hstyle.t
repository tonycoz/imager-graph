#!perl -w
use strict;
use Imager::Graph::Bar;
use lib 't/lib';
use Imager::Font::Test;
use Test::More;
use Imager::Test qw(is_image_similar is_image);

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
my @labels = qw(alpha beta gamma delta epsilon phi gi);

plan tests => 22;

# this may change output quality too
print "# Imager version: $Imager::VERSION\n";
print "# Font type: ",ref $font,"\n";

{
  my $colm = Imager::Graph::Bar->new;
  ok($colm, "creating chart object");
  $colm->set_x_tics(10);

  $colm->add_data_series(\@data1, "Test Bar");

  my $img1;
  { # default outline of chart area
    $img1 = $colm->draw
      (
       labels => \@labels,
       font => $font, 
       title => "Test",
      )
	or print "# ", $colm->error, "\n";

    ok($img1, "made the image");

    ok($img1->write(file => "testout/x51col_def.ppm"),
       "save to testout");

    cmpimg($img1, "xtestimg/x51col_def.png", 80_000);
  }

  { # no outline
    my $img2 = $colm->draw
      (
       labels => \@labels,
       font => $font, 
       title => "Test",
       features => [ qw/nograph_outline/ ],
      )
	or print "# ", $colm->error, "\n";

    isnt($img1, $img2, "make sure they're different images");

    ok($img2, "made the image");

    ok($img2->write(file => "testout/x51col_noout.ppm"),
       "save to testout");

    cmpimg($img2, "xtestimg/x51col_noout.png", 80_000);
  }

  {
    # check no state remembered from nograph_outline
    my $img5 = $colm->draw
      (
       labels => \@labels,
       font => $font, 
       title => "Test",
      )
	or print "# ", $colm->error, "\n";
    ok($img5, "make with border again to check no state held");
    is_image($img1, $img5, "check no state held");
  }

  { # styled outline
    my $img6 = $colm->draw
      (
       labels => \@labels,
       font => $font,
       title => "Test styled outline",
       graph =>
       {
	outline =>
	{
	 color => "#fff",
	 style => "dashed",
	},
       },
      );
    ok($img6, "make chart with dashed outline of graph area");
    ok($img6->write(file => "testout/x51col_dashout.ppm"),
       "save it");
    cmpimg($img6, "xtestimg/x51col_dashout.png", 80_000);
  }

  { # no outline, styled fill
    my $img7 = $colm->draw
      (
       labels => \@labels,
       font => $font,
       title => "Test styled outline",
       features => "nograph_outline",
       graph =>
       {
	fill => { solid => "ffffff80" },
       },
      )
	or print "# ", $colm->error, "\n";
    ok($img7, "made the image");
    ok($img7->write(file => "testout/x51col_fill.ppm"),
       "save it");
    cmpimg($img7, "xtestimg/x51col_fill.png", 120_000);
  }

  { # gridlines
    my $img8 = $colm->draw
      (
       labels => \@labels,
       font => $font,
       title => "gridlines",
       features => "vertical_gridlines",
       vgrid => { style => "dashed", color => "#A0A0A0" },
      )
	or print "# ", $colm->error, "\n";
    ok($img8, "made the gridline image");
    ok($img8->write(file => "testout/x51col_grid.ppm"),
       "save it");
    cmpimg($img8, "xtestimg/x51col_grid.png", 80_000);
  }

  { # gridlines (set by method)
    my $colm2 = Imager::Graph::Bar->new;
    $colm2->show_vertical_gridlines();
    $colm2->set_vertical_gridline_style(style => "dashed", color => "#A0A0A0");
    $colm2->set_labels(\@labels);
    $colm2->set_title("gridlines");
    $colm2->add_data_series(\@data1, "Test Bar");
    $colm2->set_x_tics(10);
    $colm2->set_font($font);

    my $img9 = $colm2->draw
      (
       #labels => \@labels,
       #font => $font,
       #title => "gridlines",
       #features => "vertical_gridlines",
       #vgrid => { style => "dashed", color => "#A0A0A0" },
      )
	or print "# ", $colm2->error, "\n";
    ok($img9, "made the gridline image (set by methods)");
    ok($img9->write(file => "testout/x51col_gridm.ppm"),
       "save it");
    cmpimg($img9, "xtestimg/x51col_grid.png", 80_000);
  }
}

END {
  unless ($ENV{IMAGER_GRAPH_KEEP_FILES}) {
    unlink "testout/x51col_def.ppm";
    unlink "testout/x51col_noout.ppm";
    unlink "testout/x51col_dashout.ppm";
    unlink "testout/x51col_fill.ppm";
    unlink "testout/x51col_grid.ppm";
    unlink "testout/x51col_gridm.ppm";
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
