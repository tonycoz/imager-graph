package Imager::Graph;
require 5.005;

=head1 NAME

Imager::Graph - Perl extension for producing Graphs using the Imager library.

=head1 SYNOPSIS

  use Imager::Graph::Sub_class;
  my $chart = Imager::Graph::Sub_class->new;
  my $img = $chart->draw(data=> \@data, ...)
    or die $chart->error;

=head1 DESCRIPTION

Imager::Graph provides style information to its base classes.  It
defines the colors, text display information and fills based on both
built-in styles and modifications supplied by the user to the draw()
method.

=over

=cut

use strict;
use vars qw($VERSION);
use Imager qw(:handy);
use Imager::Fountain;

$VERSION = '0.06';

# the maximum recursion depth in determining a color, fill or number
use constant MAX_DEPTH => 10;

my $NUM_RE = '(?:[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]\d+?)?)';

=item new

This is a simple constructor.  No parameters required.

=cut

sub new {
  bless {}, $_[0];
}

=item set_graph_size($size)

Sets the size of the graph (in pixels) within the image.  The size of the image defaults to 1.5 * $graph_size.

=cut

sub set_graph_size {
  $_[0]->{'custom_style'}->{'size'} = $_[1];
}

=item set_image_width($width)

Sets the width of the image in pixels.

=cut

sub set_image_width {
  $_[0]->{'custom_style'}->{'width'} = $_[1];
}

=item set_image_height($height)

Sets the height of the image in pixels.

=cut

sub set_image_height {
  $_[0]->{'custom_style'}->{'height'} = $_[1];
}

=item add_data_series([8, 6, 7, 5, 3, 0, 9], 'Series Name');

Adds a data series to the graph.  For L<Imager::Graph::Pie>, only one data series can be added.

=cut

sub add_data_series {
  my $self = shift;
  my $data_ref = shift;
  my $series_name = shift;

  my $graph_data = $self->{'graph_data'} || [];

  push @$graph_data, { data => $data_ref, series_name => $series_name };

  $self->{'graph_data'} = $graph_data;
  return;
}

sub _get_data_series {
  my ($self, $opts) = @_;

  # return the data supplied to draw() if any.
  if ($opts->{data}) {
    # one or multiple series?
    my $data = $opts->{data};
    if (@$data && ref $data->[0] && ref $data->[0] =~ /ARRAY/) {
      return $data;
    }
    else {
      return [ { data => $data } ];
    }
  }

  return $self->{'graph_data'};
}

=item set_labels(['label1', 'label2' ... ])

Labels the specific data points.  For line/bar graphs, this is the x-axis.  For pie graphs, it is the label for the wedges.

=cut

sub set_labels {
  $_[0]->{'labels'} = $_[1];
}

sub _get_labels {
  my ($self, $opts) = @_;

  $opts->{labels}
    and return $opts->{labels};

  return $_[0]->{'labels'}
}

=item set_title($title)

Sets the title of the graph.  Requires setting a font.

=cut

sub set_title {
  $_[0]->{'custom_style'}->{'title'}->{'text'} = $_[1];
}

=item set_font($font)

Sets the font to use for text.  Takes an L<Imager::Font> object.

=cut

sub set_font {
  $_[0]->{'custom_style'}->{'font'} = $_[1];
}

=item set_style($style_name)

Sets the style to be used for the graph.  Imager::Graph comes with several pre-defined styles: fount_lin (default), fount_rad, mono, primary_red, and primary.

=cut

sub set_style {
  $_[0]->{'style'} = $_[1];
}

sub _get_style {
  my ($self, $opts) = @_;

  $opts->{style}
    and return $opts->{style};

  return $self->{'style'};
}

=item error

Returns an error message.  Only valid if the draw() method returns false.

=cut

sub error {
  $_[0]->{_errstr};
}

=item draw

Creates a new image, draws the chart onto that image and returns it.

Optionally, instead of using the api methods to configure your chart,
you can supply a C<data> parameter in the format
required by that particular graph, and if your graph will use any
text, a C<font> parameter

You can also supply many different parameters which control the way
the graph looks.  These are supplied as keyword, value pairs, where
the value can be a hashref containing sub values.

The C<style> parameter will selects a basic color set, and possibly
sets other related parameters.  See L</"STYLES">.

 my $font = Imager::Font->new(file => 'ImUgly.ttf');
 my $img = $chart->draw(
                 data    => \@data,
                 font    => $font,
                 title   => {
                                 text  => "Hello, World!",
                                 size  => 36,
                                 color => 'FF0000'
                            }
                 );

When referring to a single sub-value this documentation will refer to
'title.color' rather than 'the color element of title'.

Returns the graph image on success, or false on failure.

=back

=head1 STYLES

The currently defined styles are:

=over

=item primary

a light grey background with no outlines.  Uses primary colors for the
data fills.

=item primary_red

a light red background with no outlines.  Uses primary colors for the
data fills.

Graphs drawn using this style should save well as a gif, even though
some graphs may perform a slight blur.

This was the default style, but the red was too loud.

=item mono

designed for monochrome output, such as most laser printers, this uses
hatched fills for the data, and no colors.  The returned image is a
one channel image (which can be overridden with the C<channels>
parameter.)

You can also override the colors used by all components for background
or drawing by supplying C<fg> and/or C<bg> parameters.  ie.  if you
supply C<<fg=>'FF0000', channels=>3>> then the hash fills and anything
else will be drawn in red.  Another use might be to set a transparent
background, by supplying C<<bg=>'00000000', channels=>4>>.

This style outlines the legend if present and outlines the hashed fills.

=item fount_lin

designed as a "pretty" style this uses linear fountain fills for the
background and data fills, and adds a drop shadow.

You can override the value used for text and outlines by setting the
C<fg> parameter.

This is the default style.

=item fount_rad

also designed as a "pretty" style this uses radial fountain fills for
the data and a linear blue to green fill for the background.

=back

=head1 Style API

To set or override styles, you can use the following methods:

=over 4

=item set_image_background

=cut

sub set_image_background {
  $_[0]->{'custom_style'}->{'back'} = $_[1];
}

=item set_channels

=cut

sub set_channels {
  $_[0]->{'custom_style'}->{'channels'} = $_[1];
}

=item set_line_color

=cut

sub set_line_color {
  $_[0]->{'custom_style'}->{'line'} = $_[1];
}

=item set_title_font_size

=cut

sub set_title_font_size {
  $_[0]->{'custom_style'}->{'title'}->{'size'} = $_[1];
}

=item set_title_font_color

=cut

sub set_title_font_color {
  $_[0]->{'custom_style'}->{'title'}->{'color'} = $_[1];
}

=item set_title_horizontal_align

=cut

sub set_title_horizontal_align {
  $_[0]->{'custom_style'}->{'title'}->{'halign'} = $_[1];
}

=item set_title_vertical_align

=cut

sub set_title_vertical_align {
  $_[0]->{'custom_style'}->{'title'}->{'valign'} = $_[1];
}

=item set_text_font_color

=cut

sub set_text_font_color {
  $_[0]->{'custom_style'}->{'text'}->{'color'} = $_[1];
}

=item set_text_font_size

=cut

sub set_text_font_size {
  $_[0]->{'custom_style'}->{'text'}->{'size'} = $_[1];
}

