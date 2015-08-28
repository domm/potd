#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use File::Copy;
use Imager;
use Image::ExifTool qw(:Public);

my ($src, $target, $archive) = @ARGV;

my $image = Imager->new;
$image->read( file => $src );

my $exif = ImageInfo($src);
if ($exif->{Orientation} && $exif->{Orientation} =~ /(\d+)/) {
    my $degrees = $1;
    my $rotated = $image->rotate(right=>$degrees);
    say "Rotating image $degrees right";
    $image = $rotated;
}

my $scaled = $image->scale( xpixels => 800 );
$scaled->write( file => $target );

move( $src, $archive);

