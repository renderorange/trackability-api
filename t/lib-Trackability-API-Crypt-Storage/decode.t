use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../lib", "$FindBin::RealBin/../../lib";
use Trackability::API::Test;

my $class = 'Trackability::API::Crypt::Storage';
use_ok( $class );

my $secret_key = 'foo';
my $string = 'shhh';

HAPPY_PATH: {
    note( 'happy path' );

    my $crypt = $class->new( secret_key => $secret_key );
    my $encoded = $crypt->encode( string => $string );
    is( $crypt->decode( string => $encoded ), $string, 'decoded string returns the expected string' );

    $crypt = $class->new( secret_key => $secret_key . 'oz' );
    ok( !$crypt->decode( string => $encoded ), 'not decoded string returns undef' );
}

EXCEPTIONS: {
    note( 'exceptions' );

    my $crypt = $class->new( secret_key => $secret_key );

    dies_ok( sub { $crypt->encode() }, "dies if string is not passed" );
    like $@, qr/string argument is required/, "message matches expected string";
}

done_testing();
