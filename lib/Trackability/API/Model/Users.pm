package Trackability::API::Model::Users;

use strictures version => 2;

use Types::Common::Numeric qw{ PositiveInt };
use Types::Common::String qw{ NonEmptyStr };
use Email::Valid               ();
use DateTime::Format::Strptime ();

use Trackability::API::DB                 ();
use Trackability::API::Exception::Missing ();
use Trackability::API::Exception::Invalid ();
use Trackability::API::Crypt::Hash        ();
use Trackability::API::Crypt::Storage     ();
use Trackability::API::Config             ();

use Try::Tiny;
use Scalar::Util ();
use Digest::SHA  ();

use Moo;
use MooX::ClassAttribute;
use namespace::clean;

our $VERSION = '0.001';

use constant { PASSWORD_LENGTH => 12, };

has id => (
    is  => 'rwp',
    isa => PositiveInt,
);

has name => (
    is       => 'rw',
    required => 1,
    isa      => NonEmptyStr,
    writer   => '_set_name',
);

has email => (
    is       => 'rw',
    required => 1,
    isa      => sub {
        unless ( Email::Valid->address( $_[0] ) ) {
            die "not a valid email address\n";
        }
    },
    writer => '_set_email',
);

has created_at => (
    is  => 'rwp',
    isa => sub {
        my $strp = DateTime::Format::Strptime->new(
            pattern  => '%Y-%m-%d %H:%M:%S',
            on_error => 'undef'
        );
        unless ( $strp->parse_datetime( $_[0] ) ) {
            die "not a valid created_at type\n";
        }
    },
);

has updated_at => (
    is  => 'rwp',
    isa => sub {
        my $strp = DateTime::Format::Strptime->new(
            pattern  => '%Y-%m-%d %H:%M:%S',
            on_error => 'undef'
        );
        unless ( $strp->parse_datetime( $_[0] ) ) {
            die "not a valid updated_at type\n";
        }
    },
);

class_has _dbh => (
    is      => 'rwp',
    default => sub {
        Trackability::API::DB::connect_db()
    },
);

sub get {
    my $class = shift;
    my $arg   = {
        id    => undef,
        name  => undef,
        email => undef,
        @_,
    };

    my $sql = q{
        SELECT
            id,
            name,
            email,
            created_at,
            updated_at
        FROM
            users
    };

    my ( @where, @bind_values );

    foreach my $key ( keys %{$arg} ) {
        unless ( defined $arg->{$key} ) {
            next;
        }

        push @where,       "$key = ?";
        push @bind_values, $arg->{$key};
    }

    if ( scalar @where ) {
        $sql .= ' WHERE ' . join " AND ", @where;
    }

    my @users = @{ $class->_dbh->selectall_arrayref( $sql, { Slice => {} }, @bind_values ) };

    unless (@users) {
        return;
    }

    return [ map { $class->new( %{$_} ) } @users ];
}

sub store {
    my $self = shift;

    foreach my $attribute ( 'name', 'email' ) {
        unless ( defined $self->{$attribute} ) {
            Trackability::API::Exception::Missing->throw( { message => "$attribute is required" } );
        }
    }

    my ( $sql, @bind_values );

    if ( $self->id ) {
        $sql = q{
            UPDATE
                users
            SET
                name = ?,
                email = ?
            WHERE
                id = ?
        };

        @bind_values = ( $self->name, $self->email, $self->id );
    }
    else {
        $sql = q{
            INSERT INTO
                users
            SET
                name = ?,
                email = ?
        };

        @bind_values = ( $self->name, $self->email );
    }

    my $result = try {
        return $self->_dbh->do( $sql, undef, @bind_values );
    }
    catch {
        my $exception = $_;

        # TODO: implement rollback and commit
        die "store user failed: $exception\n";
    };

    # set id into the object if this is a new record.
    # for now, we're going to leave the parameters for last_insert_id
    # here even though mysql will ignore them.  there are other databases
    # which may require, so a broader support here is better.
    my $insert = $self->_dbh->last_insert_id( undef, undef, 'users', 'id' );

    if ($insert) {
        $self->_set_id($insert);
    }

    $self->_update_object;

    return $result;
}

