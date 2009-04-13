package Imager::Graph::StackedColumn;

=head1 NAME

  Imager::Graph::StackedColumn - a tool for drawing stacked column charts on Imager images

=head1 SYNOPSIS

  This subclass is still in green development.

=cut

use strict;
use vars qw(@ISA);
use Imager::Graph::Vertical;
@ISA = qw(Imager::Graph::Vertical);

sub _get_default_series_type {
  return 'stacked_column';
}

1;

