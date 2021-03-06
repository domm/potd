#!/home/domm/rakudo-star-2016.07/install/bin/perl6

# take an jpg and maybe an --offset
# rename the file to YYYY-MM-DD.jpg
# create a textfile with a similar name at the right location
# open the textfile for editing in vim
# call an Perl5 script that will resize the image and rotate it (if EXIF says so)
#    (no idea if this could be done in Perl6)
# issue some git-commands to upload the new files
# maybe issue some commands to rebuild the website on the local machine (if --local)

# more info:
#  http://domm.plix.at/perl/2015_01_potd_helper_script.html
#  http://domm.plix.at/talks/2015_dresden_potd/

sub MAIN ( $file, Int :$offset = 1, Bool :$local ) {
    die "No such file $file" unless $file.IO.e;

    my $date = Date.today + $offset;

    my $ok = prompt "Creating POTD for $date, ok? ";
    exit if $ok ~~ m:i/^n/;

    my $home       = '/home/domm'.IO;
    my $blio       = $home.child( 'privat/domm.plix.at' );
    my $target_img = $blio.child( 'src/potd/' ~ $date ~ '.jpg' );
    my $target_txt = $blio.child( 'src/potd/' ~ $date ~ '.txt' );
    my $archive    = '/mp3/fotos/2016/potd/' ~ $date ~ '.jpg';

    my $template = template( $date );
    spurt $target_txt, $template, :createonly;
    shell "vim $target_txt";

    shell "potd_handle_image.pl $file $target_img $archive";

    publish( $target_img, $target_txt, $date );

    build_local( $blio ) if $local;
}

sub template ( Date $date ) {
    my $publish_datetime = $date ~ 'T10:00:00+02';
    return qq:to/EOBLIO/;
    title: 
    tweet: 
    date: $publish_datetime
    converter: textile
    template: potd.tt
    
    
    EOBLIO
}

sub publish ( $target_img, $target_txt, $basename ) {
   chdir $target_img.dirname;
   my @commands =
       "git add $target_img $target_txt",
       "git commit -m 'potd $basename'",
       "git push";
   for @commands -> $command {
      shell $command;
   }
}

sub build_local ( $blio ) {
   chdir $blio;
   say   "starting to build local website";
   shell './build_t430 --nosched > /dev/null';
   say   "done building local website";
}

