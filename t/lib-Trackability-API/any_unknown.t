use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib", "$FindBin::RealBin/../lib";
use Trackability::API::Test;
use Trackability::API::Model::Users ();
use Trackability::API               ();

use Plack::Test;
use HTTP::Request ();

my $user = Trackability::API::Model::Users->new( name => 'Test Testerton', email => 'test@testerton.com', );
$user->store;
my $key = $user->add_key();

HAPPY_PATH: {
    note( 'happy path' );

    my $method   = 'GET';
    my $endpoint = '/';
    my $response = test_psgi
        app    => Trackability::API->to_app,
        client => sub {
            my $cb = shift;

            my $headers = [
                'Authorization' => 'Token ' . $key,
            ];
            my $request = HTTP::Request->new(
                $method,
                $endpoint,
                $headers,
            );

            my $response = $cb->( $request );

            return $response;
        };

    my $content = $response->content();

    ok( $response->is_error, sprintf( '%s %s was not successful', $method, $endpoint ) );
    is( $response->code, 404, 'response code was 404' );
    is( $response->header( 'Content-Type' ), 'text/plain', 'response Content-Type header was text/plain' );
    like( $content, qr/not found/, 'response content indicates not found' );

    $method   = 'POST';
    $endpoint = '/unknown';
    $response = test_psgi
        app    => Trackability::API->to_app,
        client => sub {
            my $cb = shift;

            my $headers = [
                'Authorization' => 'Token ' . $key,
            ];
            my $request = HTTP::Request->new(
                $method,
                $endpoint,
                $headers,
            );

            my $response = $cb->( $request );

            return $response;
        };

    $content = $response->content();

    ok( $response->is_error, sprintf( '%s %s was not successful', $method, $endpoint ) );
    is( $response->code, 404, 'response code was 404' );
    is( $response->header( 'Content-Type' ), 'text/plain', 'response Content-Type header was text/plain' );
    like( $content, qr/not found/, 'response content indicates not found' );
}

done_testing;
