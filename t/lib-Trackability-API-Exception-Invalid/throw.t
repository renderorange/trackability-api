use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../lib";
use Trackability::API::Test skip_db => 1;

use Test::Exception;

my $class = 'Trackability::API::Exception::Invalid';
use_ok( $class );

HAPPY_PATH: {
    note( 'happy path' );

    dies_ok( sub { $class->throw( message => 'death' ) }, 'dies when throw is run' );
    throws_ok { $class->throw( message => 'death' ) } $class, "exception isa $class";
    like $@, qr/death/, "message matches expected string";
}

done_testing();
