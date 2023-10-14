use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib", "$FindBin::RealBin/../lib";
use Trackability::API::Test;
use Trackability::API::Model::Users ();
use Trackability::API               ();

use Plack::Test;
use HTTP::Request ();
use JSON   ();
use Encode ();

my $user_one = Trackability::API::Model::Users->new(
    name => 'user one',
    email => 'user-one@example.com',
);
$user_one->store();
my $key = $user_one->add_key();

my $method   = 'PUT';
my $endpoint = '/users/1';

my $app  = Trackability::API->to_app;
my $test = Plack::Test->create( $app );

my $headers = [
    'Authorization' => 'Token ' . $key,
];
my $request = HTTP::Request->new( $method, $endpoint, $headers );

my $data = { name => 'changed', email => 'changed@example.com' };
my $encoded_data = Encode::encode_utf8( JSON::encode_json( $data ) );
$request->content( $encoded_data );

my $response = $test->request( $request );
my $content  = $response->content;

ok( $response->is_success, sprintf( '%s %s was successful', $method, $endpoint ) );

my $decoded_content = JSON::decode_json $content;
my $expected_content =
    {
        id => $user_one->id,
        name => 'changed',
        email => 'changed@example.com',
        updated_at => ignore(),
        created_at => ignore(),
    };

cmp_deeply( $decoded_content, $expected_content, 'decoded content contains expected data structure' );
ok( !exists $decoded_content->{users}->[1], 'only the authenticated user was returned' );

done_testing();