=item set_graph_background_color

=cut

sub set_graph_background_color {
  $_[0]->{'custom_style'}->{'bg'} = $_[1];
}

=item set_graph_foreground_color

=cut

sub set_graph_foreground_color {
  $_[0]->{'custom_style'}->{'fg'} = $_[1];
}

=item set_legend_font_color

=cut

sub set_legend_font_color {
  $_[0]->{'custom_style'}->{'legend'}->{'color'} = $_[1];
}

=item set_legend_font

=cut

sub set_legend_font {
  $_[0]->{'custom_style'}->{'legend'}->{'font'} = $_[1];
}

=item set_legend_font_size

=cut

sub set_legend_font_size {
  $_[0]->{'custom_style'}->{'legend'}->{'size'} = $_[1];
}

=item set_legend_patch_size

=cut

sub set_legend_patch_size {
  $_[0]->{'custom_style'}->{'legend'}->{'patchsize'} = $_[1];
}

=item set_legend_patch_gap

=cut

sub set_legend_patch_gap {
  $_[0]->{'custom_style'}->{'legend'}->{'patchgap'} = $_[1];
}

=item set_legend_horizontal_align

=cut

sub set_legend_horizontal_align {
  $_[0]->{'custom_style'}->{'legend'}->{'halign'} = $_[1];
}

=item set_legend_vertical_align

=cut

sub set_legend_vertical_align {
  $_[0]->{'custom_style'}->{'legend'}->{'valign'} = $_[1];
}

=item set_legend_padding

=cut

sub set_legend_padding {
  $_[0]->{'custom_style'}->{'legend'}->{'padding'} = $_[1];
}

=item set_legend_outside_padding

=cut

sub set_legend_outside_padding {
  $_[0]->{'custom_style'}->{'legend'}->{'outsidepadding'} = $_[1];
}

=item set_legend_fill

=cut

sub set_legend_fill {
  $_[0]->{'custom_style'}->{'legend'}->{'fill'} = $_[1];
}

=item set_legend_border

=cut

sub set_legend_border {
  $_[0]->{'custom_style'}->{'legend'}->{'border'} = $_[1];
}

=item set_legend_orientation

=cut

sub set_legend_orientation {
  $_[0]->{'custom_style'}->{'legend'}->{'orientation'} = $_[1];
}

=item set_callout_font_color

=cut

sub set_callout_font_color {
  $_[0]->{'custom_style'}->{'callout'}->{'color'} = $_[1];
}

=item set_callout_font

=cut

sub set_callout_font {
  $_[0]->{'custom_style'}->{'callout'}->{'font'} = $_[1];
}

=item set_callout_font_size

=cut

sub set_callout_font_size {
  $_[0]->{'custom_style'}->{'callout'}->{'size'} = $_[1];
}

=item set_callout_line_color

=cut

sub set_callout_line_color {
  $_[0]->{'custom_style'}->{'callout'}->{'line'} = $_[1];
}

=item set_callout_leader_inside_length

=cut

sub set_callout_leader_inside_length {
  $_[0]->{'custom_style'}->{'callout'}->{'inside'} = $_[1];
}

=item set_callout_leader_outside_length

=cut

sub set_callout_leader_outside_length {
  $_[0]->{'custom_style'}->{'callout'}->{'outside'} = $_[1];
}

=item set_callout_leader_length

=cut

sub set_callout_leader_length {
  $_[0]->{'custom_style'}->{'callout'}->{'leadlen'} = $_[1];
}

=item set_callout_gap

=cut

sub set_callout_gap {
  $_[0]->{'custom_style'}->{'callout'}->{'gap'} = $_[1];
}

=item set_label_font_color

=cut

sub set_label_font_color {
  $_[0]->{'custom_style'}->{'label'}->{'color'} = $_[1];
}

=item set_label_font

=cut

sub set_label_font {
  $_[0]->{'custom_style'}->{'label'}->{'font'} = $_[1];
}

=item set_label_font_size

=cut

sub set_label_font_size {
  $_[0]->{'custom_style'}->{'label'}->{'size'} = $_[1];
}

=item set_drop_shadow_fill_color

=cut

sub set_drop_shadow_fill_color {
  $_[0]->{'custom_style'}->{'dropshadow'}->{'fill'} = $_[1];
}

=item set_drop_shadow_offset

=cut

sub set_drop_shadow_offset {
  $_[0]->{'custom_style'}->{'dropshadow'}->{'off'} = $_[1];
}

=item set_drop_shadowXOffset

=cut

sub set_drop_shadowXOffset {
  $_[0]->{'custom_style'}->{'dropshadow'}->{'offx'} = $_[1];
}

=item set_drop_shadowYOffset

=cut

sub set_drop_shadowYOffset {
  $_[0]->{'custom_style'}->{'dropshadow'}->{'offy'} = $_[1];
}

=item set_drop_shadow_filter

=cut

sub set_drop_shadow_filter {
  $_[0]->{'custom_style'}->{'dropshadow'}->{'filter'} = $_[1];
}

=item set_outline_color

=cut

sub set_outline_color {
  $_[0]->{'custom_style'}->{'outline'}->{'line'} = $_[1];
}

=item set_data_area_fills

=cut

sub set_data_area_fills {
  $_[0]->{'custom_style'}->{'fills'} = $_[1];
}

=item set_data_line_colors

=cut

sub set_data_line_colors {
  $_[0]->{'custom_style'}->{'colors'} = $_[1];
}

=back

=head1 FEATURES

Each graph type has a number of features.  These are used to add
various items that are displayed in the graph area.  Some common
methods are:

=over

=item show_legend()

adds a box containing boxes filled with the data filess, with
the labels provided to the draw method.  The legend will only be
displayed if both the legend feature is enabled and labels are
supplied.

=cut

sub show_legend {
    $_[0]->{'custom_style'}->{'features'}->{'legend'} = 1;
}

=item show_outline()

draws a border around the data areas.

=cut

sub show_outline {
    $_[0]->{'custom_style'}->{'features'}->{'outline'} = 1;
}

=item show_labels()

labels each data fill, usually by including text inside the data fill.
If the text does not fit in the fill, they could be displayed in some
other form, eg. as callouts in a pie graph.  There usually isn't much
point in including both labels and a legend.

=cut

sub show_labels {
    $_[0]->{'custom_style'}->{'features'}->{'labels'} = 1;
}

=item show_drop_shadow()

a simple drop shadow is shown behind some of the graph elements.

=cut

sub show_drop_shadow {
    $_[0]->{'custom_style'}->{'features'}->{'dropshadow'} = 1;
}

=item reset_features()

Unsets all of the features

=cut

sub reset_features {
    $_[0]->{'custom_style'}->{'features'} = {};
    $_[0]->{'custom_style'}->{'features'}->{'reset'} = 1;
}

=back

Additionally, features can be set by passing them into the draw() method:

=over

=item legend

adds a box containing boxes filled with the data filess, with
the labels provided to the draw method.  The legend will only be
displayed if both the legend feature is enabled and labels are
supplied.

=item labels

labels each data fill, usually by including text inside the data fill.
If the text does not fit in the fill, they could be displayed in some
other form, eg. as callouts in a pie graph.  There usually isn't much
point in including both labels and a legend.

=item dropshadow

a simple drop shadow is shown behind some of the graph elements.

