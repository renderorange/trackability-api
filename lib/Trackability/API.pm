package Trackability::API;

use Dancer2 appname => 'trackability-api';

use Scalar::Util                ();
use HTTP::Status                ();
use Trackability::API::Response ();

use Trackability::API::Controller::Users ();

our $VERSION = '0.001';

BEGIN {
    require Trackability::API::Config;
    my $conf = Trackability::API::Config->get();
}

any qr{.*} => sub {

    # throw 404 for any undefined method or route.
    return Trackability::API::Response::not_found();
};

hook on_route_exception => sub {
    my $app       = shift;
    my $exception = shift;

    header( 'Content-Type' => 'text/plain' );

    if (   Scalar::Util::blessed($exception)
        && Scalar::Util::blessed($exception) eq 'Trackability::API::Exception::Invalid' ) {
        response->{status}  = HTTP::Status::HTTP_BAD_REQUEST;
        response->{content} = $exception->{message};
    }
    elsif (Scalar::Util::blessed($exception)
        && Scalar::Util::blessed($exception) eq 'Trackability::API::Exception::Missing' ) {
        response->{status}  = HTTP::Status::HTTP_BAD_REQUEST;
        response->{content} = $exception->{message};
    }
    else {
        # if we're here, the exception isn't one we've expected.
        # log the unknown exception through the logging handle.
        # the development environment outputs to console; production outputs to file.
        log( 'error', $exception );

        response->{status}  = HTTP::Status::HTTP_INTERNAL_SERVER_ERROR;
        response->{content} = 'Whoops, something went wrong on our end.';
    }

    halt();
};

1;
