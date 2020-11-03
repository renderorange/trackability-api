use strict;
use warnings;

BEGIN {
    require FindBin;
    $ENV{DANCER_CONFDIR} = "$FindBin::Bin/../../app";
    $ENV{DANCER_ENVIRONMENT} = 'development';
}

use lib "$FindBin::Bin/../../lib", "$FindBin::Bin/../lib";
use Trackability::API::Test;

use Plack::Test;
use HTTP::Request ();

use Trackability::API ();
use JSON ();

use Trackability::API::Model::Users;

my $user_one = Trackability::API::Model::Users->new(
    name => 'user one',
    email => 'user-one@example.com',
);
$user_one->store();

my $method   = 'GET';
my $endpoint = '/users/1';

my $app  = Trackability::API->to_app;
my $test = Plack::Test->create( $app );

my $request = HTTP::Request->new( $method, $endpoint );

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

done_testing();
