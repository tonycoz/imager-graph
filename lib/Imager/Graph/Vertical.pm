package Imager::Graph::Vertical;

=head1 NAME

  Imager::Graph::Vertical- A super class for line/bar/column charts

=cut

use strict;
use vars qw(@ISA);
use Imager::Graph;
@ISA = qw(Imager::Graph);

=over 4

=item add_data_series(\@data, $series_name)

Add a data series to the graph, of the default type.

=cut

sub add_data_series {
  my $self = shift;
  my $data_ref = shift;
  my $series_name = shift;

  my $series_type = $self->_get_default_series_type();
  $self->_add_data_series($series_type, $data_ref, $series_name);

  return;
}

=item add_column_data_series(\@data, $series_name)

Add a column data series to the graph.

=cut

sub add_column_data_series {
  my $self = shift;
  my $data_ref = shift;
  my $series_name = shift;

  $self->_add_data_series('column', $data_ref, $series_name);

  return;
}

=item add_stacked_column_data_series(\@data, $series_name)

Add a stacked column data series to the graph.

=cut

sub add_stacked_column_data_series {
  my $self = shift;
  my $data_ref = shift;
  my $series_name = shift;

  $self->_add_data_series('stacked_column', $data_ref, $series_name);

  return;
}

=item add_line_data_series(\@data, $series_name)

Add a line data series to the graph.

=cut

sub add_line_data_series {
  my $self = shift;
  my $data_ref = shift;
  my $series_name = shift;

  $self->_add_data_series('line', $data_ref, $series_name);

  return;
}

=item set_range_padding($percentage)

Sets the padding to be used, as a percentage.  For example, if your data ranges from 0 to 10, and you have a 20 percent padding, the y axis will go to 12.

Defaults to 10.

=cut

sub set_range_padding {
  $_[0]->{'custom_style'}->{'range_padding'} = $_[1];
}

=item draw()

Draw the graph

=cut

sub draw {
  my ($self, %opts) = @_;

  if (!$self->_valid_input()) {
    return;
  }

  $self->_style_setup(\%opts);

  my $style = $self->{_style};

  my $img = $self->_get_image()
    or return;

  my @image_box = ( 0, 0, $img->getwidth-1, $img->getheight-1 );
  $self->_set_image_box(\@image_box);

  # Scale the graph box down to the widest graph that can cleanly hold the # of columns.
  $self->_get_data_range();
  my $column_count = $self->_get_column_count();

  my $width = $self->_get_number('width');
  my $height = $self->_get_number('height');
  my $size = $self->_get_number('size');

  my $bottom = ($height - $size) / 2;
  my $left   = ($width - $size) / 2;

  my $col_width = int($size / $column_count) -1;
  my $graph_width = $col_width * $column_count + 1;

  my @graph_box = ( $left, $bottom, $left + $graph_width - 1, $bottom + $size - 1 );
  $self->_set_graph_box(\@graph_box);

  $self->_draw_legend();

  $img->box(
            color   => $self->_get_color('outline.line'),
            xmin    => $left,
            xmax    => $left+$graph_width,
            ymin    => $bottom,
            ymax    => $bottom+$size,
            );

  $img->box(
            color   => $self->_get_color('bg'),
            xmin    => $left + 1,
            xmax    => $left+$graph_width - 1,
            ymin    => $bottom + 1,
            ymax    => $bottom+$size -1 ,
            filled  => 1,
            );

  my $min_value = $self->_get_min_value();
  my $max_value = $self->_get_max_value();
  my $value_range = $max_value - $min_value;

  my $zero_position;
  if ($value_range) {
    $zero_position =  $bottom + $size - (-1*$min_value / $value_range) * ($size -1);
  }

  if ($min_value < 0) {
    $img->box(
            color   => $self->_get_color('negative_bg'),
            xmin    => $left + 1,
            xmax    => $left+$graph_width- 1,
            ymin    => $zero_position,
            ymax    => $bottom+$size -1,
            filled  => 1,
    );
    $img->line(
            x1 => $left+1,
            y1 => $zero_position,
            x2 => $left + $graph_width,
            y2 => $zero_position,
            color => $self->_get_color('outline.line'),
    );
  }

  if ($self->_get_data_series()->{'stacked_column'}) {
    $self->_draw_stacked_columns();
  }
  if ($self->_get_data_series()->{'column'}) {
    $self->_draw_columns();
  }
  if ($self->_get_data_series()->{'line'}) {
    $self->_draw_lines();
  }
  return $self->_get_image();
}

