use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../lib", "$FindBin::RealBin/../lib";
use Trackability::API::Test;
use Trackability::API ();

use Plack::Test;
use HTTP::Request ();

my $method   = 'GET';
my $endpoint = '/users/1';

my $app  = Trackability::API->to_app;
my $test = Plack::Test->create( $app );

my $request = HTTP::Request->new( $method, $endpoint );

my $response = $test->request( $request );

ok( $response->is_error, sprintf( '%s %s was not successful', $method, $endpoint ) );
is( $response->code, 400, 'response code was 400' );

done_testing();
