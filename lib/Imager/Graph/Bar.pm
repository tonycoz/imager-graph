package Imager::Graph::Bar;

=head1 NAME

  Imager::Graph::Bar - a tool for drawing bar charts on Imager images

=head1 SYNOPSIS

  This subclass is still in green development.

=cut

use strict;
use vars qw(@ISA);
use Imager::Graph::Horizontal;
@ISA = qw(Imager::Graph::Horizontal);

sub _get_default_series_type {
  return 'bar';
}

1;

