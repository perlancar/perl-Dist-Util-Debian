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

    my $opts = ref($_[0]) eq 'HASH' ? shift : {};

    if ($opts->{use_allpackages}) {
        require File::Slurper::Temp;
        require File::Util::Tempdir;
        require IO::Uncompress::Gunzip;
        my $url  = "https://packages.debian.org/unstable/allpackages?format=txt.gz";
        my $path = File::Util::Tempdir::get_tempdir() . "/allpackages.txt";
        my @stat = stat($path);
        unless (@stat && $stat[9] > time() - 86400) {
            my $res = HTTP::Tiny->new->get($url);
            unless ($res->{success}) {
                warn "Can't download $url: $res->{status} - $res->{reason}";
                return undef;
            }
            my $uncompressed = "";
            IO::Uncompress::Gunzip::gunzip(\($res->{content}), \$uncompressed)
                  or die "gunzip failed: $IO::Uncompress::Gunzip::GunzipError";
            File::Slurper::Temp::write_text($path, $uncompressed);
        }
        my %res;
        my $re = join("|", map { quotemeta($_) } @_); $re = qr/^($re) \(/;
        open my($fh), "<", $path or die "Can't open $path: $!";
        while (defined(my $line = <$fh>)) {
            if ($line =~ $re) {
                $res{$1} = 1;
            }
        }
        return map { $res{$_} ? 1:0 } @_;
    } else {
        my @res;
        for my $deb (@_) {
            my $url = "https://packages.debian.org/sid/$deb";
            my $res = HTTP::Tiny->new->get($url);
            unless ($res->{success}) {
                warn "Can't check $url: $res->{status} - $res->{reason}";
                push @res, undef;
                next;
            }
            if ($res->{content} =~ /No such package/) {
                push @res, 0;
                next;
            } elsif ($res->{content} =~ /Package: \Q$deb\E \(/) {
                push @res, 1;
                next;
            } else {
                warn "Can't understand the content of $url, no indication of ".
                    "package exists or doesn't exist";
                push @res, undef;
                next;
            }
        }
        return @res;
    }
}

sub dist_has_deb {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};

    deb_exists($opts, map { dist2deb($_) } @_);
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

=head2 dist2deb($dist, ...) => list

It uses the simple rule of turning C<$dist> to lowercase and adds "lib" +
"-perl" prefix and suffix. A small percentage of distributions do not follow
this rule.

=head2 deb_exists([ \%opts, ] $deb) => bool

=head2 dist_has_deb([ \%opts, ] $dist, ...) => bool|list

Return true if distribution named C<$dist> has a corresponding Debian package.
Currently the way the routine checks this is rather naive: it checks the
corresponding Debian package against this URL:
L<https://packages.debian.org/sid/$package>.

Will warn and return undef on error, e.g. the URL cannot be checked or does not
contain negative/positive indicator of existence.

Can accept multiple dists and will return a list of bools in that case.

Known options:

=over

=item * use_allpackages => bool

If you need to check a lot of distributions (hundreds or more) then the default
way of checking each distribution against a URL might be too slow. An
alternative way, enabled if you set this option to true, is to download
L<https://packages.debian.org/unstable/allpackages?format=txt.gz> (at the time
of this writing, Jan 2017, the size is about 1.7M) then parse it locally. The
file will be cached to a temporary file and reused for a day.

Function will return undef if the allpackages index cannot be donwloaded.

=back
