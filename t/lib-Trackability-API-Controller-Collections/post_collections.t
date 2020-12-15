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
use Encode        ();

my $user_one = Trackability::API::Model::Users->new(
    name => 'user one',
    email => 'user-one@example.com',
);
$user_one->store();
my $key = $user_one->add_key();

my $collection_one = Trackability::API::Model::Collections->new(
    name => 'test collection one',
    users_id => $user_one->id,
);
$collection_one->store();

my $method   = 'POST';
my $endpoint = '/collections';

my $app  = Trackability::API->to_app;
my $test = Plack::Test->create( $app );

my $headers = [
    'Content-Type'  => 'application/json',
    'Authorization' => 'Token ' . $key,
];
my $request = HTTP::Request->new( $method, $endpoint, $headers );

my $data = { name => 'test collection two' };
my $encoded_data = Encode::encode_utf8( JSON::encode_json( $data ) );
$request->content( $encoded_data );

my $response = $test->request( $request );
my $content  = $response->content;

ok( $response->is_success, sprintf( '%s %s was successful', $method, $endpoint ) );

my $decoded_content = JSON::decode_json $content;
my $expected_content = {
    collections => [
        {
            '_meta' => {
                id => $collection_one->id + 1,
                name => 'test collection two',
                users_id => $user_one->id,
                created_at => ignore(),
                updated_at => ignore(),
            }
        }
    ],
};

cmp_deeply( $decoded_content, $expected_content, 'content contains expected data structure' );

done_testing();
