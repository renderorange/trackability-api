package Trackability::API::Controller::Collections;

use Dancer2 appname => 'trackability-api';

use Trackability::API::Model::Collections ();
use Trackability::API::Model::Events      ();
use Trackability::API::Response           ();

use List::MoreUtils       ();
use Data::Structure::Util ();
use Try::Tiny;

our $VERSION = '0.001';

options '/collections' => sub {
    header( allow          => 'GET,POST,OPTIONS' );
    header( 'Content-Type' => 'text/plain' );

    return;
};

get '/collections' => sub {
    my $query    = query_parameters;
    my $users_id = vars->{users_id};

    my $collections;

    # below we're hard setting the users_id based on authentication.
    # since there can be more than one object returned here, we're simply
    # not going to include those not belonging to that user rather than
    # erroring forbidden.
    if ( keys %{$query} ) {
        my @valid_keys = qw(
            id
            name
        );

        foreach my $key ( keys %{$query} ) {
            unless ( List::MoreUtils::any { $key eq $_ } @valid_keys ) {
                return Trackability::API::Response::bad_request("$key is an unknown query parameter.");
            }
        }

        # TODO: update this like get events, to pass query straight in.
        # no need to have this in an else.
        $collections = Trackability::API::Model::Collections->get( %{$query}, users_id => $users_id );
    }
    else {
        $collections = Trackability::API::Model::Collections->get( users_id => $users_id );
    }

    unless ($collections) {
        return Trackability::API::Response::not_found();
    }

    # rearrange the data structure to return
    Data::Structure::Util::unbless($collections);

    foreach my $collection ( @{$collections} ) {
        $collection->{_meta}{id}         = delete $collection->{id};
        $collection->{_meta}{name}       = delete $collection->{name};
        $collection->{_meta}{users_id}   = delete $collection->{users_id};
        $collection->{_meta}{created_at} = delete $collection->{created_at};
        $collection->{_meta}{updated_at} = delete $collection->{updated_at};
    }

    my $return_data = { collections => $collections };

    return $return_data;
};

post '/collections' => sub {
    my $name     = body_parameters->get('name');
    my $users_id = vars->{users_id};

    # TODO: verify header for json is present.

    unless ( defined $name ) {
        return Trackability::API::Response::bad_request('The name parameter is required.');
    }

    my @valid_parameters = qw(
        name
    );

    my $body_parameters = body_parameters;

    foreach my $key ( keys %{$body_parameters} ) {
        unless ( List::MoreUtils::any { $key eq $_ } @valid_parameters ) {
            return Trackability::API::Response::bad_request("$key is an unknown parameter.");
        }
    }

    my $collection = Trackability::API::Model::Collections->new(
        name     => $name,
        users_id => $users_id,
    );

    $collection->store();

    # rearrange the data structure to return
    Data::Structure::Util::unbless($collection);

    $collection->{_meta}{id}         = delete $collection->{id};
    $collection->{_meta}{name}       = delete $collection->{name};
    $collection->{_meta}{users_id}   = delete $collection->{users_id};
    $collection->{_meta}{created_at} = delete $collection->{created_at};
    $collection->{_meta}{updated_at} = delete $collection->{updated_at};

    my $return_data = { collections => [$collection] };

    return $return_data;
};

options '/collections/:id' => sub {
    header( allow          => 'GET,PUT,OPTIONS' );
    header( 'Content-Type' => 'text/plain' );

    return;
};

get '/collections/:id' => sub {
    my $id       = route_parameters->get('id');
    my $users_id = vars->{users_id};

    my $collections = Trackability::API::Model::Collections->get( id => $id );

    unless ($collections) {
        return Trackability::API::Response::not_found();
    }

    unless ( $collections->[0]->users_id == $users_id ) {
        return Trackability::API::Response::forbidden();
    }

    # rearrange the data structure to return
    Data::Structure::Util::unbless($collections);

    $collections->[0]{_meta}{id}         = delete $collections->[0]{id};
    $collections->[0]{_meta}{name}       = delete $collections->[0]{name};
    $collections->[0]{_meta}{users_id}   = delete $collections->[0]{users_id};
    $collections->[0]{_meta}{created_at} = delete $collections->[0]{created_at};
    $collections->[0]{_meta}{updated_at} = delete $collections->[0]{updated_at};

    my $return_data = { collections => [ $collections->[0] ] };

    return $return_data;
};

put '/collections/:id' => sub {
    my $id       = route_parameters->get('id');
    my $users_id = vars->{users_id};

    my $collections = Trackability::API::Model::Collections->get( id => $id );

    unless ($collections) {
        return Trackability::API::Response::not_found();
    }

    unless ( $collections->[0]->users_id == $users_id ) {
        return Trackability::API::Response::forbidden();
    }

    my $body_parameters = body_parameters;

    foreach my $key ( keys %{$body_parameters} ) {
        unless ( List::MoreUtils::any { $key eq $_ } ('name') ) {
            return Trackability::API::Response::bad_request("The $key parameter cannot be updated.");
        }
    }

    my $name = body_parameters->get('name');

    # TODO: verify header for json is present.

    unless ( defined $name ) {
        return Trackability::API::Response::bad_request('The name parameter is required.');
    }

    $collections->[0]->name($name);
    $collections->[0]->store();

    # rearrange the data structure to return
    Data::Structure::Util::unbless($collections);

    $collections->[0]{_meta}{id}         = delete $collections->[0]{id};
    $collections->[0]{_meta}{name}       = delete $collections->[0]{name};
    $collections->[0]{_meta}{users_id}   = delete $collections->[0]{users_id};
    $collections->[0]{_meta}{created_at} = delete $collections->[0]{created_at};
    $collections->[0]{_meta}{updated_at} = delete $collections->[0]{updated_at};

    my $return_data = { collections => [ $collections->[0] ] };

    return $return_data;
};

