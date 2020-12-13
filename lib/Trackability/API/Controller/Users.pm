package Trackability::API::Controller::Users;

use Dancer2 appname => 'trackability-api';

use Trackability::API::Model::Users ();
use Trackability::API::Response     ();

use List::MoreUtils       ();
use Data::Structure::Util ();

our $VERSION = '0.001';

options '/users/:id' => sub {
    header( allow          => 'GET,PUT,OPTIONS' );
    header( 'Content-Type' => 'text/plain' );

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

    # rearrange the data structure to return
    Data::Structure::Util::unbless($users);

    $users->[0]{_meta}{id}         = delete $users->[0]{id};
    $users->[0]{_meta}{name}       = delete $users->[0]{name};
    $users->[0]{_meta}{email}      = delete $users->[0]{email};
    $users->[0]{_meta}{created_at} = delete $users->[0]{created_at};
    $users->[0]{_meta}{updated_at} = delete $users->[0]{updated_at};

    my $return_data = { users => [ $users->[0] ] };

    return $return_data;
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

    my $name     = body_parameters->get('name');
    my $password = body_parameters->get('password');
    my $email    = body_parameters->get('email');

    # TODO: verify header for json is present.

    unless ( defined $name || defined $password || defined $email ) {
        return Trackability::API::Response::bad_request('The name, password, or email parameter is required.');
    }

    my @valid_parameters = qw(
        name
        password
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

    if ($password) {
        $users->[0]->check_password( password => $password );
    }

    $users->[0]->store();

    # this isn't ideal having to check the password, store, then store password.
    # the issue is the _update_object call inside of store_password updating the object to
    # overwrite the values before storing the values we already set.
    # ideally, the way this works get rewritten.
    if ($password) {
        $users->[0]->store_password( password => $password );
    }

    # rearrange the data structure to return
    Data::Structure::Util::unbless($users);

    $users->[0]{_meta}{id}         = delete $users->[0]{id};
    $users->[0]{_meta}{name}       = delete $users->[0]{name};
    $users->[0]{_meta}{email}      = delete $users->[0]{email};
    $users->[0]{_meta}{created_at} = delete $users->[0]{created_at};
    $users->[0]{_meta}{updated_at} = delete $users->[0]{updated_at};

    my $return_data = { users => [ $users->[0] ] };

    return $return_data;
};

1;