=back

Each graph also has features specific to that graph.

=head1 COMMON PARAMETERS

When referring to a single sub-value this documentation will refer to
'title.color' rather than 'the color element of title'.

Normally, except for the font parameter, these are controlled by
styles, but these are the style parameters I'd mostly likely expect
you want to use:

=over

=item font

the Imager font object used to draw text on the chart.

=item back

the background fill for the graph.  Default depends on the style.

=item size

the base size of the graph image.  Default: 256

=item width

the width of the graph image.  Default: 1.5 * size (384)

=item height

the height of the graph image.  Default: size (256)

=item channels

the number of channels in the image.  Default: 3 (the 'mono' style
sets this to 1).

=item line

the color used for drawing lines, such as outlines or callouts.
Default depends on the current style.  Set to undef to remove the
outline from a style.

=item title

the text used for a graph title.  Default: no title.  Note: this is
the same as the title=>{ text => ... } field.

=over

=item halign

horizontal alignment of the title in the graph, one of 'left',
'center' or 'right'. Default: center

=item valign

vertical alignment of the title, one of 'top', 'center' or 'right'.
Default: top.  It's probably a bad idea to set this to 'center' unless
you have a very short title.

=back

=item text

This contains basic defaults used in drawing text.

=over

=item color

the default color used for all text, defaults to the fg color.

=item size

the base size used for text, also used to scale many graph elements.
Default: 14.

=back

=back

=head1 BEYOND STYLES

In most cases you will want to use just the styles, but you may want
to exert more control over the way your chart looks.  This section
describes the options you can use to control the way your chart looks.

Hopefully you don't need to read this.

=over

=item back

The background of the graph.

=item bg

=item fg

Used to define basic background and foreground colors for the graph.
The bg color may be used for the background of the graph, and is used
as a default for the background of hatcheed fills.  The fg is used as
the default for line and text colors.

=item font

The default font used by the graph.  Normally you should supply this
if your graph as any text.

=item line

The default line color.

=item text

defaults for drawing text.  Other textual graph elements will inherit
or modify these values.

=over

=item color

default text color, defaults to the I<fg> color.

=item size

default text size. Default: 14.  This is used to scale many graph
elements, including padding and leader sizes.  Other text elements
will either use or scale this value.

=item font

default font object.  Inherited from I<font>, which should have been
supplied by the caller.

=back

=item title

If you supply a scalar value for this element, it will be stored in
the I<text> field.

Defines the text, font and layout information for the title.

=over

=item color

The color of the title, inherited from I<text.color>.

=item font

The font object used for the title, inherited from I<text.font>.

=item size

size of the title text. Default: double I<text.size>

=item halign

=item valign

The horizontal and vertical alignment of the title.

=back

=item legend

defines attributes of the graph legend, if present.

=over

=item color

=item font

=item size

text attributes for the labels used in the legend.

=item patchsize

the width and height of the color patch in the legend.  Defaults to
90% of the legend text size.

=item patchgap

the minimum gap between patches in pixels.  Defaults to 30% of the
patchsize.

=item patchborder

the color of the border drawn around each patch.  Inherited from I<line>.

=item halign

=item valign

the horizontal and vertical alignment of the legend within the graph.
Defaults to 'right' and 'top'.

=item padding

the gap between the legend patches and text and the outside of it's
box, or to the legend border, if any.

=item outsidepadding

the gap between the border and the outside of the legend's box.  This
is only used if the I<legend.border> attribute is defined.

=item fill

the background fill for the legend.  Default: none

=item border

the border color of the legend.  Default: none (no border is drawn
around the legend.)

=item orientation

The orientation of the legend.  If this is C<vertical> the the patches
and labels are stacked on top of each other.  If this is C<horizontal>
the patchs and labels are word wrapped across the image.  Default:
vertical.

=back

For example to create a horizontal legend with borderless patches,
darker than the background, you might do:

  my $im = $chart->draw
    (...,
    legend =>
    {
      patchborder => undef,
      orientation => 'horizontal',
      fill => { solid => Imager::Color->new(0, 0, 0, 32), }
    },
    ...);

=item callout

defines attributes for graph callouts, if any are present.  eg. if the
pie graph cannot fit the label into the pie graph segement it will
present it as a callout.

=over

=item color

=item font

=item size

the text attributes of the callout label.  Inherited from I<text>.

=item line

the color of the callout lines.  Inherited from I<line>

=item inside

=item outside

the length of the leader on the inside and the outside of the fill,
usually at some angle.  Both default to the size of the callout text.

=item leadlen

the length of the horizontal portion of the leader.  Default:
I<callout.size>.

=item gap

the gap between the callout leader and the callout text.  Defaults to
30% of the text callout size.

=back

=item label

defines attributes for labels drawn into the data areas of a graph.

=over

=item color

=item font

=item size

The text attributes of the labels.  Inherited from I<text>.

=back

=item dropshadow

the attributes of the graph's drop shadow

=over

=item fill

the fill used for the drop shadow.  Default: '404040' (dark gray)

=item off

the offset of the drop shadow.  A convenience value inherited by offx
and offy.  Default: 40% of I<text.size>.

=item offx

=item offy

the horizontal and vertical offsets of the drop shadow.  Both
inherited from I<dropshadow.off>.

=item filter

the filter description passed to Imager's filter method to blur the
drop shadow.  Default: an 11 element convolution filter.

=back

=item outline

describes the lines drawn around filled data areas, such as the
segments of a pie chart.

=over

=item line

the line color of the outlines, inherited from I<line>.

=back

=item fills

a reference to an array containing fills for each data item.

You can mix fill types, ie. using a simple color for the first item, a
hatched fill for the second and a fountain fill for the next.

=back

=head1 HOW VALUES WORK

Internally rather than specifying literal color, fill, or font objects
or literal sizes for each element, Imager::Graph uses a number of
special values to inherit or modify values taken from other graph
element names.

=head2 Specifying colors

You can specify colors by either supplying an Imager::Color object, by
supplying lookup of another color, or by supplying a single value that
Imager::Color::new can use as an initializer.  The most obvious is
just a 6 or 8 digit hex value representing the red, green, blue and
optionally alpha channels of the image.

You can lookup another color by using the lookup() "function", for
example if you give a color as "lookup(fg)" then Imager::Graph will
look for the fg element in the current style (or as overridden by
you.)  This is used internally by Imager::Graph to set up the
relationships between the colors of various elements, for example the
default style information contains:

   text=>{
          color=>'lookup(fg)',
          ...
         },
   legend =>{
             color=>'lookup(text.color)',
             ...
            },

So by setting the I<fg> color, you also set the default text color,
since each text element uses lookup(text.color) as its value.

=head2 Specifying fills

Fills can be used for the graph background color, the background color
for the legend block and for the fills used for each data element.

You can specify a fill as a L<color value|Specifying colors> or as a
general fill, see L<Imager::Fill> for details.

You don't need (or usually want) to call Imager::Fill::new yourself,
since the various fill functions will call it for you, and
Imager::Graph provides some hooks to make them more useful.

=over

=item *

with hatched fills, if you don't supply a 'fg' or 'bg' parameter,
Imager::Graph will supply the current graph fg and bg colors.

=item *

