#!perl
use strict;
use warnings;

BEGIN {
    require Cwd;
    my $cwd = Cwd::cwd();
    *cwd = sub {
        @_ ? $cwd . '/' . ( join q[/], @_ ) : $cwd . '/';
    };
}

my (@patches) = get_patches_in( cwd("patches") );
for my $patch (@patches) {
    extract_info( cwd("patches"), $patch, cwd("patch-info") );
}

use Data::Dump qw(pp);
pp \@patches;

sub vcmp {
    my ( $left, $right ) = @_;

    my ( $ld, $lr ) = ( 0, $left );
    my ( $rd, $rr ) = ( 0, $right );

    if ( $left =~ /\A([\d.]+)(.*?)\z/ ) {
        $ld = $1 + 0;
        $lr = $2;
    }
    if ( $right =~ /\A([\d.]+)(.*?)\z/ ) {
        $rd = $1 + 0;
        $rr = $2;
    }
    ( $ld <=> $rd ) || ( $lr cmp $rr );
}

sub get_patches_in {
    my ($dir) = @_;
    my (@patches);
    opendir my $dfh, $dir || die "Can't opendir $dir, $!";
    while ( my $file = readdir $dfh ) {
        next if $file eq '.' or $file eq '..';
        next unless $file =~ /\.(diff|patch)\z/;
        next if -d "$dir/$file";
        push @patches, $file;
    }
    sort { vcmp( $a, $b ) } @patches;
}

sub extract_info {
    my ( $idir, $ipatch, $odir ) = @_;
  
    STDERR->printf("\e[32m*\e[0m Extracting \e[1m%s/\e[0m\e[34m%s\e[0m\n", $idir, $ipatch);
    STDERR->printf("\e[32m*\e[0m       and: \e[1m%s/\e[0m\e[34m%s.desc\e[0m\n", $odir, $ipatch);
    STDERR->printf("\e[32m*\e[0m       and: \e[1m%s/\e[0m\e[34m%s.bugs\e[0m\n", $odir, $ipatch);
    my $info = parse_patch("$idir/$ipatch");
    if ( $info->{subject} ) {
      if ( ! -d "$odir" ) {
        mkdir "$odir" || die "Can't mkdir $odir, $!";
      }
      open my $fh, ">", "$odir/$ipatch.desc" or die "Can't write to $odir/$ipatch.desc, $!";
      $fh->print($info->{subject});
         close $fh or warn "can't close fh for $ipatch.desc, $!";
    }
    if ( $info->{bugs} ) {
        my $bugs = join q[, ], sort @{$info->{bugs}};
        open my $fh, ">", "$odir/$ipatch.bugs" or die "Can't write to $odir/$ipatch.bugs, $!";
        my (%seen_bug);
        for my $bug ( sort @{$info->{bugs}} ) {
          next if exists $seen_bug{$bug};
          $fh->printf("%s\n", $bug);
        }
    }

    1
}

sub parse_patch {
  my ( $patch ) = @_;
  my (%out);
  my $content = do {
    open my $fh, '<', $patch or die "Can't read $patch, $!";
    local $/ = undef;
    scalar <$fh>
  };
  my (@desc) = patch_get_header($content);
  if ( @desc ) {
    $out{subject} = shift @desc;
    $out{subject} =~ s/\[PATCH[^]]+\]//; # strip PATCH leaders
    $out{subject} =~ s/^\s*//;
    $out{subject} =~ s/\s*//;

    for my $line ( @desc ) {
      if ( $line =~ m{^Bug: .*https?://rt\.perl\.org/.*id=(\d+)} ) {
        push @{$out{bugs}}, "https://rt.perl.org/Public/Bug/Display.html?id=" . $1;
      }
      if ( $line =~ m{^Bug: .*https?://rt\.cpan\.org/.*id=(\d+)} ) {
        push @{$out{bugs}}, "https://rt.cpan.org/Public/Bug/Display.html?id=" . $1;
      }
      if ( $line =~ m{https?://bugs\.gentoo\.org/.*id=(\d+)} ) {
        push @{$out{bugs}}, "https://bugs.gentoo.org/" . $1;
      }
      if ( $line =~ m{https?://bugs\.gentoo\.org/(\d+)} ) {
        push @{$out{bugs}}, "https://bugs.gentoo.org/" . $1;
      }
      if ( $line =~ m{https?://bugs\.debian\.org/(\d+)} ) {
        push @{$out{bugs}}, "https://bugs.debian.org/" . $1;
      }
      if ( $line =~ m{^Bug-Gentoo: (\d+)}gm )  {
        push @{$out{bugs}}, "https://bugs.gentoo.org/" . $1;
      }
      if ( $line =~ m{Patch-Name: (.*$)} ) {
        $out{name} = $1;
      }
    }
  }
  pp \%out;
  \%out
}

sub patch_get_header {
  my ( $content ) = @_;
  my (@out);
  my ( @lines ) = split /\n/, $content;
  while (@lines and $lines[0] !~ /^Subject: / ) {
    shift @lines;
  }
  if ( @lines and $lines[0] =~ /^Subject:\s*(.*$)/  ) {
    my $lead = "$1";
    shift @lines;
    while ( @lines and $lines[0] =~ /^( .*)$/ ) {
      $lead .= $1;
      shift @lines;
    }
    push @out, $lead;
  }
  while (@lines and $lines[0] !~ /^---$/ ) {
    push @out, $lines[0];
    shift @lines;
  }
  return @out;
}
1;
