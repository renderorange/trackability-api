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
    name => 'Foo',
    users_id => $user->id,
);
$ret = $collection->store();
ok( $ret, 'created and stored collection' );

my $collection_from_db = $Trackability::API::Test::dbh->selectrow_hashref( "select * from collections where id = ?", undef, ( $collection->id ) );

ok( $collection->id eq $collection_from_db->{id}, 'collection object and db match id' );
ok( $collection->name eq $collection_from_db->{name}, 'collection object and db match name' );
ok( $collection->users_id eq $collection_from_db->{users_id}, 'collection object and db match users_id' );
ok( $collection->created_at eq $collection_from_db->{created_at}, 'collection object and db match created_at' );
ok( $collection->updated_at eq $collection_from_db->{updated_at}, 'collection object and db match updated_at' );

done_testing;
