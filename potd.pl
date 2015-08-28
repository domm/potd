#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;
use Imager;
use Path::Class;
use File::Copy;
use Time::Moment;
use File::HomeDir;
use Image::ExifTool qw(:Public);

my $raw = file( $ARGV[0] );
die "No such file $ARGV[0]" unless -e $raw;

my $day_offset = defined $ARGV[1] ? $ARGV[1] : 1;
my $date      = Time::Moment->now->plus_days($day_offset);
my $basename   = $date->strftime("%Y-%m-%d");
say "Creating POTD for $basename, ok?";
my $ok = <STDIN>;

my $home     = dir( File::HomeDir->my_home );
my $blio = $home->subdir(qw(privat domm.plix.at));
my $potd_src = $blio->subdir(qw( src potd ));
my $target_img = $potd_src->file( $basename . '.jpg' );
my $target_txt = $potd_src->file( $basename . '.txt' );
if ( -e $target_img ) {
    say "target $basename.jpg already exists, aborting";
    exit;
}

my $image = Imager->new;
$image->read( file => $raw );

my $exif = ImageInfo($raw->stringify);
if ($exif->{Orientation} && $exif->{Orientation} =~ /(\d+)/) {
    my $degrees = $1;
    my $rotated = $image->rotate(right=>$degrees);
    say "Rotating image $degrees right";
    $image = $rotated;
}

my $scaled = $image->scale( xpixels => 800 );
$scaled->write( file => $target_img );

move( $raw,
    $home->subdir(qw(media fotos 2015 potd))->file( $basename . '.jpg' ) );

my $publish_date = $basename . 'T10:00:00';
$target_txt->spew(
    <<EOBLIO
title: 
tweet: 
date: $publish_date
converter: textile
template: potd.tt

EOBLIO
);
system("vim $target_txt");

chdir( $target_img->parent );
system( join( ' ', 'git add ', $target_img, $target_txt ) );
system("git commit -m 'potd $basename'");
system('git push');

chdir( $blio );
say "starting to build local website";
system('./build_t430 --nosched > /dev/null');
say "done building local website";