with fountain fill, you can supply the xa_ratio, ya_ratio, xb_ratio
and yb_ratio parameters, and they will be scaled in the fill area to
define the fountain fills xa, ya, xb and yb parameters.

=back

As with colors, you can use lookup(name) or lookup(name1.name2) to
have one element to inherit the fill of another.

Imager::Graph defaults the fill combine value to C<'normal'>.  This
doesn't apply to simple color fills.

=head2 Specifying numbers

You can specify various numbers, usually representing the size of
something, commonly text, but sometimes the length of a line or the
size of a gap.

You can use the same lookup mechanism as with colors and fills, but
you can also scale values.  For example, 'scale(0.5,text.size)' will
return half the size of the normal text size.

As with colors, this is used internally to scale graph elements based
on the base text size.  If you change the base text size then other
graph elements will scale as well.

=head2 Specifying other elements

Other elements, such as fonts, or parameters for a filter, can also
use the lookup(name) mechanism.

=head1 INTERNAL METHODS

Only useful if you need to fix bugs, add features or create a new
graph class.

=over

=cut

my %style_defs =
  (
   back=> 'lookup(bg)',
   line=> 'lookup(fg)',
   aa => 1,
   text=>{
          color => 'lookup(fg)',
          font  => 'lookup(font)',
          size  => 14,
	  aa    => 'lookup(aa)',
         },
   title=>{ 
           color  => 'lookup(text.color)', 
           font   => 'lookup(text.font)',
           halign => 'center', 
           valign => 'top',
           size   => 'scale(text.size,2.0)',
	   aa     => 'lookup(text.aa)',
          },
   legend =>{
             color          => 'lookup(text.color)',
             font           => 'lookup(text.font)',
	     aa             => 'lookup(text.aa)',
             size           => 'lookup(text.size)',
             patchsize      => 'scale(legend.size,0.9)',
             patchgap       => 'scale(legend.patchsize,0.3)',
             patchborder    => 'lookup(line)',
             halign         => 'right',
             valign         => 'top',
             padding        => 'scale(legend.size,0.3)',
             outsidepadding => 'scale(legend.padding,0.4)',
            },
   callout => {
               color    => 'lookup(text.color)',
               font     => 'lookup(text.font)',
               size     => 'lookup(text.size)',
               line     => 'lookup(line)',
               inside   => 'lookup(callout.size)',
               outside  => 'lookup(callout.size)',
               leadlen  => 'scale(0.8,callout.size)',
               gap      => 'scale(callout.size,0.3)',
	       aa       => 'lookup(text.aa)',
	       lineaa   => 'lookup(lineaa)',
              },
   label => {
             font          => 'lookup(text.font)',
             size          => 'lookup(text.size)',
             color         => 'lookup(text.color)',
             hpad          => 'lookup(label.pad)',
             vpad          => 'lookup(label.pad)',
             pad           => 'scale(label.size,0.2)',
             pcformat      => sub { sprintf "%s (%.0f%%)", $_[0], $_[1] },
             pconlyformat  => sub { sprintf "%.1f%%", $_[0] },
	     aa            => 'lookup(text.aa)',
	     lineaa        => 'lookup(lineaa)',
             },
   dropshadow => {
                  fill    => { solid => Imager::Color->new(0, 0, 0, 96) },
                  off     => 'scale(0.4,text.size)',
                  offx    => 'lookup(dropshadow.off)',
                  offy    => 'lookup(dropshadow.off)',
                  filter  => { type=>'conv', 
                              # this needs a fairly heavy blur
                              coef=>[0.1, 0.2, 0.4, 0.6, 0.7, 0.9, 1.2, 
                                     0.9, 0.7, 0.6, 0.4, 0.2, 0.1 ] },
                 },
   outline => {
               line =>'lookup(line)',
	       lineaa => 'lookup(lineaa)',
              },
   size=>256,
   width=>'scale(1.5,size)',
   height=>'lookup(size)',

   # yes, the handling of fill and line AA is inconsistent, lack of
   # forethought, unfortunately
   fill => {
	    aa => 'lookup(aa)',
	   },
   lineaa => 'lookup(aa)',
  );

=item _error($message)

Sets the error field of the object and returns an empty list or undef,
depending on context.  Should be used for error handling, since it may
provide some user hooks at some point.

The intended usage is:

  some action
    or return $self->_error("error description");

You should almost always return the result of _error() or return
immediately afterwards.

=cut

sub _error {
  my ($self, $error) = @_;

  $self->{_errstr} = $error;

  return;
}


=item _style_defs()

Returns the style defaults, such as the relationships between line
color and text color.

Intended to be over-ridden by base classes to provide graph specific
defaults.

=cut

sub _style_defs {
  \%style_defs;
}

# Let's make the default something that looks really good, so folks will be interested enough to customize the style.
my $def_style = 'fount_lin';

my %styles =
  (
   primary =>
   {
    fills=>
    [
     qw(FF0000 00FF00 0000FF C0C000 00C0C0 FF00FF)
    ],
    fg=>'000000',
    negative_bg=>'EEEEEE',
    bg=>'E0E0E0',
    legend=>
    {
     #patchborder=>'000000'
    },
   },
   primary_red =>
   {
    fills=>
    [
     qw(FF0000 00FF00 0000FF C0C000 00C0C0 FF00FF)
    ],
    fg=>'000000',
    negative_bg=>'EEEEEE',
    bg=>'C08080',
    legend=>
    {
     patchborder=>'000000'
    },
   },
   mono =>
   {
    fills=>
    [
     { hatch=>'slash2' },
     { hatch=>'slosh2' },
     { hatch=>'vline2' },
     { hatch=>'hline2' },
     { hatch=>'cross2' },
     { hatch=>'grid2' },
     { hatch=>'stipple3' },
     { hatch=>'stipple2' },
    ],
    channels=>1,
    bg=>'FFFFFF',
    fg=>'000000',
    negative_bg=>'EEEEEE',
    features=>{ outline=>1 },
    pie =>{
           blur=>undef,
          },
    aa => 0,
   },
   fount_lin =>
   {
    fills=>
    [
     { fountain=>'linear',
       xa_ratio=>0.13, ya_ratio=>0.13, xb_ratio=>0.87, yb_ratio=>0.87,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('FFC0C0'), NC('FF0000') ]),
     },
     { fountain=>'linear',
       xa_ratio=>0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('C0FFC0'), NC('00FF00') ]),
     },
     { fountain=>'linear',
       xa_ratio=>0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('C0C0FF'), NC('0000FF') ]),
     },
     { fountain=>'linear',
       xa_ratio=>0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('FFFFC0'), NC('FFFF00') ]),
     },
     { fountain=>'linear',
       xa_ratio=>0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('C0FFFF'), NC('00FFFF') ]),
     },
     { fountain=>'linear',
       xa_ratio=>0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('FFC0FF'), NC('FF00FF') ]),
     },
    ],
    colors  => [
     qw(FF0000 00FF00 0000FF C0C000 00C0C0 FF00FF)
    ],
    line_markers =>[
      { shape => 'circle',   radius => 4 },
      { shape => 'square',   radius => 4 },
      { shape => 'diamond',  radius => 4 },
      { shape => 'triangle', radius => 4 },
      { shape => 'x',        radius => 4 },
      { shape => 'plus',     radius => 4 },
    ],
    back=>{ fountain=>'linear',
            xa_ratio=>0, ya_ratio=>0,
            xb_ratio=>1.0, yb_ratio=>1.0,
            segments=>Imager::Fountain->simple
            ( positions=>[0, 1],
              colors=>[ NC('6060FF'), NC('60FF60') ]) },
    fg=>'000000',
    negative_bg=>'EEEEEE',
    bg=>'FFFFFF',
    features=>{ dropshadow=>1 },
   },
   fount_rad =>
   {
    fills=>
    [
     { fountain=>'radial',
       xa_ratio=>0.5, ya_ratio=>0.5, xb_ratio=>1.0, yb_ratio=>0.5,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('FF8080'), NC('FF0000') ]),
     },
     { fountain=>'radial',
       xa_ratio=>0.5, ya_ratio=>0.5, xb_ratio=>1.0, yb_ratio=>0.5,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('80FF80'), NC('00FF00') ]),
     },
     { fountain=>'radial',
       xa_ratio=>0.5, ya_ratio=>0.5, xb_ratio=>1.0, yb_ratio=>0.5,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('808080FF'), NC('0000FF') ]),
     },
     { fountain=>'radial',
       xa_ratio=>0.5, ya_ratio=>0.5, xb_ratio=>1.0, yb_ratio=>0.5,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('FFFF80'), NC('FFFF00') ]),
     },
     { fountain=>'radial',
       xa_ratio=>0.5, ya_ratio=>0.5, xb_ratio=>1.0, yb_ratio=>0.5,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('80FFFF'), NC('00FFFF') ]),
     },
     { fountain=>'radial',
       xa_ratio=>0.5, ya_ratio=>0.5, xb_ratio=>1.0, yb_ratio=>0.5,
       segments => Imager::Fountain->simple(positions=>[0, 1],
                                            colors=>[ NC('FF80FF'), NC('FF00FF') ]),
     },
    ],
    colors  => [
     qw(FF0000 00FF00 0000FF C0C000 00C0C0 FF00FF)
    ],
    back=>{ fountain=>'linear',
            xa_ratio=>0, ya_ratio=>0,
            xb_ratio=>1.0, yb_ratio=>1.0,
            segments=>Imager::Fountain->simple
            ( positions=>[0, 1],
              colors=>[ NC('6060FF'), NC('60FF60') ]) },
    fg=>'000000',
    negative_bg=>'EEEEEE',
    bg=>'FFFFFF',
   }
  );

