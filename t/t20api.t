#!perl -w
use strict;
use Imager::Graph::Pie;
use lib 't/lib';
use Imager::Font::Test;
use Test::More;

++$|;

use Imager qw(:handy);

plan tests => 3;

#my $fontfile = 'ImUgly.ttf';
#my $font = Imager::Font->new(file=>$fontfile, type => 'ft2', aa=>1)
#  or plan skip_all => "Cannot create font object: ",Imager->errstr,"\n";
my $font = Imager::Font::Test->new();

my @data = ( 100, 180, 80, 20, 2, 1, 0.5 );
my @labels = qw(alpha beta gamma delta epsilon phi gi);

my $api_pie = Imager::Graph::Pie->new();

$api_pie->addDataSeries(\@data, 'Demo series');
$api_pie->setFont($font);
$api_pie->setLabels(\@labels);
$api_pie->setGraphSize(50);
$api_pie->setImageWidth(200);
$api_pie->setImageHeight(200);
$api_pie->setTitle('Test 20');
$api_pie->setStyle('fount_rad');

my $api_img = $api_pie->draw();
ok($api_img);

my $data_pie = Imager::Graph::Pie->new();

my $data_img = $data_pie->draw(
                                data    => \@data,
                                labels  => \@labels,
                                font    => $font,
                                title   => { text => 'Test 20' },
                                style   => 'fount_rad',
                                size    => 50,
                                width   => 200,
                                height  => 200,
                              );


ok($data_img);

my ($api_content, $data_content);

$data_img->write(data => \$data_content, type=>'tiff', tiff_compression => 'none') or die "Err: ".$data_img->errstr;
$api_img->write(data  => \$api_content,  type=>'tiff', tiff_compression => 'none') or die "Err: ".$api_img->errstr;

ok($data_content eq $api_content);


