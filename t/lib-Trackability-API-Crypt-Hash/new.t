use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../lib";
use Trackability::API::Test skip_db => 1;

my $class = 'Trackability::API::Crypt::Hash';
use_ok( $class );

HAPPY_PATH: {
    note( 'happy path' );

    my $crypt = Trackability::API::Crypt::Hash->new();

    isa_ok( $crypt, $class );

    my @methods = qw(
        generate
        validate
    );

    can_ok( $class, $_ ) foreach @methods;
}

done_testing();