sub _get_data_range {
  my $self = shift;

  my $max_value = 0;
  my $min_value = 0;
  my $column_count = 0;

  my ($sc_min, $sc_max, $sc_cols) = $self->_get_stacked_column_range();
  my ($c_min, $c_max, $c_cols) = $self->_get_column_range();
  my ($l_min, $l_max, $l_cols) = $self->_get_line_range();

  # These are side by side...
  $sc_cols += $c_cols;

  $min_value = $self->_min(0, $sc_min, $c_min, $l_min);
  $max_value = $self->_max(0, $sc_max, $c_max, $l_max);

  my $range_padding = $self->_get_number('range_padding');
  if (!defined $range_padding) {
    $range_padding = 10;
  }
  if ($range_padding && $min_value < 0) {
    my $difference = $min_value * $range_padding / 100;
    if ($min_value < -1 && $difference > -1) {
      $difference = -1;
    }
    $min_value += $difference;
  }
  if ($range_padding && $max_value > 0) {
    my $difference = $max_value * $range_padding / 100;
    if ($max_value > 1 && $difference < 1) {
      $difference = 1;
    }
    $max_value += $difference;
  }

  $column_count = $self->_max(0, $sc_cols, $l_cols);

  $self->_set_max_value($max_value);
  $self->_set_min_value($min_value);
  $self->_set_column_count($column_count);
}

sub _min {
  my $self = shift;
  my $min = shift;

  foreach my $value (@_) {
    if ($value < $min) { $min = $value; }
  }
  return $min;
}

sub _max {
  my $self = shift;
  my $min = shift;

  foreach my $value (@_) {
    if ($value > $min) { $min = $value; }
  }
  return $min;
}

sub _get_line_range {
  my $self = shift;
  my $series = $self->_get_data_series()->{'line'};
  return (0, 0, 0) unless $series;

  my $max_value = 0;
  my $min_value = 0;
  my $column_count = 0;

  my @series = @{$series};
  foreach my $series (@series) {
    my @data = @{$series->{'data'}};

    if (scalar @data > $column_count) {
      $column_count = scalar @data;
    }

    foreach my $value (@data) {
      if ($value > $max_value) { $max_value = $value; }
      if ($value < $min_value) { $min_value = $value; }
    }
  }

  return ($min_value, $max_value, $column_count);
}

sub _get_column_range {
  my $self = shift;

  my $series = $self->_get_data_series()->{'column'};
  return (0, 0, 0) unless $series;

  my $max_value = 0;
  my $min_value = 0;
  my $column_count = 0;

  my @series = @{$series};
  foreach my $series (@series) {
    my @data = @{$series->{'data'}};

    foreach my $value (@data) {
      $column_count++;
      if ($value > $max_value) { $max_value = $value; }
      if ($value < $min_value) { $min_value = $value; }
    }
  }

  return ($min_value, $max_value, $column_count);
}

sub _get_stacked_column_range {
  my $self = shift;

  my $max_value = 0;
  my $min_value = 0;
  my $column_count = 0;

  return (0, 0, 0) unless $self->_get_data_series()->{'stacked_column'};
  my @series = @{$self->_get_data_series()->{'stacked_column'}};

  my @max_entries;
  my @min_entries;
  for (my $i = scalar @series - 1; $i >= 0; $i--) {
    my $series = $series[$i];
    my $data = $series->{'data'};

    for (my $i = 0; $i < scalar @$data; $i++) {
      my $value = 0;
      if ($data->[$i] > 0) {
        $value = $data->[$i] + ($max_entries[$i] || 0);
        $data->[$i] = $value;
        $max_entries[$i] = $value;
      }
      elsif ($data->[$i] < 0) {
        $value = $data->[$i] + ($min_entries[$i] || 0);
        $data->[$i] = $value;
        $min_entries[$i] = $value;
      }
      if ($value > $max_value) { $max_value = $value; }
      if ($value < $min_value) { $min_value = $value; }
    }
    if (scalar @$data > $column_count) {
      $column_count = scalar @$data;
    }
  }

  return ($min_value, $max_value, $column_count);
}

sub _draw_legend {
  my $self = shift;
  my $style = $self->{'_style'};

  my @labels;
  my $img = $self->_get_image();
  if (my $series = $self->_get_data_series()->{'stacked_column'}) {
    push @labels, map { $_->{'series_name'} } @$series;
  }
  if (my $series = $self->_get_data_series()->{'column'}) {
    push @labels, map { $_->{'series_name'} } @$series;
  }
  if (my $series = $self->_get_data_series()->{'line'}) {
    push @labels, map { $_->{'series_name'} } @$series;
  }

  if ($style->{features}{legend} && (scalar @labels)) {
    $self->SUPER::_draw_legend($self->_get_image(), \@labels, $self->_get_image_box())
      or return;
  }
  return;
}

