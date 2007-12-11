package Imager::Graph::Pie;

=head1 NAME

  Imager::Graph::Pie - a tool for drawing pie charts on Imager images

=head1 SYNOPSIS

  use Imager::Graph::Pie;

  my $chart = Imager::Graph::Pie->new;
  # see Imager::Graph for options
  my $img = $chart->draw(labels=>['first segment', 'second segment'],
			 data=>[ $first_amount, $second_amount ],
			 size=>[$width, $height])

=head1 DESCRIPTION

Imager::Graph::Pie is intender to make it simple to use L<Imager> to
create good looking pie graphs.

Most of the basic layout and color selection is handed off to
L<Imager::Graph>.

=over

=cut

use strict;
use vars qw(@ISA);
use Imager::Graph;
@ISA = qw(Imager::Graph);
use Imager::Graph::Util;
use POSIX qw(floor);

use constant PI => 3.1415926535;

# Imager doesn't have a arc boundary function, and the obvious code
# either leaves gaps between the circle and the fill, or has some of the
# fill outside the outline.  These fudge factors produced good results
# for the test images <sigh>
use constant CIRCLE_FUDGE_X => 0.4;
use constant CIRCLE_FUDGE_Y => 0.4;
use constant CIRCLE_RADIUS_FUDGE => 0.2;

=item $graph->draw(...)

Draws a pie graph onto a new image and returns the image.

You must at least supply a C<data> parameter and should probably supply a C<labels> parameter.

The C<data> parameter should be a reference to an array containing the
data the pie graph should present.

The C<labels> parameter is a reference to an array of labels,
corresponding to the values in C<data>.

=back

=head1 FEATURES

As described in L<Imager::Graph> you can enable extra features for
your graph.  The features you can use with pie graphs are:

=over

=item legend

adds a legend to your graph.  Requires the labels parameter

=item labels

labels each segment of the graph.  If the label doesn't fit inside the
segment it is presented as a callout.

=item labelspc

adds the percentage of the pie to each label.

=item labelspconly

the segments are labels with their percentages only.

=item allcallouts

all labels are presented as callouts

=item pieblur

the segments are blurred, as a substitute for anti-aliased arcs

=item outline

the pie segments are outlined.

=item dropshadow

the pie is given a drop shadow.

=back

=head1 EXAMPLES

Assuming:

  # from the Netcraft September 2001 web survey
  # http://www.netcraft.com/survey/
  my @data   = qw(17874757  8146372   1321544  811406 );
  my @labels = qw(Apache    Microsoft iPlanet  Zeus   );

  my $pie = Imager::Graph::Pie->new;

First a simple graph, normal size, no labels:

  my $img = $pie->draw(data=>\@data)
    or die $pie->error;

label the segments:

  # error handling omitted for brevity from now on
  $img = $pie->draw(data=>\@data, labels=>\@labels, features=>'labels');

just percentages in the segments:

  $img = $pie->draw(data=>\@data, features=>'labelspconly');

add a legend as well:

  $img = $pie->draw(data=>\@data, labels=>\@labels,
                    features=>[ 'labelspconly', 'legend' ]);

and a title, but move the legend down, and add a dropshadow:

  $img = $pie->draw(data=>\@data, labels=>\@labels,
                    title=>'Netcraft Web Survey',
                    legend=>{ valign=>'bottom' },
                    features=>[ qw/labelspconly legend dropshadow/ ]);

something a bit prettier:

  # requires Imager > 0.38
  $img = $pie->draw(data=>\@data, labels=>\@labels,
                    style=>'fount_lin', features=>'legend');

suitable for monochrome output:

  # requires Imager > 0.38
  $img = $pie->draw(data=>\@data, labels=>\@labels,
                    style=>'mono', features=>'legend');

=cut