sub _update_object {
    my $self = shift;

    unless ( Scalar::Util::blessed($self) ) {
        Trackability::API::Exception::Invalid->throw( { message => "_update_object must be called as an object method" } );
    }

    # always get each of the updatable columns for the object
    my @columns = (qw{ name email created_at updated_at });

    my $query = 'select ' . ( join ', ', @columns ) . ' from users where id = ?';

    my $user_record = $self->_dbh->selectrow_hashref( $query, undef, $self->id );

    foreach my $update (@columns) {
        my $setter = '_set_' . $update;
        $self->$setter( $user_record->{$update} );
    }

    return;
}

sub check_password {
    my $self = shift;
    my $arg  = {
        password => undef,
        @_,
    };

    unless ( Scalar::Util::blessed($self) ) {
        Trackability::API::Exception::Invalid->throw( { message => "check_password must be called as an object method" } );
    }

    unless ( $arg->{password} ) {
        Trackability::API::Exception::Missing->throw( { message => "password is required" } );
    }

    if ( $arg->{password} =~ /^\s+$/ ) {
        Trackability::API::Exception::Invalid->throw( { message => "password cannot be only whitespace" } );
    }

    if ( length( $arg->{password} ) < PASSWORD_LENGTH ) {
        Trackability::API::Exception::Invalid->throw( { message => "password must be at least 12 characters" } );
    }

    my %password_checks = (
        uppercase => qr/[A-Z]+/,
        lowercase => qr/[a-z]+/,
        numeric   => qr/\d+/,
    );

    foreach my $check ( keys %password_checks ) {
        if ( $arg->{password} !~ $password_checks{$check} ) {
            Trackability::API::Exception::Invalid->throw( { message => "password must have at least 1 $check character" } );
        }
    }

    return 1;
}

sub store_password {
    my $self = shift;
    my $arg  = {
        password => undef,
        @_,
    };

    unless ( Scalar::Util::blessed($self) ) {
        Trackability::API::Exception::Invalid->throw( { message => "store_password must be called as an object method" } );
    }

    unless ( $self->id ) {
        Trackability::API::Exception::Invalid->throw( { message => "store_password cannot be run for a nonexistent user" } );
    }

    # check password again, incase the caller didn't already check before storing.
    $self->check_password( password => $arg->{password} );

    my $crypt = Trackability::API::Crypt::Hash->new();
    my $hash  = $crypt->generate( string => $arg->{password} );

    my $sql = q{
        UPDATE
            users
        SET
            password = ?
        WHERE
            id = ?
    };

    my @bind_values = ( $hash, $self->id );

    my $result = try {
        return $self->_dbh->do( $sql, undef, @bind_values );
    }
    catch {
        my $exception = $_;

        # TODO: implement rollback and commit
        die "store_password failed: $exception\n";
    };

    $self->_update_object;

    return $result;
}

sub validate_password {
    my $self = shift;
    my $arg  = {
        password => undef,
        @_,
    };

    unless ( Scalar::Util::blessed($self) ) {
        Trackability::API::Exception::Invalid->throw( { message => "validate_password must be called as an object method" } );
    }

    unless ( $self->id ) {
        Trackability::API::Exception::Invalid->throw( { message => "validate_password cannot be run for a nonexistent user" } );
    }

    unless ( $arg->{password} ) {
        Trackability::API::Exception::Missing->throw( { message => "password is required" } );
    }

    my $sql = q{
        SELECT
            password
        FROM
            users
        WHERE
            id = ?
    };

    my $hash = try {
        return $self->_dbh->selectrow_arrayref( $sql, undef, $self->id )->[0];
    }
    catch {
        my $exception = $_;

        die "validate_password failed: $exception\n";
    };

    unless ($hash) {
        Trackability::API::Exception::Missing->throw( { message => "password is not set" } );
    }

    my $crypt = Trackability::API::Crypt::Hash->new();
    return $crypt->validate( hash => $hash, string => $arg->{password} );
}

