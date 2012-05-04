#!perl -w
use strict;
use Imager::Graph::Line;
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

plan tests => 29;

# this may change output quality too
print "# Imager version: $Imager::VERSION\n";
print "# Font type: ",ref $font,"\n";

{
  my $vert = Imager::Graph::Vertical->new;
  ok($vert, "creating chart object");
  $vert->set_y_tics(10);

  $vert->add_line_data_series(\@data1, "Test Line");

  my $img1;
  { # default outline of chart area
    $img1 = $vert->draw
      (
       labels => \@labels,
       font => $font, 
       title => "Test",
      )
	or print "# ", $vert->error, "\n";

    ok($img1, "made the image");

    ok($img1->write(file => "testout/x50line_def.ppm"),
       "save to testout");

    cmpimg($img1, "xtestimg/x50line_def.png", 60_000);
  }

  { # no outline
    my $img2 = $vert->draw
      (
       labels => \@labels,
       font => $font, 
       title => "Test",
       features => [ qw/nograph_outline/ ],
      )
	or print "# ", $vert->error, "\n";

    isnt($img1, $img2, "make sure they're different images");

    ok($img2, "made the image");

    ok($img2->write(file => "testout/x50line_noout.ppm"),
       "save to testout");

    cmpimg($img2, "xtestimg/x50line_noout.png", 60_000);

    my $img3 = $vert->draw
      (
       labels => \@labels,
       font => $font, 
       title => "Test",
       features => "nograph_outline",
      )
	or print "# ", $vert->error, "\n";
    ok($img3, "made with scalar features");
    is_image($img3, $img2, "check that both feature mechanisms act the same");

    my $img4 = $vert->draw
      (
       labels => \@labels,
       font => $font, 
       title => "Test",
       features => { "graph_outline" => 0 },
      )
	or print "# ", $vert->error, "\n";
    ok($img4, "made with hashref features");
    is_image($img4, $img2, "check that all feature mechanisms act the same");
  }

  {
    # check no state remembered from nograph_outline
    my $img5 = $vert->draw
      (
       labels => \@labels,
       font => $font, 
       title => "Test",
      )
	or print "# ", $vert->error, "\n";
    ok($img5, "make with border again to check no state held");
    is_image($img1, $img5, "check no state held");
  }

  { # styled outline
    my $img6 = $vert->draw
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
    ok($img6->write(file => "testout/x50line_dashout.ppm"),
       "save it");
    cmpimg($img6, "xtestimg/x50line_dashout.png", 80_000);
  }

  { # no outline, styled fill
    my $img7 = $vert->draw
      (
       labels => \@labels,
       font => $font,
       title => "Test styled outline",
       features => "nograph_outline",
       graph =>
       {
	fill => { solid => "ffffffC0" },
       },
      )
	or print "# ", $vert->error, "\n";
    ok($img7, "made the image");
    ok($img7->write(file => "testout/x50line_fill.ppm"),
       "save it");
    cmpimg($img7, "xtestimg/x50line_fill.png", 80_000);
  }

  { # gridlines
    my $img8 = $vert->draw
      (
       labels => \@labels,
       font => $font,
       title => "gridlines",
       features => "horizontal_gridlines",
       hgrid => { style => "dashed", color => "#A0A0A0" },
      )
	or print "# ", $vert->error, "\n";
    ok($img8, "made the gridline image");
    ok($img8->write(file => "testout/x50line_grid.ppm"),
       "save it");
    cmpimg($img8, "xtestimg/x50line_grid.png", 60_000);

    # default horizontal gridlines
    my $imgb = $vert->draw
      (
       labels => \@labels,
       font => $font,
       title => "gridlines",
       features => "horizontal_gridlines",
      )
	or print "# ", $vert->error, "\n";
    ok($imgb, "made the gridline image");
    ok($imgb->write(file => "testout/x50line_griddef.ppm"),
       "save it");
    cmpimg($imgb, "xtestimg/x50line_griddef.png", 60_000);

  }

  { # gridlines (set by method)
    my $vert2 = Imager::Graph::Vertical->new;
    $vert2->show_horizontal_gridlines();
    $vert2->set_horizontal_gridline_style(style => "dashed", color => "#A0A0A0");
    $vert2->set_labels(\@labels);
    $vert2->set_title("gridlines");
    $vert2->add_line_data_series(\@data1, "Test Line");
    $vert2->set_y_tics(10);
    $vert2->set_font($font);

    my $img9 = $vert2->draw
      (
       #labels => \@labels,
       #font => $font,
       #title => "gridlines",
       #features => "horizontal_gridlines",
       #hgrid => { style => "dashed", color => "#A0A0A0" },
      )
	or print "# ", $vert2->error, "\n";
    ok($img9, "made the gridline image (set by methods)");
    ok($img9->write(file => "testout/x50line_gridm.ppm"),
       "save it");
    cmpimg($img9, "xtestimg/x50line_grid.png", 60_000);
  }
}

END {
  unless ($ENV{IMAGER_GRAPH_KEEP_FILES}) {
    unlink "testout/x50line_def.ppm";
    unlink "testout/x50line_noout.ppm";
    unlink "testout/x50line_dashout.ppm";
    unlink "testout/x50line_fill.ppm";
    unlink "testout/x50line_grid.ppm";
    unlink "testout/x50line_griddef.ppm";
    unlink "testout/x50line_gridm.ppm";
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