options '/collections/:id/events' => sub {
    header( allow          => 'GET,POST,OPTIONS' );
    header( 'Content-Type' => 'text/plain' );

    return;
};

get '/collections/:id/events' => sub {
    my $id       = route_parameters->get('id');
    my $query    = query_parameters;
    my $users_id = vars->{users_id};

    my $collections = Trackability::API::Model::Collections->get( id => $id );

    unless ($collections) {
        return Trackability::API::Response::not_found();
    }

    unless ( $collections->[0]->users_id == $users_id ) {
        return Trackability::API::Response::forbidden();
    }

    # validate the query params
    if ( keys %{$query} ) {
        my @valid_keys = qw(
            id
            created
        );

        foreach my $key ( keys %{$query} ) {
            unless ( List::MoreUtils::any { $key eq $_ } @valid_keys ) {
                return Trackability::API::Response::bad_request("$key is an unknown query parameter.");
            }
        }

        # validate the created query
        if ( defined $query->{created} ) {

            # to allow for multiple definitions of created, we need to specifically retrieve it from the query.
            # the query_parameters method returns a hashref, which will overwrite the first definition.
            my @created = query_parameters->get_all('created');

            if ( List::MoreUtils::any { $_ && $_ !~ /^\d+$/ } @created ) {
                return Trackability::API::Response::bad_request('The created parameter must be an epoch timestamp.');
            }

            delete $query->{created};

            # if only 1 is defined, assume they want an exact match for that date to the created_at column.
            # if 2 are defined, then they want between created[0] and created[1].
            if ( scalar @created == 1 ) {
                $query->{created_at} = $created[0];
            }
            else {
                $query->{created_at} = [ $created[0], $created[1] ];
            }
        }
    }

    my $events = Trackability::API::Model::Events->get( %{$query}, collections_id => $id );

    unless ($events) {
        return { events => [] };
    }

    # rearrange the data structure to return
    Data::Structure::Util::unbless($events);

    foreach my $event ( @{$events} ) {
        $event->{_meta}{id}             = delete $event->{id};
        $event->{_meta}{collections_id} = delete $event->{collections_id};
        $event->{_meta}{created_at}     = delete $event->{created_at};
        $event->{_meta}{updated_at}     = delete $event->{updated_at};

        # this *should* be valid JSON already since we won't store it
        # if it's invalid.
        # this might be better to wrap in a try/catch block to be sure.
        my $data = decode_json( delete $event->{data} );
        foreach ( keys %{$data} ) {
            $event->{$_} = $data->{$_};
        }
    }

    my $return_data = { events => $events };

    return $return_data;
};

post '/collections/:id/events' => sub {
    my $id       = route_parameters->get('id');
    my $users_id = vars->{users_id};

    my $collections = Trackability::API::Model::Collections->get( id => $id );

    unless ($collections) {
        return Trackability::API::Response::not_found();
    }

    unless ( $collections->[0]->users_id == $users_id ) {
        return Trackability::API::Response::forbidden();
    }

    my $data = Data::Structure::Util::unbless(body_parameters);

    # TODO: verify the data being sent is all allowed data types
    # before serializing back to json.

    my $json = try {
        return encode_json($data);
    }
    catch {
        my $exception = $_;
        die "encode_json failed: $exception\n";
    };

    # TODO: verify this user is who's posting

    my $event = Trackability::API::Model::Events->new(
        collections_id => $id,
        data           => $json,
    );

    $event->store();

    # rearrange the data structure to return
    Data::Structure::Util::unbless($event);

    $event->{_meta}{id}             = delete $event->{id};
    $event->{_meta}{collections_id} = delete $event->{collections_id};
    $event->{_meta}{created_at}     = delete $event->{created_at};
    $event->{_meta}{updated_at}     = delete $event->{updated_at};

    delete $event->{data};

    my $return_data = { events => [$event] };

    return $return_data;
};

options '/collections/:collections_id/events/:events_id' => sub {
    header( allow          => 'GET,OPTIONS' );
    header( 'Content-Type' => 'text/plain' );

    return;
};

get '/collections/:collections_id/events/:events_id' => sub {
    my $collections_id = route_parameters->get('collections_id');
    my $users_id       = vars->{users_id};

    my $collections = Trackability::API::Model::Collections->get( id => $collections_id );

    unless ($collections) {
        return Trackability::API::Response::not_found();
    }

    unless ( $collections->[0]->users_id == $users_id ) {
        return Trackability::API::Response::forbidden();
    }

    my $events_id = route_parameters->get('events_id');

    my $events = Trackability::API::Model::Events->get( id => $events_id, collections_id => $collections_id );

    unless ($events) {
        return Trackability::API::Response::not_found();
    }

    # rearrange the data structure to return
    Data::Structure::Util::unbless($events);

    $events->[0]{_meta}{id}             = delete $events->[0]{id};
    $events->[0]{_meta}{collections_id} = delete $events->[0]{collections_id};
    $events->[0]{_meta}{created_at}     = delete $events->[0]{created_at};
    $events->[0]{_meta}{updated_at}     = delete $events->[0]{updated_at};

    # this *should* be valid JSON already since we won't store it
    # if it's invalid.
    # this might be better to wrap in a try/catch block to be sure.
    my $data = decode_json( delete $events->[0]{data} );
    foreach ( keys %{$data} ) {
        $events->[0]{$_} = $data->{$_};
    }

    my $return_data = { events => [ $events->[0] ] };

    return $return_data;
};

1;
