use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib", "$FindBin::RealBin/../lib";
use Trackability::API::Test;
use Trackability::API::Model::Users ();
use Trackability::API               ();

use Plack::Test;
use HTTP::Request ();

my $user_one = Trackability::API::Model::Users->new(
    name => 'user one',
    email => 'user-one@example.com',
);
my $password = 'Testtesttest1';
$user_one->store();
my $key = $user_one->add_key();

my $method   = 'OPTIONS';
my $endpoint = '/users/1';

my $app  = Trackability::API->to_app;
my $test = Plack::Test->create( $app );

my $headers = [
    'Authorization' => 'Token ' . $key,
];
my $request = HTTP::Request->new( $method, $endpoint, $headers );

my $response = $test->request( $request );

ok( $response->is_success, sprintf( '%s %s was successful', $method, $endpoint ) );
is( $response->headers->{allow}, 'GET,PUT,OPTIONS', 'allow header contains expected options' );

done_testing();
