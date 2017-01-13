#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Dist::Util::Debian qw(dist2deb deb_exists dist_has_deb);

is(dist2deb("HTTP-Tiny"), "libhttp-tiny-perl");

done_testing;
