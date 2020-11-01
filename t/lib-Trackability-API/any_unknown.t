use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib", "$FindBin::RealBin/../../lib";
use Trackability::API::Test skip_db => 1;
use Trackability::API ();

use Plack::Test;
use HTTP::Request ();

HAPPY_PATH: {
    note( 'happy path' );

    my $method   = 'GET';
    my $endpoint = '/';
    my $response = test_psgi
        app    => Trackability::API->to_app,
        client => sub {
            my $cb = shift;

            my $request = HTTP::Request->new(
                $method,
                $endpoint,
            );

            my $response = $cb->( $request );

            return $response;
        };

    my $content = $response->content();

    ok( $response->is_error, sprintf( '%s %s was not successful', $method, $endpoint ) );
    ok( $response->code == 404, 'response code was 404' );
    ok( $response->header( 'Content-Type' ) eq 'text/plain', 'response Content-Type header was text/plain' );
    ok( $content =~ qr/not found/, 'response content indicates not found' );

    $method   = 'POST';
    $endpoint = '/unknown';
    $response = test_psgi
        app    => Trackability::API->to_app,
        client => sub {
            my $cb = shift;

            my $request = HTTP::Request->new(
                $method,
                $endpoint,
            );

            my $response = $cb->( $request );

            return $response;
        };

    $content = $response->content();

    ok( $response->is_error, sprintf( '%s %s was not successful', $method, $endpoint ) );
    ok( $response->code == 404, 'response code was 404' );
    ok( $response->header( 'Content-Type' ) eq 'text/plain', 'response Content-Type header was text/plain' );
    ok( $content =~ qr/not found/, 'response content indicates not found' );
}

done_testing;