# this function is too long
sub draw {
  my ($self, %opts) = @_;

  $opts{data} 
    or return $self->_error("No data parameter supplied");
  my @data = @{$opts{data}};
  my @labels;
  @labels = @{$opts{labels}} if $opts{labels};

  $self->_style_setup(\%opts);

  my $style = $self->{_style};

  my $img = $self->_make_img()
    or return;

  my $total = 0;
  for my $item (@data) {
    $total += $item;
  }

  my @chart_box = ( 0, 0, $img->getwidth-1, $img->getheight-1 );
  if ($style->{title}{text}) {
    $self->_draw_title($img, \@chart_box)
      or return;
  }

  # consolidate any segments that are too small to display
  $self->_consolidate_segments(\@data, \@labels, $total);

  if ($style->{features}{legend} && $opts{labels}) {
    $self->_draw_legend($img, \@labels, \@chart_box)
      or return;
  }

  # the following code is fairly ugly
  # it attempts to work out a good layout for the components of the chart
  my @info;
  my $index = 0;
  my $pos = 0;
  my @ebox = (0, 0, 0, 0);
  defined(my $callout_outside = $self->_get_number('callout.outside'))
    or return;
  defined(my $callout_leadlen = $self->_get_number('callout.leadlen'))
    or return;
  defined(my $callout_gap = $self->_get_number('callout.gap'))
    or return;
  defined(my $label_vpad = $self->_get_number('label.vpad'))
    or return;
  defined(my $label_hpad = $self->_get_number('label.hpad'))
    or return;
  my $guessradius = 
    int($self->_small_extent(\@chart_box) * $style->{pie}{guessfactor} * 0.5);
  for my $data (@data) {
    my $item = { data=>$data, index=>$index };
    my $size = 2 * PI * $data / $total;
    $item->{begin} = $pos;
    $pos += $size;
    $item->{end} = $pos;
    if ($opts{labels}) {
      $item->{text} = $labels[$index];
    }
    if ($style->{features}{labelspconly}) {
      $item->{text} = 
        $style->{label}{pconlyformat}->($data/$total * 100);
    }
    if ($item->{text}) {
      if ($style->{features}{labelspc}) {
        $item->{text} = 
          $style->{label}{pcformat}->($item->{text}, $data/$total * 100);
        $item->{label} = 1;
      }
      elsif ($style->{features}{labelspconly}) {
        $item->{text} = 
          $style->{label}{pconlyformat}->($data/$total * 100);
        $item->{label} = 1;
      }
      elsif ($style->{features}{labels}) {
        $item->{label} = 1;
      }
      $item->{lbox} = [ $self->_text_bbox($item->{text}, 'label') ];
      if ($item->{label}) {
        unless ($self->_fit_text(0, 0, 'label', $item->{text}, $guessradius,
                                 $item->{begin}, $item->{end})) {
          $item->{callout} = 1;
        }
      }
      $item->{callout} = 1 if $style->{features}{allcallouts};
      if ($item->{callout}) {
        $item->{label} = 0;
	$item->{cbox} = [ $self->_text_bbox($item->{text}, 'callout') ];
	$item->{cangle} = ($item->{begin} + $item->{end}) / 2;
	my $dist = cos($item->{cangle}) * ($guessradius+
                                           $callout_outside);
	my $co_size = $callout_leadlen + $callout_gap + $item->{cbox}[2];
	if ($dist < 0) {
	  $dist -= $co_size - $guessradius;
	  $dist < $ebox[0] and $ebox[0] = $dist;
	}
	else {
	  $dist += $co_size - $guessradius;
	  $dist > $ebox[2] and $ebox[2] = $dist;
	}
      }
    }
    push(@info, $item);
    ++$index;
  }

  my $radius = 
    int($self->_small_extent(\@chart_box) * $style->{pie}{size} * 0.5);
  my $max_width = $chart_box[2] - $chart_box[0] + $ebox[0] - $ebox[2];
  if ($radius > $max_width / 2) {
    $radius = $max_width / 2;
  }
  $chart_box[0] -= $ebox[0];
  $chart_box[2] -= $ebox[2];
  my $cx = int(($chart_box[0] + $chart_box[2]) / 2);
  my $cy = int(($chart_box[1] + $chart_box[3]) / 2);
  if ($style->{features}{dropshadow}) {
    my @shadow_fill = $self->_get_fill('dropshadow.fill')
      or return;
    my $offx = $self->_get_number('dropshadow.offx')
      or return;
    my $offy = $self->_get_number('dropshadow.offy');
    for my $item (@info) {
      $img->arc(x=>$cx+$offx, 'y'=>$cy+$offy, r=>$radius+1,
                d1=>180/PI * $item->{begin}, d2=>180/PI * $item->{end},
                @shadow_fill);
    }
    $self->_filter_region($img, 
                          $cx+$offx-$radius-10, $cy+$offy-$radius-10, 
                          $cx+$offx+$radius+10, $cy+$offy+$radius+10,
                          'dropshadow.filter')
      if $style->{dropshadow}{filter};
  }
  my @fill_box = ( $cx-$radius, $cy-$radius, $cx+$radius, $cy+$radius );
  for my $item (@info) {
    my @fill = $self->_data_fill($item->{index}, \@fill_box)
      or return;
    $img->arc(x=>$cx, 'y'=>$cy, r=>$radius, 
              d1=>180/PI * $item->{begin}, d2=>180/PI * $item->{end},
              @fill);
  }
  if ($style->{features}{pieblur}) {
    $self->_pieblur($img, $cx, $cy, $radius);
  }
  if ($style->{features}{outline}) {
    my $outcolor = $self->_get_color('outline.line');
    for my $item (@info) {
      my $px = int($cx + CIRCLE_FUDGE_X + 
                   ($radius+CIRCLE_RADIUS_FUDGE) * cos($item->{begin}));
      my $py = int($cy + CIRCLE_FUDGE_Y + 
                   ($radius+CIRCLE_RADIUS_FUDGE) * sin($item->{begin}));
      $img->line(x1=>$cx, y1=>$cy, x2=>$px, y2=>$py, color=>$outcolor);
      for (my $i = $item->{begin}; $i < $item->{end}; $i += PI/180) {
	my $stroke_end = $i + PI/180;
	$stroke_end = $item->{end} if $stroke_end > $item->{end};
	my $nx = int($cx + CIRCLE_FUDGE_X + 
                     ($radius+CIRCLE_RADIUS_FUDGE) * cos($stroke_end));
	my $ny = int($cy + CIRCLE_FUDGE_Y + 
                     ($radius+CIRCLE_RADIUS_FUDGE) * sin($stroke_end));
	$img->line(x1=>$px, y1=>$py, x2=>$nx, y2=>$ny, color=>$outcolor,
		  antialias=>1);
	($px, $py) = ($nx, $ny);
      }
    }
  }

  my $callout_inside = $radius - $self->_get_number('callout.inside');
  $callout_outside += $radius;
  my %callout_text = $self->_text_style('callout');
  my %label_text = $self->_text_style('label');
  for my $label (@info) {
    if ($label->{label}) {
      my @loc = $self->_fit_text($cx, $cy, 'label', $label->{text}, $radius,
                                 $label->{begin}, $label->{end});
      if (@loc) {
        my $tcx = ($loc[0]+$loc[2])/2;
        my $tcy = ($loc[1]+$loc[3])/2;
        #$img->box(xmin=>$loc[0], ymin=>$loc[1], xmax=>$loc[2], ymax=>$loc[3],
        #          color=>Imager::Color->new(0,0,0));
        $img->string(%label_text, x=>$tcx-$label->{lbox}[2]/2,
                     'y'=>$tcy+$label->{lbox}[3]/2+$label->{lbox}[1],
                     text=>$label->{text});
      }
      else {
        $label->{callout} = 1;
        $label->{cbox} = [ $self->_text_bbox($label->{text}, 'callout') ]; 
        $label->{cangle} = ($label->{begin} + $label->{end}) / 2;
      }
    }
    if ($label->{callout}) {
      my $ix = floor(0.5 + $cx + $callout_inside * cos($label->{cangle}));
      my $iy = floor(0.5 + $cy + $callout_inside * sin($label->{cangle}));
      my $ox = floor(0.5 + $cx + $callout_outside * cos($label->{cangle}));
      my $oy = floor(0.5 + $cy + $callout_outside * sin($label->{cangle}));
      my $lx = ($ox < $cx) ? $ox - $callout_leadlen : $ox + $callout_leadlen;
      $img->line(x1=>$ix, y1=>$iy, x2=>$ox, y2=>$oy, antialias=>1,
		 color=>$self->_get_color('callout.color'));
      $img->line(x1=>$ox, y1=>$oy, x2=>$lx, y2=>$oy, antialias=>1,
		 color=>$self->_get_color('callout.color'));
      #my $tx = $lx + $callout_gap;
      my $ty = $oy + $label->{cbox}[3]/2+$label->{cbox}[1];
      if ($lx < $cx) {
	$img->string(%callout_text, x=>$lx-$callout_gap-$label->{cbox}[2], 
		     'y'=>$ty, text=>$label->{text});
      }
      else {
	$img->string(%callout_text, x=>$lx+$callout_gap, 'y'=>$ty, 
		     text=>$label->{text});
      }
    }
  }

  $img;
}

