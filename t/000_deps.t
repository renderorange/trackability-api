use strict;
use warnings;

use Test::More;

my @required_modules = qw{
    Config::Tiny
    constant
    Cwd
    Crypt::PBKDF2
    Dancer2
    Data::Structure::Util
    DBI
    Digest::SHA
    Email::Valid
    FindBin
    Getopt::Long
    HTTP::Status
    JSON::Parse
    List::MoreUtils
    Moo
    MooX::ClassAttribute
    namespace::clean
    Plack
    Plack::Builder
    Plack::Loader::Shotgun
    Plack::Middleware::TrailingSlashKiller
    Pod::Usage
    Scalar::Util
    Session::Storage::Secure
    Starman
    strictures
    Throwable::Error
    Try::Tiny
    Types::Common::Numeric
    Types::Common::String
};

foreach my $required ( @required_modules ) {
    use_ok($required) or BAIL_OUT("required module $required cannot be loaded");
};

done_testing;
