use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../../lib", "$FindBin::RealBin/../lib";
use Trackability::API::Test;
use Trackability::API::Model::Users;
use Trackability::API::Model::Collections;

my $user = Trackability::API::Model::Users->new(
    email => 'foo@bar.tld',
    name => 'Foo Bar',
);
my $ret = $user->store();
ok( $ret, 'created and stored user' );

my $collection = Trackability::API::Model::Collections->new(
    name => 'test collection',
    users_id => $user->id,
);
$ret = $collection->store();
ok( $ret, 'created and stored collection' );

my $id = $collection->id;
my $name = $collection->name;
my $users_id = $collection->users_id;
my $created_at = $collection->created_at;
my $updated_at = $collection->updated_at;

sleep(1);

$collection->name( 'test collection updated' );
$ret = $collection->store();
ok( $ret, 'updated collection' );

my $collection_from_db = $Trackability::API::Test::dbh->selectrow_hashref( "select * from collections where id = ?", undef, ( $collection->id ) );

ok( $collection->name eq $collection_from_db->{name}, 'collection object and db match name after update' );
ok( $created_at eq $collection->{created_at} &&
    $created_at eq $collection_from_db->{created_at}, 'created_at was updated in the db and object' );
ok( $updated_at ne $collection->{updated_at} &&
    $updated_at ne $collection_from_db->{updated_at}, 'updated_at was updated in the db and object' );

done_testing;
