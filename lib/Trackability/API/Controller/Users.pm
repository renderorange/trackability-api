package Trackability::API::Controller::Users;

use Dancer2 appname => 'trackability-api';

use Trackability::API::Model::Users ();
use Trackability::API::Response     ();

use List::MoreUtils       ();
use Data::Structure::Util ();

our $VERSION = '0.001';

options '/users/:id' => sub {
    response_header( allow          => 'GET,PUT,OPTIONS' );
    response_header( 'Content-Type' => 'text/plain' );

    return;
};

get '/users/:id' => sub {
    my $id       = route_parameters->get('id');
    my $users_id = vars->{users_id};

    my $users = Trackability::API::Model::Users->get( id => $id );

    unless ($users) {
        return Trackability::API::Response::not_found();
    }

    unless ( $users->[0]->id == $users_id ) {
        return Trackability::API::Response::forbidden();
    }

    Data::Structure::Util::unbless($users);

    return $users->[0];
};

put '/users/:id' => sub {
    my $id       = route_parameters->get('id');
    my $users_id = vars->{users_id};

    my $users = Trackability::API::Model::Users->get( id => $id );

    unless ($users) {
        return Trackability::API::Response::not_found();
    }

    unless ( $users->[0]->id == $users_id ) {
        return Trackability::API::Response::forbidden();
    }

    my $name  = body_parameters->get('name');
    my $email = body_parameters->get('email');

    # TODO: verify header for json is present.

    unless ( defined $name || defined $email ) {
        return Trackability::API::Response::bad_request('The name and email parameters are required.');
    }

    my @valid_parameters = qw(
        name
        email
    );

    my $body_parameters = body_parameters;

    foreach my $key ( keys %{$body_parameters} ) {
        unless ( List::MoreUtils::any { $key eq $_ } @valid_parameters ) {
            return Trackability::API::Response::bad_request("$key is an unknown parameter.");
        }
    }

    if ($name) {
        $users->[0]->name($name);
    }

    if ( $email && $email ne $users->[0]->email ) {

        # check if the user already exists in the system
        my $existing_user = Trackability::API::Model::Users->get( email => $email );

        if ($existing_user) {
            return Trackability::API::Response::conflict('That email address is already in use.');
        }

        $users->[0]->email($email);
    }

    $users->[0]->store();

    Data::Structure::Util::unbless($users);

    return $users->[0];
};

1;