=head1 INTERNAL FUNCTIONS

These are used in the implementation of Imager::Graph, and are
documented for debuggers and developers.

=over

=item _consolidate_segments($data, $labels, $total)

Consolidate segments that are too small into an 'others' segment.

=cut

sub _consolidate_segments {
  my ($self, $data, $labels, $total) = @_;

  my @others;
  my $index;
  for my $item (@$data) {
    if ($item / $total < $self->{_style}{pie}{maxsegment}) {
      push(@others, $index);
    }
    ++$index;
  }
  if (@others) {
    my $others = 0;
    for my $index (reverse @others) {
      $others += $data->[$index];
      splice(@$labels, $index, 1);
      splice(@$data, $index, 1);
    }
    push(@$labels, $self->{_style}{otherlabel}) if @$labels;
    push(@$data, $others);
  }
}

=item _pieblur($img, $cx, $cy, $radius)

Blurs the pie as a substitute for anti-aliased segments.

=cut

sub _pieblur {
  my ($self, $img, $cx, $cy, $radius) = @_;

  my $left = $cx - $radius - 2;
  $left > 1 or $left = 2;
  my $right = $cx + $radius + 2;
  my $top = $cy - $radius - 2;
  $top > 1 or $top = 2;
  my $bottom = $cy + $radius + 2;

  my $filter = $self->_get_thing("pie.blur")
    or return;
  
  # newer versions of Imager let you work on just part of an image
  if ($img->can('masked') && !$self->{_style}{features}{_debugblur}) {
    # the mask prevents the blur from leaking over the edges
    my $mask = Imager->new(xsize=>$right-$left, ysize=>$bottom-$top, 
                           channels=>1);
    $mask->arc(x=>$cx-$left, 'y'=>$cy-$top, r=>$radius);
    my $masked = $img->masked(mask=>$mask,
                              left=>$left, top=>$top,
                              right=>$right, bottom=>$bottom);
    $masked->filter(%{$self->{_style}{pie}{blur}});
  }
  else {
    # for older versions of Imager
    my $subset = $img->crop(left=>$left, top=>$top,
                            right=>$right, bottom=>$bottom);
    $subset->filter(%{$self->{_style}{pie}{blur}});
    $img->paste(left=>$left, top=>$top, img=>$subset);
  }
}