sub add_key {
    my $self = shift;

    unless ( Scalar::Util::blessed($self) ) {
        Trackability::API::Exception::Invalid->throw( { message => "add_key must be called as an object method" } );
    }

    unless ( $self->id ) {
        Trackability::API::Exception::Invalid->throw( { message => "add_key cannot be run for a nonexistent user" } );
    }

    my $crypt_hash        = Trackability::API::Crypt::Hash->new();
    my $hash              = $crypt_hash->generate( string => rand . localtime . rand . $self->id );
    my $token             = Digest::SHA::sha256_hex($hash);
    my $hashed_passphrase = $crypt_hash->generate( string => $token );

    my $sql = q{
        INSERT INTO
            users_key
        SET
            users_id = ?,
            `key` = ?
        };

    my $result = try {
        return $self->_dbh->do( $sql, undef, ( $self->id, $hashed_passphrase ) );
    }
    catch {
        my $exception = $_;

        # TODO: implement rollback and commit
        die "add_key failed: $exception\n";
    };

    # build and return the key string
    # the unencoded string is in the format: users_key.id-users.id-key
    # TODO: this assumes the key was inserted, otherwise doesn't give an error back to the user.
    # this needs to be expanded to let the user know there was an issue, if there was one.
    if ($result) {
        my $plain_key = $self->_dbh->last_insert_id( undef, undef, 'users_key', 'id' ) . q{-} . $self->id . q{-} . $token;

        my $conf          = Trackability::API::Config->get();
        my $crypt_storage = Trackability::API::Crypt::Storage->new( secret_key => $conf->{token}{secret_key} );
        my $encoded_key   = $crypt_storage->encode( string => $plain_key );

        return $encoded_key;
    }

    return;
}

sub validate_key {
    my $class = shift;
    my $arg   = {
        key => undef,
        @_,
    };

    unless ( $arg->{key} ) {
        Trackability::API::Exception::Missing->throw( { message => "key is required" } );
    }

    # decode key
    my $conf          = Trackability::API::Config->get();
    my $crypt_storage = Trackability::API::Crypt::Storage->new( secret_key => $conf->{token}{secret_key} );
    my $plain_key     = $crypt_storage->decode( string => $arg->{key} ) || q{};

    my ( $users_key_id, $users_id, $token ) = split( /-/, $plain_key );

    unless ( $users_key_id && $users_id && $token ) {
        Trackability::API::Exception::Invalid->throw( { message => "key is invalid" } );
    }

    # first, verify the user exists using the decoded key
    my $users = $class->get( id => $users_id );

    unless ( $users->[0] ) {
        Trackability::API::Exception::Missing->throw();
    }

    # next, get the key
    my $sql = q{
        SELECT
            `key`
        FROM
            users_key
        WHERE
            id = ? AND
            users_id = ?
    };

    my $hash = try {
        my $users_key_arrref = $class->_dbh->selectrow_arrayref( $sql, undef, ( $users_key_id, $users_id ) );
        return $users_key_arrref->[0];
    }
    catch {
        my $exception = $_;

        # TODO: implement rollback and commit
        die "validate_key failed: $exception\n";
    };

    unless ($hash) {
        Trackability::API::Exception::Missing->throw( { message => "key does not exist" } );
    }

    my $crypt_hash = Trackability::API::Crypt::Hash->new();

    # if the decoded token validates with what we have stored, return the user object to the caller.
    if ( $crypt_hash->validate( hash => $hash, string => $token ) ) {
        return $users;
    }

    return;
}

1;
