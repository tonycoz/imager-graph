package Imager::Graph::Line;

=head1 NAME

  Imager::Graph::Line - a tool for drawing line charts on Imager images

=head1 SYNOPSIS

  This subclass is still in green development.

=cut

use strict;
use vars qw(@ISA);
use Imager::Graph::Vertical;
@ISA = qw(Imager::Graph::Vertical);

sub _get_default_series_type {
    return 'line';
}

1;

