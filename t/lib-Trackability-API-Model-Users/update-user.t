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
$user->store();
note( 'created and stored user to db' );

my $id = $user->id;
my $name = $user->name;
my $email = $user->email;
my $created_at = $user->created_at;
my $updated_at = $user->updated_at;

sleep(1);

$user->email( 'foo2@bar.tld' );
$user->store();
note( 'updated email and stored to db' );

my $user_from_db = $Trackability::API::Test::dbh->selectrow_hashref( "select email, UNIX_TIMESTAMP(created_at) as created_at, UNIX_TIMESTAMP(updated_at) as updated_at from users where id = ?", undef, ( $user->id ) );

ok( $user->email eq $user_from_db->{email}, 'user object and db match email after update' );
ok( $created_at eq $user->{created_at} &&
    $created_at eq $user_from_db->{created_at}, 'created_at was updated in the db and object' );
ok( $updated_at ne $user->{updated_at} &&
    $updated_at ne $user_from_db->{updated_at}, 'updated_at was updated in the db and object' );

done_testing;
