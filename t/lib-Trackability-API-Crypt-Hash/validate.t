use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../lib";
use Trackability::API::Test skip_db => 1;

use Test::Exception;

my $class = 'Trackability::API::Crypt::Hash';
use_ok( $class );

HAPPY_PATH: {
    note( 'happy path' );

    my $string = 'foo';

    my $crypt = Trackability::API::Crypt::Hash->new();
    my $hash = $crypt->generate( string => $string );

    ok( $crypt->validate( hash => $hash, string => $string ), 'string validates as true' );
}

EXCEPTIONS: {
    note( 'exceptions' );

    my $crypt = Trackability::API::Crypt::Hash->new();

    foreach my $required ( 'string', 'hash' ) {
        dies_ok( sub { $crypt->validate( $required => 'fake' ) },
                 "dies if $required is not passed" );
        like $@, qr/[string|hash] is required/, "message matches expected string";
    }
}

done_testing();
