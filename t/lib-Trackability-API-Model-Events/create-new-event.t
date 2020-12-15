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

my $collection = Trackability::API::Model::Collections->new(
    name => 'Foo',
    users_id => $user->id,
);
$ret = $collection->store();
ok( $ret, 'created and stored collection' );

my $event = Trackability::API::Model::Events->new(
    collections_id => $collection->id,
    data => '{"one":1,"two":2}',
);
$ret = $event->store();
ok( $ret, 'created and stored event' );

my $event_from_db = $Trackability::API::Test::dbh->selectrow_hashref( "select * from events where id = ?", undef, ( $event->id ) );

ok( $event->id eq $event_from_db->{id}, 'event object and db match id' );
ok( $event->collections_id eq $event_from_db->{collections_id}, 'event object and db match collections_id' );
ok( $event->data eq $event_from_db->{data}, 'event object and db match data' );
ok( $event->created_at eq $event_from_db->{created_at}, 'event object and db match created_at' );
ok( $event->updated_at eq $event_from_db->{updated_at}, 'event object and db match updated_at' );

done_testing;
