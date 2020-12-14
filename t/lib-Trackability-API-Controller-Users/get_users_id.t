use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib", "$FindBin::RealBin/../lib";
use Trackability::API::Test;
use Trackability::API::Model::Users ();
use Trackability::API               ();

use Plack::Test;
use HTTP::Request ();
use JSON ();

my $user_one = Trackability::API::Model::Users->new(
    name => 'user one',
    email => 'user-one@example.com',
);
$user_one->store();
my $key = $user_one->add_key();

my $method   = 'GET';
my $endpoint = '/users/1';

my $app  = Trackability::API->to_app;
my $test = Plack::Test->create( $app );

my $headers = [
    'Authorization' => 'Token ' . $key,
];
my $request = HTTP::Request->new( $method, $endpoint, $headers );

my $response = $test->request( $request );
my $content  = $response->content;

ok( $response->is_success, sprintf( '%s %s was successful', $method, $endpoint ) );

my $decoded_content = JSON::decode_json $content;
my $expected_content =
    {
        'users' => [
            {
                '_meta' => {
                    'id' => $user_one->id,
                    'name' => $user_one->name,
                    'email' => $user_one->email,
                    'updated_at' => $user_one->updated_at,
                    'created_at' => $user_one->created_at,
                }
            }
        ],
    };

cmp_deeply( $decoded_content, $expected_content, 'decoded content contains expected data structure' );
ok( !exists $decoded_content->{users}->[1], 'only the authenticated user was returned' );

done_testing();