$styles{'ocean'} = {
    fills  => [
             {
              fountain =>'linear',
              xa_ratio => 0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
              segments => Imager::Fountain->simple(
                                                    positions=>[0, 1],
                                                    colors=>[ NC('FFFFFF'), NC('E6E2AF') ]),
            },
             {
              fountain =>'linear',
              xa_ratio => 0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
              segments => Imager::Fountain->simple(
                                                    positions=>[0, 1],
                                                    colors=>[ NC('FFFFFF'), NC('A7A37E') ]),
            },
             {
              fountain =>'linear',
              xa_ratio => 0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
              segments => Imager::Fountain->simple(
                                                    positions=>[0, 1],
                                                    colors=>[ NC('FFFFFF'), NC('80B4A2') ]),
            },
            {
              fountain =>'linear',
              xa_ratio => 0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
              segments => Imager::Fountain->simple(
                                                    positions=>[0, 1],
                                                    colors=>[ NC('FFFFFF'), NC('046380') ]),
            },
            {
              fountain =>'linear',
              xa_ratio => 0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
              segments => Imager::Fountain->simple(
                                                    positions=>[0, 1],
                                                    colors=>[ NC('FFFFFF'), NC('877EA7') ]),
            },
            {
              fountain =>'linear',
              xa_ratio => 0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
              segments => Imager::Fountain->simple(
                                                    positions=>[0, 1],
                                                    colors=>[ NC('FFFFFF'), NC('67A35E') ]),
            },
            {
              fountain =>'linear',
              xa_ratio => 0, ya_ratio=>0, xb_ratio=>1.0, yb_ratio=>1.0,
              segments => Imager::Fountain->simple(
                                                    positions=>[0, 1],
                                                    colors=>[ NC('FFFFFF'), NC('B4726F') ]),
            },
    ],
    colors  => [
     qw(E6E2AF A7A37E 80B4A2 046380 877EA7 67A35E B4726F)
    ],
    fg=>'000000',
    negative_bg=>'EEEEEE',
    bg=>'FFFFFF',
    features=>{ dropshadow=>1 },

};

=item $self->_style_setup(\%opts)

Uses the values from %opts to build a customized hash describing the
way the graph should be drawn.

=cut

sub _style_setup {
  my ($self, $opts) = @_;
  my $style_defs = $self->_style_defs;
  my $style;

  my $pre_def_style = $self->_get_style($opts);
  my $api_style = $self->{'custom_style'} || {};
  $style = $styles{$pre_def_style} if $pre_def_style;

  $style ||= $styles{$def_style};

  my @search_list = ( $style_defs, $style, $api_style, $opts);
  my %work;

  my @composite = $self->_composite();
  my %composite;
  @composite{@composite} = @composite;

  for my $src (@search_list) {
    for my $key (keys %$src) {
      if ($composite{$key}) {
        $work{$key} = {} unless exists $work{$key};
        if (ref $src->{$key}) {
          # some keys have sub values, especially text
          @{$work{$key}}{keys %{$src->{$key}}} = values %{$src->{$key}};
        }
        else {
          # assume it's the text for a title or something
          $work{$key}{text} = $src->{$key};
        }
      }
      else {
        $work{$key} = $src->{$key}
	  if defined $src->{$key}; # $opts with pmichauds new accessor handling
      }
    }
  }

  # features are handled specially
  $work{features} = {};
  for my $src (@search_list) {
    if ($src->{features}) {
      if (ref $src->{features}) {
        if (ref($src->{features}) =~ /ARRAY/) {
          # just set those features
          for my $feature (@{$src->{features}}) {
            $work{features}{$feature} = 1;
          }
        }
        elsif (ref($src->{features}) =~ /HASH/) {
          if ($src->{features}{reset}) {
            $work{features} = {}; # only the ones the user specifies
          }
          @{$work{features}}{keys %{$src->{features}}} =
            values(%{$src->{features}});
        }
      }
      else {
        # just set that single feature
        $work{features}{$src->{features}} = 1;
      }
    }
  }
  #use Data::Dumper;
  #print Dumper(\%work);

  $self->{_style} = \%work;
}

=item $self->_get_thing($name)

Retrieve some general 'thing'.

Supports the 'lookup(foo)' mechanism.

Returns an empty list on failure.

=cut

sub _get_thing {
  my ($self, $name, @depth) = @_;

  push(@depth, $name);
  my $what;
  if ($name =~ /^(\w+)\.(\w+)$/) {
    $what = $self->{_style}{$1}{$2};
  }
  else {
    $what = $self->{_style}{$name};
  }
  defined $what or
    return;
  if (ref $what) {
    return $what;
  }
  elsif ($what =~ /^lookup\((\w+(?:\.\w+)?)\)$/) {
    @depth < MAX_DEPTH
      or return $self->_error("too many levels of recursion in lookup(@depth)");
    return $self->_get_thing($1, @depth);
  }
  else {
    return $what;
  }
}

