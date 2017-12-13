#!perl
use strict;
use warnings;

use Path::Tiny qw( path tempdir );    # dev-perl/Path-Tiny
use Term::ANSIColor qw( colored colorstrip );

sub einfo;
sub eerror;
sub ewarn;
sub green;
sub red;
sub yellow;

if ( not $ENV{PATCH_LEVEL} ) {
    eerror yellow("PATCH_LEVEL") . " must be specified in " . yellow("ENV");
}

my $target_url = extract_target_url('./.travis.yml');
my $url_meta   = parse_url($target_url);

my $output_name = "perl-$url_meta->{version}-patches-$ENV{PATCH_LEVEL}";
my $tar_name    = "$output_name.tar";
my $comp_name   = "$tar_name.xz";
my (@targets)   = "patches/";

einfo "Using " . green($comp_name) . " for tarball";

if ( path($comp_name)->exists ) {
    eerror "Path " . red($comp_name) . " already exists";
}

my $tempdir = tempdir( TEMPLATE => "make_release.XXXXXXX" );

einfo "Archiving "
  . green("@targets") . " to "
  . green( path( $tempdir, $tar_name ) );
system(
    'tar',           '-cf',           path( $tempdir, $tar_name ),
    '--sort=name',   '--no-xattrs',   '--no-acls',
    '--no-selinux',  '--exclude-vcs', '--exclude-vcs-ignores',
    '--dereference', '-v',            '--totals',
    @targets
  ) == 0
  or eerror "tar did not exit cleanly, $? $!";

einfo "Compressing "
  . green( path( $tempdir, $tar_name ) ) . "\n"
  . "           to "
  . green( path( $tempdir, $comp_name ) );

delete $ENV{XZ_DEFAULTS};
system(
    'xz', '-vv9e',
    '--memlimit-compress=5G',
    '--lzma2=dict=512KiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=2048',
    '--memlimit-decompress=1M',    # low threshold for decompressing.
    '-k',
    path( $tempdir, $tar_name )
  ) == 0
  or eerror "xz did not exit cleanly, $? $!";

einfo "Copying "
  . green( path( $tempdir, $comp_name ) ) . "\n"
  . "       to "
  . green( path( '.', $comp_name ) );

path( $tempdir, $comp_name )->copy( path( '.', $comp_name ) );

sub green  { colored( ['bold green'],  $_[0] ) }
sub red    { colored( ['bold red'],    $_[0] ) }
sub yellow { colored( ['bold yellow'], $_[0] ) }
sub einfo  { warn green("*") . " " . $_[0] . "\n" }
sub ewarn  { warn yellow("*") . " " . $_[0] . "\n" }

sub eerror {
    warn red("*") . " " . $_[0] . "\n";
    die colorstrip $_[0];
}

sub extract_target_url {
    my ($file) = @_;
    for my $line ( path($file)->lines_raw( { chomp => 1 } ) ) {
        next unless $line =~ /TARGET_PERL=(.+?)\s*\z/;
        return "$1";
    }
    eerror "Can't find " . yellow("TARGET_PERL=") . " in " . yellow($file);
}

sub parse_url {
    my ($url) = @_;
    if ( $url =~ qr{authors/id/(.)/(..)/(.+)/perl-(.*?)\.tar\.([^.]+)\z} ) {
        return {
            author  => "$3",
            version => "$4",
            ext     => "$5"
        };
    }
    eerror "Can't extract "
      . yellow("author/version/ext")
      . " from url "
      . yellow($url);
}
