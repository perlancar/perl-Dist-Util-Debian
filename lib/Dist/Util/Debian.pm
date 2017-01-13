package Dist::Util::Debian;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       dist2deb
                       deb_exists
                       dist_has_deb
               );

sub dist2deb {
    my $dist = shift;
    return "lib" . lc($dist) . "-perl";
}

sub deb_exists {
    require HTTP::Tiny;

    my $deb = shift;

    my $url = "https://packages.debian.org/sid/$deb";
    my $res = HTTP::Tiny->new->get($url);
    unless ($res->{success}) {
        warn "Can't check $url: $res->{status} - $res->{reason}";
        return undef;
    }
    if ($res->{content} =~ /No such package/) {
        return 0;
    } elsif ($res->{content} =~ /Package: \Q$deb\E \(/) {
        return 1;
    } else {
        warn "Can't understand the content of $url, no indication of package exists or doesn't exist";
        return undef;
    }
}

sub dist_has_deb {
    my $dist = shift;
    my $deb = dist2deb($dist);

    deb_exists($deb);
}

1;
# ABSTRACT: Utilities related to Perl distribution and Debian

=head1 SYNOPSIS

 use Dist::Util::Debian qw(
     dist2deb
     deb_exists
     dist_has_deb
 );

 say dist2deb("HTTP-Tiny"); # -> libhttp-tiny-perl

 say dist_has_deb("HTTP-Tiny"); # -> 1
 say dist_has_deb("Foo");       # -> 0


=head1 DESCRIPTION


=head1 FUNCTIONS

=head2 dist2deb($dist) => str

It uses the simple rule of turning C<$dist> to lowercase and adds "lib" +
"-perl" prefix and suffix. A small percentage of distributions do not follow
this rule.

=head2 deb_exists($deb) => bool

=head2 dist_has_deb($dist) => bool

Return true if distribution named C<$dist> has a corresponding Debian package.
Currently the way the routine checks this is rather naive: it checks the
corresponding Debian package against this URL:
L<https://packages.debian.org/sid/$package>.

Will warn and return undef on error, e.g. the URL cannot be checked or does not
contain negative/positive indicator of existence.

TODO: If one needs to check a lot of distributions (hundreds or more) then the
above way might be too slow and this might be better: Download
L<https://packages.debian.org/unstable/allpackages?format=txt.gz> (at the time
of this writing about 1.7M) then parse it locally.
