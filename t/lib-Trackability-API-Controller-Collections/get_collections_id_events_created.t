use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib", "$FindBin::RealBin/../lib";
use Trackability::API::Test;
use Trackability::API::Model::Users;
use Trackability::API::Model::Collections;
use Trackability::API::Model::Events;
use Trackability::API;

use Plack::Test;
use HTTP::Request ();
use JSON ();

my %data = ( one => 1, two => 2 );
my $json = JSON::encode_json \%data;

my $user_one = Trackability::API::Model::Users->new(
    name => 'user one',
    email => 'user-one@example.com',
);
$user_one->store();
my $key = $user_one->add_key();

my $user_two = Trackability::API::Model::Users->new(
    name => 'user two',
    email => 'user-two@example.com',
);
$user_two->store();

my $collection_one = Trackability::API::Model::Collections->new(
    name => 'collection one',
    users_id => $user_one->id,
);
$collection_one->store();

my $collection_two = Trackability::API::Model::Collections->new(
    name => 'collection two',
    users_id => $user_two->id,
);
$collection_two->store();

my $collection_three = Trackability::API::Model::Collections->new(
    name => 'collection three',
    users_id => $user_one->id,
);
$collection_three->store();

my $event_one = Trackability::API::Model::Events->new(
    collections_id => $collection_one->id,
    data => $json,
    users_id => $user_one->id,
);
$event_one->store();

sleep(3);

my $event_two = Trackability::API::Model::Events->new(
    collections_id => $collection_two->id,
    data => $json,
    users_id => $user_two->id,
);
$event_two->store();

sleep(3);

my $event_three = Trackability::API::Model::Events->new(
    collections_id => $collection_one->id,
    data => $json,
    users_id => $user_one->id,
);
$event_three->store();

note( 'exact match on created date' );
my $method   = 'GET';
my $endpoint = '/collections/1/events?created=' . $event_three->created_at;

my $app  = Trackability::API->to_app;
my $test = Plack::Test->create( $app );

my $request = HTTP::Request->new( $method, $endpoint );
$request->header( 'Authorization' => 'Token ' . $key );

my $response = $test->request( $request );
my $content  = $response->content;

ok( $response->is_success, sprintf( '%s %s was successful', $method, $endpoint ) );

my $decoded_content = JSON::decode_json $content;
my $expected_content =
    {
        'events' => [
            {
                '_meta' => {
                    'id' => $event_three->id,
                    'collections_id' => $event_three->collections_id,
                    'updated_at' => $event_three->updated_at,
                    'created_at' => $event_three->created_at,
                },
                %data,
            }
        ],
    };

cmp_deeply( $decoded_content, $expected_content, 'decoded content contains expected data structure' );

note( 'between two created dates' );
$endpoint = '/collections/1/events?created=' . $event_one->created_at . '&created=' . $event_three->created_at;

$request = HTTP::Request->new( $method, $endpoint );
$request->header( 'Authorization' => 'Token ' . $key );

$response = $test->request( $request );
$content  = $response->content;

ok( $response->is_success, sprintf( '%s %s was successful', $method, $endpoint ) );

$decoded_content = JSON::decode_json $content;
$expected_content =
    {
        'events' => [
            {
                '_meta' => {
                    'id' => $event_one->id,
                    'collections_id' => $event_one->collections_id,
                    'updated_at' => $event_one->updated_at,
                    'created_at' => $event_one->created_at,
                },
                %data,
            },
            {
                '_meta' => {
                    'id' => $event_three->id,
                    'collections_id' => $event_three->collections_id,
                    'updated_at' => $event_three->updated_at,
                    'created_at' => $event_three->created_at,
                },
                %data,
            }
        ],
    };

cmp_deeply( $decoded_content, $expected_content, 'decoded content contains expected data structure' );

note( 'all newer than or equal to created date' );
$endpoint = '/collections/1/events?created=&created=' . $event_one->created_at;

$request = HTTP::Request->new( $method, $endpoint );
$request->header( 'Authorization' => 'Token ' . $key );

$response = $test->request( $request );
$content  = $response->content;

ok( $response->is_success, sprintf( '%s %s was successful', $method, $endpoint ) );

$decoded_content = JSON::decode_json $content;
$expected_content =
    {
        'events' => [
            {
                '_meta' => {
                    'id' => $event_one->id,
                    'collections_id' => $event_one->collections_id,
                    'updated_at' => $event_one->updated_at,
                    'created_at' => $event_one->created_at,
                },
                %data,
            },
        ],
    };

cmp_deeply( $decoded_content, $expected_content, 'decoded content contains expected data structure' );

note( 'all older than or equal to created date' );
$endpoint = '/collections/1/events?created=' . $event_three->created_at . '&created=';

$request = HTTP::Request->new( $method, $endpoint );
$request->header( 'Authorization' => 'Token ' . $key );

$response = $test->request( $request );
$content  = $response->content;

ok( $response->is_success, sprintf( '%s %s was successful', $method, $endpoint ) );

$decoded_content = JSON::decode_json $content;
$expected_content =
    {
        'events' => [
            {
                '_meta' => {
                    'id' => $event_three->id,
                    'collections_id' => $event_three->collections_id,
                    'updated_at' => $event_three->updated_at,
                    'created_at' => $event_three->created_at,
                },
                %data,
            },
        ],
    };

cmp_deeply( $decoded_content, $expected_content, 'decoded content contains expected data structure' );

done_testing();
