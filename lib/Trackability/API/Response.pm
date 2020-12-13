package Trackability::API::Response;

use Dancer2 appname => 'trackability-api';

use HTTP::Status ();

our $VERSION = '0.001';

sub bad_request {
    my $message = shift;

    # return 400 bad request
    header( 'Content-Type' => 'text/plain' );
    response->{status}  = HTTP::Status::HTTP_BAD_REQUEST;
    response->{content} = $message || "Whoops, something isn't correct with your request.";

    return response;
}

sub unauthorized {
    my $message = shift;

    # return 401 unauthorized
    header( 'Content-Type' => 'text/plain' );
    response->{status}  = HTTP::Status::HTTP_UNAUTHORIZED;
    response->{content} = $message || 'You are not authenticated.';

    return response;
}

sub forbidden {
    my $message = shift;

    # return 403 forbidden
    header( 'Content-Type' => 'text/plain' );
    response->{status}  = HTTP::Status::HTTP_FORBIDDEN;
    response->{content} = $message || 'You are not authorized to access this resource.';

    return response;
}

sub not_found {
    my $message = shift;

    # return 404 not found
    header( 'Content-Type' => 'text/plain' );
    response->{status}  = HTTP::Status::HTTP_NOT_FOUND;
    response->{content} = $message || 'That resource was not found.';

    return response;
}

sub conflict {
    my $message = shift;

    # return 409 conflict
    header( 'Content-Type' => 'text/plain' );
    response->{status}  = HTTP::Status::HTTP_CONFLICT;
    response->{content} = $message || 'That resource already exists.';

    return response;
}

sub internal_server_error {
    my $message = shift;

    # return 500 internal server error
    header( 'Content-Type' => 'text/plain' );
    response->{status}  = HTTP::Status::HTTP_INTERNAL_SERVER_ERROR;
    response->{content} = $message || 'Whoops, something went wrong on our end.';

    return response;
}

sub success {
    my $message = shift;

    # return 200 success
    header( 'Content-Type' => 'text/plain' );
    response->{status}  = HTTP::Status::HTTP_OK;
    response->{content} = $message || 'OK.';

    return response;
}

1;