=item $self->_get_number($name)

Retrieves a number from the style.  The value in the style can be the
number, or one of two functions:

=over

=item lookup(newname)

Recursively looks up I<newname> in the style.

=item scale(value1,value2)

Each value can be a number or a name.  Names are recursively looked up
in the style and the product is returned.

=back

=cut

sub _get_number {
  my ($self, $name, @depth) = @_;

  push(@depth, $name);
  my $what;
  if ($name =~ /^(\w+)\.(\w+)$/) {
    $what = $self->{_style}{$1}{$2};
  }
  else {
    $what = $self->{_style}{$name};
  }
  defined $what or
    return $self->_error("$name is undef (@depth)");

  if (ref $what) {
    if ($what =~ /CODE/) {
      $what = $what->($self, $name);
    }
  }
  else {
    if ($what =~ /^lookup\(([\w.]+)\)$/) {
      @depth < MAX_DEPTH
        or return $self->_error("too many levels of recursion in lookup (@depth)");
      return $self->_get_number($1, @depth);
    }
    elsif ($what =~ /^scale\(
                    ((?:[a-z][\w.]*)|$NUM_RE)
                    ,
                    ((?:[a-z][\w.]*)|$NUM_RE)\)$/x) {
      my ($left, $right) = ($1, $2);
      unless ($left =~ /^$NUM_RE$/) {
        @depth < MAX_DEPTH 
          or return $self->_error("too many levels of recursion in scale (@depth)");
        $left = $self->_get_number($left, @depth);
      }
      unless ($right =~ /^$NUM_RE$/) {
        @depth < MAX_DEPTH 
          or return $self->_error("too many levels of recursion in scale (@depth)");
        $right = $self->_get_number($right, @depth);
      }
      return $left * $right;
    }
    else {
      return $what+0;
    }
  }
}

=item $self->_get_integer($name)

Retrieves an integer from the style.  This is a simple wrapper around
_get_number() that rounds the result to an integer.

Returns an empty list on failure.

=cut

sub _get_integer {
  my ($self, $name, @depth) = @_;

  my $number = $self->_get_number($name, @depth)
    or return;

  return sprintf("%.0f", $number);
}

=item _get_color($name)

Returns a color object of the given name from the style hash.

Uses Imager::Color->new to translate normal scalars into color objects.

Allows the lookup(name) mechanism.

Returns an empty list on failure.

=cut

sub _get_color {
  my ($self, $name, @depth) = @_;

  push(@depth, $name);
  my $what;
  if ($name =~ /^(\w+)\.(\w+)$/) {
    $what = $self->{_style}{$1}{$2};
  }
  else {
    $what = $self->{_style}{$name};
  }

  defined($what)
    or return $self->_error("$name was undefined (@depth)");

  unless (ref $what) {
    if ($what =~ /^lookup\((\w+(?:\.\w+)?)\)$/) {
      @depth < MAX_DEPTH or
        return $self->_error("too many levels of recursion in lookup (@depth)");

      return $self->_get_color($1, @depth);
    }
    $what = Imager::Color->new($what);
  }

  $what;
}

=item _translate_fill($what, $box)

Given the value of a fill, either attempts to convert it into a fill
list (one of C<<color=>$color_value, filled=>1>> or C<<fill=>{ fill
parameters }>>), or to lookup another fill that is referred to with
the 'lookup(name)' mechanism.

This function does the fg and bg initialization for hatched fills, and
translation of *_ratio for fountain fills (using the $box parameter).

Returns an empty list on failure.

=cut

sub _translate_fill {
  my ($self, $what, $box, @depth) = @_;

  if (ref $what) {
    if (UNIVERSAL::isa($what, "Imager::Color")) {
      return ( color=>Imager::Color->new($what), filled=>1 );
    }
    else {
      # a general fill
      # default to normal combine mode
      my %work = ( combine => 'normal', %$what );
      if ($what->{hatch}) {
        if (!$work{fg}) {
          $work{fg} = $self->_get_color('fg')
            or return;
        }
        if (!$work{bg}) {
          $work{bg} = $self->_get_color('bg')
            or return;
        }
        return ( fill=>\%work );
      }
      elsif ($what->{fountain}) {
        for my $key (qw(xa ya xb yb)) {
          if (exists $work{"${key}_ratio"}) {
            if ($key =~ /^x/) {
              $work{$key} = $box->[0] + $work{"${key}_ratio"} 
                * ($box->[2] - $box->[0]);
            }
            else {
              $work{$key} = $box->[1] + $work{"${key}_ratio"} 
                * ($box->[3] - $box->[1]);
            }
          }
        }
        return ( fill=>\%work );
      }
      else {
        return ( fill=> \%work );
      }
    }
  }
  else {
    if ($what =~ /^lookup\((\w+(?:\.\w+)?)\)$/) {
      return $self->_get_fill($1, $box, @depth);
    }
    else {
      # assumed to be an Imager::Color single value
      return ( color=>Imager::Color->new($what), filled=>1 );
    }
  }
}

=item _data_fill($index, $box)

Retrieves the fill parameters for a data area fill.

=cut

sub _data_fill {
  my ($self, $index, $box) = @_;

  my $fills = $self->{_style}{fills};
  return $self->_translate_fill($fills->[$index % @$fills], $box,
                                "data.$index");
}

sub _data_color {
  my ($self, $index) = @_;

  my $colors = $self->{'_style'}{'colors'} || [];
  my $fills  = $self->{'_style'}{'fills'} || [];

  # Try to just use a fill, so non-fountain styles don't need
  # to have a duplicated set of fills and colors
  my $fill = $fills->[$index % @$fills];
  if (!ref $fill) {
    return $fill;
  }

  if (@$colors) {
    return $colors->[$index % @$colors] || '000000';
  }
  return '000000';
}

=item _get_fill($index, $box)

Retrieves fill parameters for a named fill.

=cut

sub _get_fill {
  my ($self, $name, $box, @depth) = @_;

  push(@depth, $name);
  my $what;
  if ($name =~ /^(\w+)\.(\w+)$/) {
    $what = $self->{_style}{$1}{$2};
  }
  else {
    $what = $self->{_style}{$name};
  }

  defined($what)
    or return $self->_error("no fill $name found");

  return $self->_translate_fill($what, $box, @depth);
}

=item _make_img()

Builds the image object for the graph and fills it with the background
fill.

=cut

sub _make_img {
  my ($self) = @_;

  my $width = $self->_get_number('width') || 256;
  my $height = $self->_get_number('height') || 256;
  my $channels = $self->{_style}{channels};

  $channels ||= 3;

  my $img = Imager->new(xsize=>$width, ysize=>$height, channels=>$channels);

  $img->box($self->_get_fill('back', [ 0, 0, $width-1, $height-1]));

  $img;
}

sub _get_image {
  my $self = shift;

  if (!$self->{'_image'}) {
    $self->{'_image'} = $self->_make_img();
  }
  return $self->{'_image'};
}

=item _text_style($name)

Returns parameters suitable for calls to Imager::Font's bounding_box()
and draw() methods intended for use in defining text styles.

Returns an empty list on failure.

Returns the following attributes: font, color, size, aa, sizew
(optionally)

=cut

