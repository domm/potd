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


use File::HomeDir;

sub MAIN ($file, Int :$offset = 1, Bool :$local) {
    die "No such file $file" unless $file.IO.e;

    my $date = Date.today() + $offset;
    my $basename = "$date";

    my $ok = prompt("Createing POTD for $date, ok? ");

    my $home = File::HomeDir.new.my_home.IO;
    my $blio = $home.child('privat/domm.plix.at');
    my $potd_src = $blio.child('src/potd');
    my $target_img = $potd_src.child( $basename ~ '.jpg' );
    my $target_txt = $potd_src.child( $basename ~ '.txt' );
    my $archive_img = $home.child('media/fotos/2015/potd/' ~ $basename ~ '.jpg');

    if $target_img.e {
        say "target $basename.jpg already exists, aborting";
        exit;
    }

    my $template = post_template( $basename );
    spurt($target_txt, $template);
    shell "vim $target_txt";

    shell "potd_handle_image.pl $file $target_img $archive_img";

    publish($target_img, $target_txt, $basename);

    build_local($blio) if $local;
}

sub post_template(Str $basename) {
    my $publish_date = $basename ~ 'T10:00:00';
    return qq:to/EOBLIO/;
title: 
tweet: 
date: $publish_date
converter: textile
template: potd.tt

EOBLIO
}

sub publish($target_img, $target_txt, $basename) {
   chdir($target_img.dirname);
   my @commands =
       "git add $target_img $target_txt",
       "git commit -m 'potd $basename'",
       "git push";
   for @commands -> $command {
      shell $command;
   }
}

sub build_local($blio) {
   chdir( $blio );
   say "starting to build local website";
   shell './build_t430 --nosched > /dev/null';
   say "done building local website";
}


