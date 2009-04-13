package Imager::Graph::Column;

=head1 NAME

  Imager::Graph::Column - a tool for drawing column charts on Imager images

=head1 SYNOPSIS

  This subclass is still in green development.

=cut

use strict;
use vars qw(@ISA);
use Imager::Graph::Vertical;
@ISA = qw(Imager::Graph::Vertical);

sub _get_default_series_type {
  return 'column';
}

1;

