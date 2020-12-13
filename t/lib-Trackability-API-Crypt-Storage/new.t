use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../lib", "$FindBin::RealBin/../../lib";
use Trackability::API::Test;

my $class = 'Trackability::API::Crypt::Storage';
use_ok( $class );

CONSTRUCTOR: {
    note( 'constructor' );

    my $crypt = $class->new( secret_key => 'test' );
    isa_ok( $crypt, $class );

    my @methods = qw(
        encode
        decode
    );

    can_ok( $class, $_ ) foreach @methods;

    ok( exists $crypt->{_store_obj}, 'object contains _store_obj key' );
}

EXCEPTIONS: {
    note( 'exceptions' );

    dies_ok( sub { $class->new() },
             "dies if secret_key is not passed" );
    like $@, qr/secret_key argument is required/, "message matches expected string";
}

done_testing();
