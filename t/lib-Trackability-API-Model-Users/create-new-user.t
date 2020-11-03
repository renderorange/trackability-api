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

ok( $user->email eq 'foo@bar.tld', 'user object contains expected email' );
ok( $user->name eq 'Foo Bar', 'user object contains expected name' );
ok( !$user->id, 'user object does not contain id yet' );
ok( !$user->created_at, 'user object does not contain created_at yet' );
ok( !$user->updated_at, 'user object does not contain updated_at yet' );

my $ret = $user->store();
ok( $ret, 'store was successful' );

ok( $user->id, 'user object now contains id' );
ok( $user->created_at, 'user object now contains created_at' );
ok( $user->updated_at, 'user object now contains updated_at' );

my $user_from_db = $Trackability::API::Test::dbh->selectrow_hashref( "select * from users where id = ?", undef, ( $user->id ) );

ok( $user->email eq $user_from_db->{email}, 'user object and db match email' );
ok( $user->name eq $user_from_db->{name}, 'user object and db match name' );
ok( $user->id == $user_from_db->{id}, 'user object and db match id' );
ok( $user->created_at eq $user_from_db->{created_at}, 'user object and db match created_at' );
ok( $user->updated_at eq $user_from_db->{updated_at}, 'user object and db match updated_at' );

done_testing;
