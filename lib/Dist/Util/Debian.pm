package Dist::Util::Debian;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       dist_has_deb
               );

sub dist_has_deb {
    require HTTP::Tiny;

    my $dist = shift;
    my $deb = "lib" . lc($dist) . "-perl";

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

1;
# ABSTRACT: Utilities related to Perl distribution and Debian

=head1 SYNOPSIS

 use Dist::Util::Debian qw(
     dist_has_deb
 );

 say dist_has_deb("HTTP-Tiny"); # -> 1
 say dist_has_deb("Foo");       # -> 0


=head1 DESCRIPTION


=head1 FUNCTIONS

=head2 dist_has_deb($dist) => bool

Return true if distribution named C<$dist> has a corresponding Debian package.
Currently the way the routine checks this is rather naive: it converts C<$dist>
to Debian package name by turning it to lowercase and adds "lib" + "-perl"
prefix and suffix (a small percentage of distributions do not follow this rule).
Then it checks against this URL: L<https://packages.debian.org/sid/$package>.

Will warn and return undef on error, e.g. the URL cannot be checked or does not
contain negative/positive indicator of existence.
