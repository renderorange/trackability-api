use strict;
use warnings;

use Test::More;

my @required_modules = qw{
    Config::Tiny
    Cwd
    Dancer2
    Data::Structure::Util
    DBI
    HTTP::Status
    Moo
    Plack
    Plack::Builder
    Plack::Loader::Shotgun
    Plack::Middleware::TrailingSlashKiller
    Scalar::Util
    Starman
    strictures
    Throwable::Error
};

foreach my $required ( @required_modules ) {
    use_ok($required) or BAIL_OUT("required module $required cannot be loaded");
};

done_testing;