sub _text_style {
  my ($self, $name) = @_;

  my %work;

  if ($self->{_style}{$name}) {
    %work = %{$self->{_style}{$name}};
  }
  else {
    %work = %{$self->{_style}{text}};
  }
  $work{font}
    or return $self->_error("$name has no font parameter");

  $work{font} = $self->_get_thing("$name.font")
    or return $self->_error("No $name.font defined, either set $name.font or font to a font");
  UNIVERSAL::isa($work{font}, "Imager::Font")
      or return $self->_error("$name.font is not a font");
  if ($work{color} && !ref $work{color}) {
    $work{color} = $self->_get_color("$name.color")
      or return;
  }
  $work{size} = $self->_get_number("$name.size");
  $work{sizew} = $self->_get_number("$name.sizew")
    if $work{sizew};
  $work{aa} = $self->_get_number("$name.aa");

  %work;
}

=item _text_bbox($text, $name)

Returns a bounding box for the specified $text as styled by $name.

Returns an empty list on failure.

=cut

sub _text_bbox {
  my ($self, $text, $name) = @_;

  my %text_info = $self->_text_style($name)
    or return;

  my @bbox = $text_info{font}->bounding_box(%text_info, string=>$text,
                                            canon=>1);

  return @bbox[0..3];
}

=item _line_style($name)

Return parameters suitable for calls to Imager's line(), polyline(),
and box() methods.

For now this returns only color and aa parameters, but future releases
of Imager may support extra parameters.

=cut

sub _line_style {
  my ($self, $name) = @_;

  my %line;
  $line{color} = $self->_get_color("$name.line")
    or return;
  $line{aa} = $self->_get_number("$name.lineaa");
  defined $line{aa} or $line{aa} = $self->_get_number("aa");

  return %line;
}

sub _align_box {
  my ($self, $box, $chart_box, $name) = @_;

  my $halign = $self->{_style}{$name}{halign}
    or $self->_error("no halign for $name");
  my $valign = $self->{_style}{$name}{valign};

  if ($halign eq 'right') {
    $box->[0] += $chart_box->[2] - $box->[2];
  }
  elsif ($halign eq 'left') {
    $box->[0] = $chart_box->[0];
  }
  elsif ($halign eq 'center' || $halign eq 'centre') {
    $box->[0] = ($chart_box->[0] + $chart_box->[2] - $box->[2])/2;
  }
  else {
    return $self->_error("invalid halign $halign for $name");
  }

  if ($valign eq 'top') {
    $box->[1] = $chart_box->[1];
  }
  elsif ($valign eq 'bottom') {
    $box->[1] = $chart_box->[3] - $box->[3];
  }
  elsif ($valign eq 'center' || $valign eq 'centre') {
    $box->[1] = ($chart_box->[1] + $chart_box->[3] - $box->[3])/2;
  }
  else {
    return $self->_error("invalid valign $valign for $name");
  }
  $box->[2] += $box->[0];
  $box->[3] += $box->[1];
}

sub _remove_box {
  my ($self, $chart_box, $object_box) = @_;

  my $areax;
  my $areay;
  if ($object_box->[0] - $chart_box->[0] 
      < $chart_box->[2] - $object_box->[2]) {
    $areax = ($object_box->[2] - $chart_box->[0]) 
      * ($chart_box->[3] - $chart_box->[1]);
  }
  else {
    $areax = ($chart_box->[2] - $object_box->[0]) 
      * ($chart_box->[3] - $chart_box->[1]);
  }

  if ($object_box->[1] - $chart_box->[1] 
      < $chart_box->[3] - $object_box->[3]) {
    $areay = ($object_box->[3] - $chart_box->[1]) 
      * ($chart_box->[2] - $chart_box->[0]);
  }
  else {
    $areay = ($chart_box->[3] - $object_box->[1]) 
      * ($chart_box->[2] - $chart_box->[0]);
  }

  if ($areay < $areax) {
    if ($object_box->[1] - $chart_box->[1] 
        < $chart_box->[3] - $object_box->[3]) {
      $chart_box->[1] = $object_box->[3];
    }
    else {
      $chart_box->[3] = $object_box->[1];
    }
  }
  else {
    if ($object_box->[0] - $chart_box->[0] 
        < $chart_box->[2] - $object_box->[2]) {
      $chart_box->[0] = $object_box->[2];
    }
    else {
      $chart_box->[2] = $object_box->[0];
    }
  }
}

sub _draw_legend {
  my ($self, $img, $labels, $chart_box) = @_;

  my $orient = $self->_get_thing('legend.orientation');
  defined $orient or $orient = 'vertical';

  if ($orient eq 'vertical') {
    return $self->_draw_legend_vertical($img, $labels, $chart_box);
  }
  elsif ($orient eq 'horizontal') {
    return $self->_draw_legend_horizontal($img, $labels, $chart_box);
  }
  else {
    return $self->_error("Unknown legend.orientation $orient");
  }
}

sub _draw_legend_horizontal {
  my ($self, $img, $labels, $chart_box) = @_;

  defined(my $padding = $self->_get_integer('legend.padding'))
    or return;
  my $patchsize = $self->_get_integer('legend.patchsize')
    or return;
  defined(my $gap = $self->_get_integer('legend.patchgap'))
    or return;

  my $minrowsize = $patchsize + $gap;
  my ($width, $height) = (0,0);
  my $row_height = $minrowsize;
  my $pos = 0;
  my @sizes;
  my @offsets;
  for my $label (@$labels) {
    my @text_box = $self->_text_bbox($label, 'legend')
      or return;
    push(@sizes, \@text_box);
    my $entry_width = $patchsize + $gap + $text_box[2];
    if ($pos == 0) {
      # never re-wrap the first entry
      push @offsets, [ 0, $height ];
    }
    else {
      if ($pos + $gap + $entry_width > $chart_box->[2]) {
        $pos = 0;
        $height += $row_height;
      }
      push @offsets, [ $pos, $height ];
    }
    my $entry_right = $pos + $entry_width;
    $pos += $gap + $entry_width;
    $entry_right > $width and $width = $entry_right;
    if ($text_box[3] > $row_height) {
      $row_height = $text_box[3];
    }
  }
  $height += $row_height;
  my @box = ( 0, 0, $width + $padding * 2, $height + $padding * 2 );
  my $outsidepadding = 0;
  if ($self->{_style}{legend}{border}) {
    defined($outsidepadding = $self->_get_integer('legend.outsidepadding'))
      or return;
    $box[2] += 2 * $outsidepadding;
    $box[3] += 2 * $outsidepadding;
  }
  $self->_align_box(\@box, $chart_box, 'legend')
    or return;
  if ($self->{_style}{legend}{fill}) {
    $img->box(xmin=>$box[0]+$outsidepadding, 
              ymin=>$box[1]+$outsidepadding, 
              xmax=>$box[2]-$outsidepadding, 
              ymax=>$box[3]-$outsidepadding,
             $self->_get_fill('legend.fill', \@box));
  }
  $box[0] += $outsidepadding;
  $box[1] += $outsidepadding;
  $box[2] -= $outsidepadding;
  $box[3] -= $outsidepadding;
  my %text_info = $self->_text_style('legend')
    or return;
  my $patchborder;
  if ($self->{_style}{legend}{patchborder}) {
    $patchborder = $self->_get_color('legend.patchborder')
      or return;
  }
  
  my $dataindex = 0;
  for my $label (@$labels) {
    my ($left, $top) = @{$offsets[$dataindex]};
    $left += $box[0] + $padding;
    $top += $box[1] + $padding;
    my $textpos = $left + $patchsize + $gap;
    my @patchbox = ( $left, $top,
                     $left + $patchsize, $top + $patchsize );
    my @fill = $self->_data_fill($dataindex, \@patchbox)
      or return;
    $img->box(xmin=>$left, ymin=>$top, xmax=>$left + $patchsize,
               ymax=>$top + $patchsize, @fill);
    if ($self->{_style}{legend}{patchborder}) {
      $img->box(xmin=>$left, ymin=>$top, xmax=>$left + $patchsize,
                ymax=>$top + $patchsize,
                color=>$patchborder);
    }
    $img->string(%text_info, x=>$textpos, 'y'=>$top + $patchsize, 
                 text=>$label);

    ++$dataindex;
  }
  if ($self->{_style}{legend}{border}) {
    my $border_color = $self->_get_color('legend.border')
      or return;
    $img->box(xmin=>$box[0], ymin=>$box[1], xmax=>$box[2], ymax=>$box[3],
              color=>$border_color);
  }
  $self->_remove_box($chart_box, \@box);
  1;
}

