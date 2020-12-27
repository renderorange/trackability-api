use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../lib", "$FindBin::RealBin/../../lib";
use Trackability::API::Test;
use Trackability::API::Model::Users;

my $class = 'Trackability::API::Model::Users';

HAPPY_PATH: {
    note( 'happy path' );

    my $user_one = $class->new(
        email => 'foo@bar.tld',
        name => 'Foo Bar',
    );
    my $ret = $user_one->store();
    ok( $ret, 'store was successful' );

    my $key_one = $user_one->add_key();
    ok( $key_one, 'key one is returned' );

    ok( $user_one->validate_key( key => $key_one ), 'returned key validates' );

    my $user_two = $class->new(
        email => 'bar@bar.tld',
        name => 'Bar Foo',
    );
    $ret = $user_two->store();

    my $key_two = $user_two->add_key();
    ok( $key_two, 'key two is returned' );

    my $authenticated_user = $class->validate_key( key => $key_two );

    is( $authenticated_user->[0]{id}, $user_two->id, 'user returned from key two is user two' );
    isnt( $authenticated_user->[0]{id}, $user_one->id, 'user returned from key two is not user one' );
}

INVALID_KEY: {
    note( 'invalid key' );

    subtest 'on invalid key' => sub {
        plan tests => 3;

        dies_ok { $class->validate_key( key => 'not a key' ) } 'dies ok';
        my $exception_class = 'Trackability::API::Exception::Invalid';
        throws_ok { $class->validate_key( key => 'not a key' ) } $exception_class,
                    "exception class is $exception_class";
        my $exception_string = 'key is invalid';
        throws_ok { $class->validate_key( key => 'not a key' ) } qr/$exception_string/,
                    "exception string is '$exception_string'";
    };
}

USER_NOT_FOUND: {
    note( 'user not found' );

    # here we're tapping into the encode process to change the user id within the key
    # so it doesn't match.
    Trackability::API::Test::override(
        package => 'Trackability::API::Crypt::Storage',
        name    => 'encode',
        subref  => sub {
            my $self = shift;
            my $arg  = {
                string => undef,
                @_,
            };

            # manipulate the users_id to not match
            my $plain_key = $arg->{string};
            my ( $users_key_id, $users_id, $token ) = split( /-/, $plain_key );
            my $new_key = $users_key_id . $users_id + 1 . $token;

            return $self->{_store_obj}->decode( $new_key );
        },
    );

    my $user_one = $class->new(
        email => 'new@bar.tld',
        name => 'new Bar',
    );
    my $ret = $user_one->store();
    ok( $ret, 'store was successful' );

    my $key_one = $user_one->add_key();

    my $exception_class = 'Trackability::API::Exception::Missing';
    throws_ok { $class->validate_key( key => $key_one ) } $exception_class,
                    "on user not found exception class is '$exception_class'";
}

done_testing;