# used for debugging
sub _test_line {
  my ($x, $y, @l) = @_;

  my $res = $l[0]*$x + $l[1] * $y + $l[2];
  print "test ", (abs($res) < 0.000001) ? "success\n" : "failure $res\n";
}

=item _fit_text($cx, $cy, $name, $text, $radius, $begin, $end)

Attempts to fit text into a pie segment with its center at ($cx, $cy)
with the given radius, covering the angles $begin through $end.

Returns a list defining the bounding box of the text if it does fit.

=cut

sub _fit_text {
  my ($self, $cx, $cy, $name, $text, $radius, $begin, $end) = @_;

  #print "fit: $cx, $cy '$text' $radius $begin $end\n";
  my @tbox = $self->_text_bbox($text, $name);
  my $tcx = floor(0.5+$cx + cos(($begin+$end)/2) * $radius *3/5);
  my $tcy = floor(0.5+$cy + sin(($begin+$end)/2) * $radius *3/5);
  my $topy = $tcy - $tbox[3]/2;
  my $boty = $topy + $tbox[3];
  my @lines;
  for my $y ($topy, $boty) {
    my %entry = ( 'y'=>$y );
    $entry{line} = [ line_from_points($tcx, $y, $tcx+1, $y) ];
    $entry{left} = -$radius;
    $entry{right} = $radius;
    for my $angle ($begin, $end) {
      my $ex = $cx + cos($angle)*$radius;
      my $ey = $cy + sin($angle)*$radius;
      my @line = line_from_points($cx, $cy, $ex, $ey);
      #_test_line($cx, $cy, @line);
      #_test_line($ex, $ey, @line);
      my $goodsign = $line[0] * $tcx + $line[1] * $tcy + $line[2];
      for my $pos (@entry{qw/left right/}) {
        my $sign = $line[0] * ($pos+$tcx) + $line[1] * $y + $line[2];
        if ($goodsign * $sign < 0) {
          if (my @p = intersect_lines(@line, @{$entry{line}})) {
            # die "$goodsign $sign ($pos, $tcx) no intersect (@line) (@{$entry{line}})"  ; # this would be wierd
            #_test_line(@p, @line);
            #_test_line(@p, @{$entry{line}});
            $pos = $p[0]-$tcx;
          }
          else {
            return;
          }
            
        }

        # circle
        my $dist2 = ($pos+$tcx-$cx) * ($pos+$tcx-$cx) 
          + ($y - $cy) * ($y - $cy);
        if ($dist2 > $radius * $radius) {
          my @points = 
            intersect_line_and_circle(@{$entry{line}}, $cx, $cy, $radius);
          while (@points) {
            my @p = splice(@points, 0, 2);
            if ($p[0] < $cx && $tcx+$pos < $p[0]) {
              $pos = $p[0]-$tcx;
            }
            elsif ($p[0] > $cx && $tcx+$pos > $p[0]) {
              $pos = $p[0]-$tcx;
            }
          }
        }
      }
    }
    push(@lines, \%entry);
  }
  my $left = $lines[0]{left} > $lines[1]{left} ? $lines[0]{left} : $lines[1]{left};
  my $right = $lines[0]{right} < $lines[1]{right} ? $lines[0]{right} : $lines[1]{right};
  return if $right - $left < $tbox[2];

  return ($tcx+$left, $topy, $tcx+$right, $boty);
}

sub _composite {
  ( 'pie', $_[0]->SUPER::_composite() );
}

sub _style_defs {
  my ($self) = @_;

  my %work = %{$self->SUPER::_style_defs()};
  $work{otherlabel} = "(others)";
  $work{features}{pieblur} = 1;
  $work{pie} = 
    {
     blur => { 
              type=>'conv',
              coef=>[0.05, 0.1, 0.3, 1, 0.3, 0.1, 0.05]
             },
     guessfactor=>0.6,
     size=>0.8,
     maxsegment=> 0.05,
    };

  \%work;
}

1;
__END__

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=head1 SEE ALSO

Imager::Graph(3), Imager(3), perl(1)

=cut