sub _draw_legend_vertical {
  my ($self, $img, $labels, $chart_box) = @_;

  defined(my $padding = $self->_get_integer('legend.padding'))
    or return;
  my $patchsize = $self->_get_integer('legend.patchsize')
    or return;
  defined(my $gap = $self->_get_integer('legend.patchgap'))
    or return;
  my $minrowsize = $patchsize + $gap;
  my ($width, $height) = (0,0);
  my @sizes;
  for my $label (@$labels) {
    my @box = $self->_text_bbox($label, 'legend')
      or return;
    push(@sizes, \@box);
    $width = $box[2] if $box[2] > $width;
    if ($minrowsize > $box[3]) {
      $height += $minrowsize;
    }
    else {
      $height += $box[3];
    }
  }
  my @box = (0, 0, 
             $width + $patchsize + $padding * 2 + $gap,
             $height + $padding * 2 - $gap);
  my $outsidepadding = 0;
  if ($self->{_style}{legend}{border}) {
    defined($outsidepadding = $self->_get_integer('legend.outsidepadding'))
      or return;
    $box[2] += 2 * $outsidepadding;
    $box[3] += 2 * $outsidepadding;
  }
  $self->_align_box(\@box, $chart_box, 'legend')
    or return;
  if ($self->{_style}{legend}{fill}) {
    $img->box(xmin=>$box[0]+$outsidepadding, 
              ymin=>$box[1]+$outsidepadding, 
              xmax=>$box[2]-$outsidepadding, 
              ymax=>$box[3]-$outsidepadding,
             $self->_get_fill('legend.fill', \@box));
  }
  $box[0] += $outsidepadding;
  $box[1] += $outsidepadding;
  $box[2] -= $outsidepadding;
  $box[3] -= $outsidepadding;
  my $ypos = $box[1] + $padding;
  my $patchpos = $box[0]+$padding;
  my $textpos = $patchpos + $patchsize + $gap;
  my %text_info = $self->_text_style('legend')
    or return;
  my $patchborder;
  if ($self->{_style}{legend}{patchborder}) {
    $patchborder = $self->_get_color('legend.patchborder')
      or return;
  }
  my $dataindex = 0;
  for my $label (@$labels) {
    my @patchbox = ( $patchpos - $patchsize/2, $ypos - $patchsize/2,
                     $patchpos + $patchsize * 3 / 2, $ypos + $patchsize*3/2 );

    my @fill;
    if ($self->_draw_flat_legend()) {
      @fill = (color => $self->_data_color($dataindex), filled => 1);
    }
    else {
      @fill = $self->_data_fill($dataindex, \@patchbox)
        or return;
    }
    $img->box(xmin=>$patchpos, ymin=>$ypos, xmax=>$patchpos + $patchsize,
               ymax=>$ypos + $patchsize, @fill);
    if ($self->{_style}{legend}{patchborder}) {
      $img->box(xmin=>$patchpos, ymin=>$ypos, xmax=>$patchpos + $patchsize,
                ymax=>$ypos + $patchsize,
                color=>$patchborder);
    }
    $img->string(%text_info, x=>$textpos, 'y'=>$ypos + $patchsize, 
                 text=>$label);

    my $step = $patchsize + $gap;
    if ($minrowsize < $sizes[$dataindex][3]) {
      $ypos += $sizes[$dataindex][3];
    }
    else {
      $ypos += $minrowsize;
    }
    ++$dataindex;
  }
  if ($self->{_style}{legend}{border}) {
    my $border_color = $self->_get_color('legend.border')
      or return;
    $img->box(xmin=>$box[0], ymin=>$box[1], xmax=>$box[2], ymax=>$box[3],
              color=>$border_color);
  }
  $self->_remove_box($chart_box, \@box);
  1;
}

sub _draw_title {
  my ($self, $img, $chart_box) = @_;

  my $title = $self->{_style}{title}{text};
  my @box = $self->_text_bbox($title, 'title')
    or return;
  my $yoff = $box[1];
  @box[0,1] = (0,0);
  $self->_align_box(\@box, $chart_box, 'title');
  my %text_info = $self->_text_style('title')
    or return;
  $img->string(%text_info, x=>$box[0], 'y'=>$box[3] + $yoff, text=>$title);
  $self->_remove_box($chart_box, \@box);
  1;
}

sub _small_extent {
  my ($self, $box) = @_;

  if ($box->[2] - $box->[0] > $box->[3] - $box->[1]) {
    return $box->[3] - $box->[1];
  }
  else {
    return $box->[2] - $box->[0];
  }
}

sub _draw_flat_legend {
  return 0;
}

=item _composite()

Returns a list of style fields that are stored as composites, and
should be merged instead of just being replaced.

=cut

sub _composite {
  qw(title legend text label dropshadow outline callout);
}

sub _filter_region {
  my ($self, $img, $left, $top, $right, $bottom, $filter) = @_;

  unless (ref $filter) {
    my $name = $filter;
    $filter = $self->_get_thing($name)
      or return;
    $filter->{type}
      or return $self->_error("no type for filter $name");
  }

  $left > 0 or $left = 0;
  $top > 0 or $top = 0;

  # newer versions of Imager let you work on just part of an image
  if ($img->can('masked') && !$self->{_style}{features}{_debugblur}) {
    my $masked = $img->masked(left=>$left, top=>$top,
                              right=>$right, bottom=>$bottom);
    $masked->filter(%$filter);
  }
  else {
    # for older versions of Imager
    my $subset = $img->crop(left=>$left, top=>$top,
                            right=>$right, bottom=>$bottom);
    $subset->filter(%$filter);
    $img->paste(left=>$left, top=>$top, img=>$subset);
  }
}

1;
__END__

=back

=head1 SEE ALSO

Imager::Graph::Pie(3), Imager(3), perl(1).

=head1 AUTHOR

Tony Cook <tony@develop-help.com>

=head1 LICENSE

Imager::Graph is licensed under the same terms as perl itself.

=head1 BLAME

Addi for producing a cool imaging module. :)

=cut
