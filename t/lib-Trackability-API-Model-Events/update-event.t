use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../../lib", "$FindBin::RealBin/../lib";
use Trackability::API::Test;
use Trackability::API::Model::Users;
use Trackability::API::Model::Collections;
use Trackability::API::Model::Events;

my $user = Trackability::API::Model::Users->new(
    email => 'foo@bar.tld',
    name => 'Foo Bar',
);
my $ret = $user->store();
ok( $ret, 'created and stored user' );

my $collection_one = Trackability::API::Model::Collections->new(
    name => 'Collection One',
    users_id => $user->id,
);
$ret = $collection_one->store();
ok( $ret, 'created and stored collection one' );

my $collection_two = Trackability::API::Model::Collections->new(
    name => 'Collection Two',
    users_id => $user->id,
);
$ret = $collection_two->store();
ok( $ret, 'created and stored collection two' );

my $event = Trackability::API::Model::Events->new(
    collections_id => $collection_one->id,
    data => '{"one":1,"two":2}',
);
$ret = $event->store();
ok( $ret, 'created and stored event' );

my $id = $event->id;
my $collections_id = $event->collections_id;
my $data       = $event->data;
my $created_at = $event->created_at;
my $updated_at = $event->updated_at;

sleep(1);

$event->collections_id( $collection_two->id );
$event->data( '{"one":1,"two":2,"three":3}' );
$ret = $event->store();
ok( $ret, 'updated event' );

my $event_from_db = $Trackability::API::Test::dbh->selectrow_hashref( "select * from events where id = ?", undef, ( $event->id ) );

ok( $event->collections_id eq $event_from_db->{collections_id}, 'event object and db match collections_id after update' );
ok( $collections_id ne $event->collections_id &&
    $collections_id ne $event_from_db->{collections_id},
    'collections_id was updated in the db and object' );

ok( $event->data eq $event_from_db->{data}, 'event object and db match data after update' );
ok( $data ne $event->data &&
    $data ne $event_from_db->{data},
    'data was updated in the db and object' );

ok( $created_at eq $event->{created_at} &&
    $created_at eq $event_from_db->{created_at}, 'created_at was not updated in the db and object' );
ok( $updated_at ne $event->{updated_at} &&
    $updated_at ne $event_from_db->{updated_at}, 'updated_at was updated in the db and object' );

done_testing;
