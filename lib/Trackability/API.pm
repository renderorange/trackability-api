package Trackability::API;

use Dancer2 appname => 'trackability-api';

use Try::Tiny;
use Scalar::Util                ();
use HTTP::Status                ();
use Trackability::API::Response ();

use Trackability::API::Controller::Users       ();
use Trackability::API::Controller::Collections ();

our $VERSION = '0.001';

any qr{.*} => sub {

    # throw 404 for any undefined method or route.
    return Trackability::API::Response::not_found();
};

hook before => sub {
    my $app = shift;

    my $auth_header = $app->request->headers->authorization;

    # TODO: ensure bearer is correctly spelled and formatted.
    # give proper responses to instruct what is wrong with the request.

    unless ($auth_header) {
        Trackability::API::Response::bad_request();
        halt();
    }

    # TODO: splitting the auth header here is meant to allow for authentication with a static token
    # as well as a JSON Web Token.  depending on how the API and frontend are developed, if a frontend
    # ends up coming out of the this at all, leaving the split here without checking the entity string.
    # most likely, the JSON Web Token functionality will be added later, but not for now.

    my ( $entity, $token ) = split( / /, $auth_header );

    unless ( $entity && $token ) {
        Trackability::API::Response::bad_request();
        halt();
    }

    my $users = try {
        return Trackability::API::Model::Users->validate_key( key => $token );
    }
    catch {
        my $exception = $_;

        if (   Scalar::Util::blessed($exception)
            && Scalar::Util::blessed($exception) eq 'Trackability::API::Exception::Missing' ) {
            Trackability::API::Response::bad_request( $exception->{message} );
            halt();
        }
        elsif (Scalar::Util::blessed($exception)
            && Scalar::Util::blessed($exception) eq 'Trackability::API::Exception::Invalid' ) {
            Trackability::API::Response::unauthorized( $exception->{message} );
            halt();
        }
        else {
            # unknown error during the decode, log and return 400.
            log( 'error', $exception );

            # TODO: ensure all error paths are correctly trapped and coersed here.
            # there could be other reasons for failure, and we don't want to return 400
            # for something that blew up on our end.
            Trackability::API::Response::internal_server_error();
            halt();
        }
    };

    # if we didn't get a user back, the key could be invalid, or was deleted, or never existed.
    # just return unauthorized since it's a good request up to this point.
    unless ( $users->[0] ) {
        Trackability::API::Response::unauthorized();
        halt();
    }

    # if we got this far the token is valid.
    # store the user_id to share between hooks and route handlers.
    # TODO: ensure this isn't available between other user requests in prod mode.
    var users_id => $users->[0]->id;
};

hook after => sub {

    # ensure users_id is destroyed after the route is finished.
    undef vars->{users_id};
};

hook on_route_exception => sub {
    my $app       = shift;
    my $exception = shift;

    log( 'error', $exception );
};

1;
