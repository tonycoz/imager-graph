package Imager::Graph::Line;

=head1 NAME

  Imager::Graph::Line - a tool for drawing line charts on Imager images

=head1 SYNOPSIS

  This subclass is still in green development.

=cut

use strict;
use vars qw(@ISA);
use Imager::Graph;
@ISA = qw(Imager::Graph);

=item setYTics($count)

Set the number of Y tics to use.  Their value and position will be determined by the data range.

=cut

sub setYTics {
  $_[0]->{'y_tics'} = $_[1];
}

sub _getYTics {
  return $_[0]->{'y_tics'};
}

sub draw {
  my ($self, %opts) = @_;

  $self->_processOptions(\%opts);

  if (!$self->_validInput()) {
    return;
  }

  $self->_style_setup(\%opts);

  my $style = $self->{_style};

  my $img = $self->_make_img()
    or return;

  my @chart_box = ( 0, 0, $img->getwidth-1, $img->getheight-1 );

  my @labels = map { $_->{'series_name'} } @{$self->_getDataSeries()};
  if ($style->{features}{legend} && (scalar @labels)) {
    $self->_draw_legend($img, \@labels, \@chart_box)
      or return;
  }

  my @series = @{$self->_getDataSeries()};
  my $max_value = 0;
  my $min_value = 0;

  foreach my $series (@series) {
    my @data = @{$series->{'data'}};

    foreach my $value (@data) {
      if ($value > $max_value) { $max_value = $value; }
      if ($value < $min_value) { $min_value = $value; }
    }
  }

  my $value_range = $max_value - $min_value;

  my $width = $self->_get_number('width');
  my $height = $self->_get_number('height');
  my $size = $self->_get_number('size');

  my $bottom = ($height - $size) / 2;
  my $left   = ($width - $size) / 2;

  my @graph_box = ( $left, $bottom, $left + $size - 1, $bottom + $size - 1 );

  $img->box(
            color   => '000000',
            xmin    => $left,
            xmax    => $left+$size,
            ymin    => $bottom,
            ymax    => $bottom+$size,
            );

  $img->box(
            color   => 'FFFFFF',
            xmin    => $left + 1,
            xmax    => $left+$size - 1,
            ymin    => $bottom + 1,
            ymax    => $bottom+$size -1 ,
            filled  => 1,
            );

  if ($min_value < 0) {
    $img->box(
            color   => 'EEEEEE',
            xmin    => $left + 1,
            xmax    => $left+$size - 1,
            ymin    => $bottom + $size - (-1*$min_value / $value_range) * ($size -1),
            ymax    => $bottom+$size -1,
            filled  => 1,
    );
  }

  if ($self->_getYTics()) {
    $self->_drawYTics($img, $min_value, $max_value, $self->_getYTics(), \@graph_box, \@chart_box);
  }
  if ($self->_getLabels()) {
    $self->_drawXTics($img, \@graph_box, \@chart_box);
  }

  my $series_counter = 0;
  foreach my $series (@series) {
    my @data = @{$series->{'data'}};
    my $data_size = scalar @data;
    my @fill = $self->_data_fill($series_counter, \@graph_box);
    my $color = $self->_data_color($series_counter);
    for (my $i = 0; $i < $data_size - 1; $i++) {
      my $x1 = $left + $i * $size / ($data_size - 1);
      my $x2 = $left + ($i + 1) * $size / ($data_size - 1);

      my $y1 = $bottom + ($value_range - $data[$i] + $min_value)/$value_range * $size;
      my $y2 = $bottom + ($value_range - $data[$i + 1] + $min_value)/$value_range * $size;

      $img->line(x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, aa => 1, color => $color) || die $img->errstr;
      $img->circle(x => $x1, y => $y1, r => 3, aa => 1, filled => 1, @fill);
    }

    my $x2 = $left + ($data_size - 1) * $size / ($data_size - 1);
    my $y2 = $bottom + ($value_range - $data[$data_size - 1] + $min_value)/$value_range * $size;

    $img->circle(x => $x2, y => $y2, r => 3, aa => 1, filled => 1, @fill);
    $series_counter++;
  }

  return $img;
}

sub _drawYTics {
  my $self = shift;
  my $img = shift;
  my $min = shift;
  my $max = shift;
  my $tic_count = shift;
  my $graph_box = shift;
  my $image_box = shift;

  my $interval = ($max - $min) / ($tic_count - 1);

  my %text_info = $self->_text_style('legend')
    or return;

  my $tic_distance = ($graph_box->[3] - $graph_box->[1]) / ($tic_count - 1);
  for my $count (0 .. $tic_count - 1) {
    my $x1 = $graph_box->[0] - 5;
    my $x2 = $graph_box->[0] + 5;
    my $y1 = $graph_box->[3] - ($count * $tic_distance);

    $img->line(x1 => $x1, x2 => $x2, y1 => $y1, y2 => $y1, aa => 1, color => '000000');

    my $value = sprintf("%.2f", ($count*$interval)+$min);

    my @box = $self->_text_bbox($value, 'legend')
      or return;

    my $width = $box[2];
    my $height = $box[3];

    $img->string(%text_info,
                 x    => ($x1 - $width - 3),
                 y    => ($y1 + ($height / 2)),
                 text => $value
                );
  }

}

sub _drawXTics {
  my $self = shift;
  my $img = shift;
  my $graph_box = shift;
  my $image_box = shift;

  my $labels = $self->_getLabels();

  my $tic_count = (scalar @$labels) - 1;

  my $tic_distance = ($graph_box->[2] - $graph_box->[0]) / ($tic_count);
  my %text_info = $self->_text_style('legend')
    or return;

  for my $count (0 .. $tic_count) {
    my $label = $labels->[$count];
    my $x1 = $graph_box->[0] + ($tic_distance * $count);
    my $y1 = $graph_box->[3] + 5;
    my $y2 = $graph_box->[3] - 5;

    $img->line(x1 => $x1, x2 => $x1, y1 => $y1, y2 => $y2, aa => 1, color => '000000');

    my @box = $self->_text_bbox($label, 'legend')
      or return;

    my $width = $box[2];
    my $height = $box[3];

    $img->string(%text_info,
                 x    => ($x1 - ($width / 2)),
                 y    => ($y1 + ($height + 5)),
                 text => $label
                );

  }
}

sub _validInput {
  my $self = shift;

  if (!defined $self->_getDataSeries() || !scalar @{$self->_getDataSeries()}) {
    return $self->_error("No data supplied");
  }

  if (!scalar @{$self->_getDataSeries()->[0]->{'data'}}) {
    return $self->_error("No values in data series");
  }

  my @data = @{$self->_getDataSeries()->[0]->{'data'}};

  return 1;
}



1;