sub _draw_flat_legend {
  return 1;
}

sub _draw_lines {
  my $self = shift;
  my $style = $self->{'_style'};

  my $img = $self->_get_image();

  my $max_value = $self->_get_max_value();
  my $min_value = $self->_get_min_value();
  my $column_count = $self->_get_column_count();

  my $value_range = $max_value - $min_value;

  my $width = $self->_get_number('width');
  my $height = $self->_get_number('height');
  my $size = $self->_get_number('size');

  my $bottom = ($height - $size) / 2;
  my $left   = ($width - $size) / 2;

  my $zero_position =  $bottom + $size - (-1*$min_value / $value_range) * ($size -1);

  if ($self->_get_y_tics()) {
    $self->_draw_y_tics();
  }
  if ($self->_get_labels()) {
    $self->_draw_x_tics();
  }

  my $line_series = $self->_get_data_series()->{'line'};
  my $series_counter = $self->_get_series_counter() || 0;

  my $has_columns = (defined $self->_get_data_series()->{'column'} || $self->_get_data_series->{'stacked_column'}) ? 1 : 0;

  my $col_width = int($size / $column_count) -1;
  my $graph_width = $col_width * $column_count + 1;

  foreach my $series (@$line_series) {
    my @data = @{$series->{'data'}};
    my $data_size = scalar @data;

    my $interval;
    if ($has_columns) {
      $interval = $graph_width / ($data_size);
    }
    else {
      $interval = $graph_width / ($data_size - 1);
    }
    my @fill = $self->_data_fill($series_counter, $self->_get_graph_box());
    my $color = $self->_data_color($series_counter);
    for (my $i = 0; $i < $data_size - 1; $i++) {
      my $x1 = $left + $i * $interval;
      my $x2 = $left + ($i + 1) * $interval;

      $x1 += $has_columns * $interval / 2;
      $x2 += $has_columns * $interval / 2;

      my $y1 = $bottom + ($value_range - $data[$i] + $min_value)/$value_range * $size;
      my $y2 = $bottom + ($value_range - $data[$i + 1] + $min_value)/$value_range * $size;

      $img->line(x1 => $x1, y1 => $y1, x2 => $x2, y2 => $y2, aa => 1, color => $color) || die $img->errstr;
      $img->circle(x => $x1, y => $y1, r => 3, aa => 1, filled => 1, @fill);
    }

    my $x2 = $left + ($data_size - 1) * $interval;
    $x2 += $has_columns * $interval / 2;

    my $y2 = $bottom + ($value_range - $data[$data_size - 1] + $min_value)/$value_range * $size;

    $img->circle(x => $x2, y => $y2, r => 3, aa => 1, filled => 1, @fill);
    $series_counter++;
  }

  $self->_set_series_counter($series_counter);
  return;
}

