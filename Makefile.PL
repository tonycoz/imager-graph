# Imager::Graph
use ExtUtils::MakeMaker;
my %opts;
if ($] ge '5.005') {
  $opts{AUTHOR} = 'Tony Cook <tony@develop-help.com>';
  $opts{ABSTRACT} = 'Draws good looking pie graphs';
}

WriteMakefile(
              %opts,
              'NAME'          => 'Imager::Graph',
              'VERSION_FROM'  => 'Graph.pm', # finds $VERSION
              PREREQ_PM       => { Imager=>'0.38' },
              clean => { FILES=>'testout' },
);
