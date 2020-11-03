use strict;
use warnings;

BEGIN {
    require FindBin;
    $ENV{DANCER_CONFDIR} = "$FindBin::RealBin/../../app";
    $ENV{DANCER_ENVIRONMENT} = 'development';
}

use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../lib";
use Trackability::API::Test;
use Test::Deep;
use Plack::Test;
use HTTP::Request ();

use Trackability::API ();
use JSON   ();
use Encode ();

use Trackability::API::Model::Users;

my $user_one = Trackability::API::Model::Users->new(
    name => 'user one',
    email => 'user-one@example.com',
);
my $password = 'Testtesttest1';
$user_one->store();
$user_one->store_password( password => $password );
$user_one->store();

my $method   = 'OPTIONS';
my $endpoint = '/users/1';

my $app  = Trackability::API->to_app;
my $test = Plack::Test->create( $app );

my $request = HTTP::Request->new( $method, $endpoint );
my $response = $test->request( $request );

ok( $response->is_success, sprintf( '%s %s was successful', $method, $endpoint ) );
is( $response->headers->{allow}, 'GET,PUT,OPTIONS', 'allow header contains expected options' );

done_testing();