sub _draw_columns {
  my $self = shift;
  my $style = $self->{'_style'};

  my $img = $self->_get_image();

  my $max_value = $self->_get_max_value();
  my $min_value = $self->_get_min_value();
  my $column_count = $self->_get_column_count();

  my $value_range = $max_value - $min_value;

  my $width = $self->_get_number('width');
  my $height = $self->_get_number('height');
  my $size = $self->_get_number('size');

  my $bottom = ($height - $size) / 2;
  my $left   = ($width - $size) / 2 + 1;

  my $zero_position =  int($bottom + $size - (-1*$min_value / $value_range) * ($size -1));

  if ($self->_get_y_tics()) {
    $self->_draw_y_tics();
  }
  if ($self->_get_labels()) {
    $self->_draw_x_tics();
  }

  my $bar_width = int(($size)/ $column_count - 2);

  my $outline_color;
  if ($style->{'features'}{'outline'}) {
    $outline_color = $self->_get_color('outline.line');
  }

  my $series_counter = $self->_get_series_counter() || 0;
  my $col_series = $self->_get_data_series()->{'column'};

  # This tracks the series we're in relative to the starting series - this way colors stay accurate, but the columns don't start out too far to the right.
  my $column_series = 0;

  # If there are stacked columns, non-stacked columns need to start one to the right of where they would otherwise
  my $has_stacked_columns = (defined $self->_get_data_series()->{'stacked_column'} ? 1 : 0);

  for (my $series_pos = 0; $series_pos < scalar @$col_series; $series_pos++) {
    my $series = $col_series->[$series_pos];
    my @data = @{$series->{'data'}};
    my $data_size = scalar @data;
    my $color = $self->_data_color($series_counter);
    for (my $i = 0; $i < $data_size; $i++) {
      my $x1 = int($left + $bar_width * (scalar @$col_series * $i + $series_pos)) + scalar @$col_series * $i + $series_pos;
      if ($has_stacked_columns) {
        $x1 += ($i + 1) * $bar_width + $i + 1;
      }
      my $x2 = $x1 + $bar_width;

      my $y1 = int($bottom + ($value_range - $data[$i] + $min_value)/$value_range * $size);

      my $color = $self->_data_color($series_counter);

    #  my @fill = $self->_data_fill($series_counter, [$x1, $y1, $x2, $zero_position]);
      if ($data[$i] > 0) {
        $img->box(xmin => $x1, xmax => $x2, ymin => $y1, ymax => $zero_position-1, color => $color, filled => 1);
        if ($style->{'features'}{'outline'}) {
          $img->box(xmin => $x1, xmax => $x2, ymin => $y1, ymax => $zero_position, color => $outline_color);
        }
      }
      else {
        $img->box(xmin => $x1, xmax => $x2, ymin => $zero_position+1, ymax => $y1, color => $color, filled => 1);
        if ($style->{'features'}{'outline'}) {
          $img->box(xmin => $x1, xmax => $x2, ymin => $zero_position+1, ymax => $y1+1, color => $outline_color);
        }
      }
    }

    $series_counter++;
    $column_series++;
  }
  $self->_set_series_counter($series_counter);
  return;
}

sub _draw_stacked_columns {
  my $self = shift;
  my $style = $self->{'_style'};

  my $img = $self->_get_image();

  my $max_value = $self->_get_max_value();
  my $min_value = $self->_get_min_value();
  my $column_count = $self->_get_column_count();
  my $value_range = $max_value - $min_value;

  my $graph_box = $self->_get_graph_box();
  my $left = $graph_box->[0] + 1;
  my $bottom = $graph_box->[1];
  my $size = $self->_get_number('size');

  if ($self->_get_y_tics()) {
    $self->_draw_y_tics();
  }
  if ($self->_get_labels()) {
    $self->_draw_x_tics();
  }

  my $bar_width = int($size / $column_count -2);
  my $column_series = 0;
  if (my $column_series_data = $self->_get_data_series()->{'column'}) {
    $column_series = (scalar @$column_series_data);
  }
  $column_series++;

  my $outline_color;
  if ($style->{'features'}{'outline'}) {
    $outline_color = $self->_get_color('outline.line');
  }

  my $zero_position =  $bottom + $size - (-1*$min_value / $value_range) * ($size -1);
  my $col_series = $self->_get_data_series()->{'stacked_column'};
  my $series_counter = $self->_get_series_counter() || 0;
  foreach my $series (@$col_series) {
    my @data = @{$series->{'data'}};
    my $data_size = scalar @data;
    my $color = $self->_data_color($series_counter);
    for (my $i = 0; $i < $data_size; $i++) {
      my $x1 = int($left + $bar_width * ($column_series * $i)) + $column_series * $i;
#      my $x1 = $left + $i * $size / ($data_size);
      my $x2 = $x1 + $bar_width;

      my $y1 = $bottom + ($value_range - $data[$i] + $min_value)/$value_range * $size;

      if ($data[$i] > 0) {
        $img->box(xmin => $x1, xmax => $x2, ymin => $y1, ymax => $zero_position-1, color => $color, filled => 1);
        if ($style->{'features'}{'outline'}) {
          $img->box(xmin => $x1, xmax => $x2, ymin => $y1, ymax => $zero_position, color => $outline_color);
        }
      }
      else {
        $img->box(xmin => $x1, xmax => $x2, ymin => $zero_position+1, ymax => $y1, color => $color, filled => 1);
        if ($style->{'features'}{'outline'}) {
          $img->box(xmin => $x1, xmax => $x2, ymin => $zero_position+1, ymax => $y1+1, color => $outline_color);
        }
      }
    }

    $series_counter++;
  }
  $self->_set_series_counter($series_counter);
  return;
}

