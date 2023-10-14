use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib", "$FindBin::RealBin/../lib";
use Trackability::API::Test;
use Trackability::API::Model::Users;
use Trackability::API::Model::Collections;
use Trackability::API;

use Plack::Test;
use HTTP::Request ();
use JSON          ();

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

my $method   = 'GET';
my $endpoint = '/collections/1';

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
        id => $collection_one->id,
        name => $collection_one->name,
        users_id => $collection_one->users_id,
        updated_at => $collection_one->updated_at,
        created_at => $collection_one->created_at,
    };

cmp_deeply( $decoded_content, $expected_content, 'decoded content contains expected data structure' );

done_testing();
