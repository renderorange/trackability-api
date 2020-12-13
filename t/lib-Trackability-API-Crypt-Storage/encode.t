use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../lib", "$FindBin::RealBin/../../lib";
use Trackability::API::Test;

my $class = 'Trackability::API::Crypt::Storage';
use_ok( $class );

HAPPY_PATH: {
    note( 'happy path' );

    my $string = 'foo';

    my $crypt = $class->new( secret_key => $string );
    my $encoded = $crypt->encode( string => 'fooz' );

    unlike( $encoded, qr/$string/, 'returned string is encoded' );
}

EXCEPTIONS: {
    note( 'exceptions' );

    my $crypt = $class->new( secret_key => 'foo' );

    dies_ok( sub { $crypt->encode() }, "dies if string is not passed" );
    like $@, qr/string argument is required/, "message matches expected string";
}

done_testing();
