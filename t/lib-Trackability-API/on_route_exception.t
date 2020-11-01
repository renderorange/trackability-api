use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib", "$FindBin::RealBin/../../lib";
use Trackability::API::Test skip_db => 1;
use Trackability::API ();
use Trackability::API::Exception::Invalid ();

use Plack::Test;
use HTTP::Request ();

HAPPY_PATH: {
    note( 'happy path' );

    my $internal_error = 'fake your death';

    Trackability::API::Test::override(
        package => 'Trackability::API::Model::Users',
        name    => 'get',
        subref  => sub { die( $internal_error ) },
    );

    my $logger_fired = 0;

    Trackability::API::Test::override(
        package => 'Dancer2::Logger::Console',
        name    => 'log',
        subref  => sub { $logger_fired = 1 },
    );

    my $method   = 'GET';
    my $endpoint = '/users/1';

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
    is( $response->code, 500, 'response code was 500' );
    is( $response->header( 'Content-Type' ), 'text/plain', 'response Content-Type header was text/plain' );
    is( $content, 'Whoops, something went wrong on our end.', 'response content indicates something went wrong' );
    unlike( $content, qr/$internal_error/, 'response content does not contain the internal error' );

    ok( $logger_fired, 'logger method was fired' );

    # test classed exceptions
    Trackability::API::Test::override(
        package => 'Trackability::API::Model::Users',
        name    => 'get',
        subref  => sub { Trackability::API::Exception::Invalid->throw( { message => $internal_error } ) },
    );

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
    is( $response->code, 400, 'response code was 400' );
    is( $response->header( 'Content-Type' ), 'text/plain', 'response Content-Type header was text/plain' );
    like( $content, qr/$internal_error/, 'response content contains the internal error' );

    ok( $logger_fired, 'logger method was fired' );
}

done_testing;