sub _add_data_series {
  my $self = shift;
  my $series_type = shift;
  my $data_ref = shift;
  my $series_name = shift;

  my $graph_data = $self->{'graph_data'} || {};

  my $series = $graph_data->{$series_type} || [];

  push @$series, { data => $data_ref, series_name => $series_name };

  $graph_data->{$series_type} = $series;

  $self->{'graph_data'} = $graph_data;
  return;
}

=over

=item set_y_tics($count)

Set the number of Y tics to use.  Their value and position will be determined by the data range.

=cut

sub set_y_tics {
  $_[0]->{'y_tics'} = $_[1];
}

sub _get_y_tics {
  return $_[0]->{'y_tics'};
}

sub _draw_y_tics {
  my $self = shift;
  my $min = $self->_get_min_value();
  my $max = $self->_get_max_value();
  my $tic_count = $self->_get_y_tics();

  my $img = $self->_get_image();
  my $graph_box = $self->_get_graph_box();
  my $image_box = $self->_get_image_box();

  my $interval = ($max - $min) / ($tic_count - 1);

  my %text_info = $self->_text_style('legend')
    or return;

  my $tic_distance = ($graph_box->[3] - $graph_box->[1]) / ($tic_count - 1);
  for my $count (0 .. $tic_count - 1) {
    my $x1 = $graph_box->[0] - 5;
    my $x2 = $graph_box->[0] + 5;
    my $y1 = $graph_box->[3] - ($count * $tic_distance);

    my $value = sprintf("%.2f", ($count*$interval)+$min);
    if ($value < 0) {
        $y1++;
    }
    my @box = $self->_text_bbox($value, 'legend')
      or return;

    $img->line(x1 => $x1, x2 => $x2, y1 => $y1, y2 => $y1, aa => 1, color => '000000');

    my $width = $box[2];
    my $height = $box[3];

    $img->string(%text_info,
                 x    => ($x1 - $width - 3),
                 y    => ($y1 + ($height / 2)),
                 text => $value
                );
  }

}

sub _draw_x_tics {
  my $self = shift;

  my $img = $self->_get_image();
  my $graph_box = $self->_get_graph_box();
  my $image_box = $self->_get_image_box();

  my $labels = $self->_get_labels();

  my $tic_count = (scalar @$labels) - 1;

  my $has_columns = (defined $self->_get_data_series()->{'column'} || defined $self->_get_data_series()->{'stacked_column'});

  # If we have columns, we want the x-ticks to show up in the middle of the column, not on the left edge
  my $denominator = $tic_count;
  if ($has_columns) {
    $denominator ++;
  }
  my $tic_distance = ($graph_box->[2] - $graph_box->[0]) / ($denominator);
  my %text_info = $self->_text_style('legend')
    or return;

  for my $count (0 .. $tic_count) {
    my $label = $labels->[$count];
    my $x1 = $graph_box->[0] + ($tic_distance * $count);

    if ($has_columns) {
      $x1 += $tic_distance / 2;
    }
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

sub _valid_input {
  my $self = shift;

  if (!defined $self->_get_data_series() || !keys %{$self->_get_data_series()}) {
    return $self->_error("No data supplied");
  }

  my $data = $self->_get_data_series();
  if (defined $data->{'line'} && !scalar @{$data->{'line'}->[0]->{'data'}}) {
    return $self->_error("No values in data series");
  }
  if (defined $data->{'column'} && !scalar @{$data->{'column'}->[0]->{'data'}}) {
    return $self->_error("No values in data series");
  }
  if (defined $data->{'stacked_column'} && !scalar @{$data->{'stacked_column'}->[0]->{'data'}}) {
    return $self->_error("No values in data series");
  }

  return 1;
}

sub _set_column_count   { $_[0]->{'column_count'} = $_[1]; }
sub _set_min_value      { $_[0]->{'min_value'} = $_[1]; }
sub _set_max_value      { $_[0]->{'max_value'} = $_[1]; }
sub _set_image_box      { $_[0]->{'image_box'} = $_[1]; }
sub _set_graph_box      { $_[0]->{'graph_box'} = $_[1]; }
sub _set_series_counter { $_[0]->{'series_counter'} = $_[1]; }
sub _get_column_count   { return $_[0]->{'column_count'} }
sub _get_min_value      { return $_[0]->{'min_value'} }
sub _get_max_value      { return $_[0]->{'max_value'} }
sub _get_image_box      { return $_[0]->{'image_box'} }
sub _get_graph_box      { return $_[0]->{'graph_box'} }
sub _get_series_counter { return $_[0]->{'series_counter'} }



1;
