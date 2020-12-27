use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../lib", "$FindBin::RealBin/../../lib";
use Trackability::API::Test;
use Trackability::API::Model::Users;

my $user = Trackability::API::Model::Users->new(
    email => 'foo@bar.tld',
    name => 'Foo Bar',
);
my $ret = $user->store();
ok( $ret, 'store was successful' );

ok( !$user->can( 'key' ), "user object doesn't contain key method" );

my $key_one = $user->add_key();
ok( $key_one, 'key one is returned' );

my $users_keys_from_db = $Trackability::API::Test::dbh->selectall_arrayref(
    "select * from users_key where users_id = ?", { Slice => {} }, ( $user->id ),
);

is( scalar @$users_keys_from_db, 1, 'one key exists in the users_key table for the user' );
isnt( $key_one, $users_keys_from_db->[0]->{key}, "the returned key and the key in the db don't match" );
like( $users_keys_from_db->[0]->{key}, qr/^{X-PBKDF2}HMACSHA1:AAAD6A/, 'the key in the db is hashed' );

my $key_two = $user->add_key();
ok( $key_two, 'key two is returned' );

$users_keys_from_db = $Trackability::API::Test::dbh->selectall_arrayref(
    "select * from users_key where users_id = ?", { Slice => {} }, ( $user->id ),
);

is( scalar @$users_keys_from_db, 2, 'two keys exist in the users_key table for the user' );

done_testing;
