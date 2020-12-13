package Trackability::API::Model::Collections;

use strictures version => 2;

use Types::Common::Numeric qw{ PositiveInt };
use Types::Common::String qw{ NonEmptyStr };
use DateTime::Format::Strptime ();

use Trackability::API::DB                 ();
use Trackability::API::Exception::Missing ();
use Trackability::API::Exception::Invalid ();

use Try::Tiny;
use List::MoreUtils ();

use Moo;
use MooX::ClassAttribute;
use namespace::clean;

our $VERSION = '0.001';

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

has users_id => (
    is       => 'rw',
    required => 1,
    isa      => PositiveInt,
    writer   => '_set_users_id',
);

has created_at => (
    is  => 'rwp',
    isa => sub {
        my $strp = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S' );
        unless ( $strp->parse_datetime( $_[0] ) ) {
            die "not a valid created_at type\n";
        }
    },
);

has updated_at => (
    is  => 'rwp',
    isa => sub {
        my $strp = DateTime::Format::Strptime->new( pattern => '%Y-%m-%d %H:%M:%S' );
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
        id       => undef,
        name     => undef,
        users_id => undef,
        @_,
    };

    my $sql = q{
        SELECT
            id,
            name,
            users_id,
            created_at,
            updated_at
        FROM
            collections
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

    my @collections = @{ $class->_dbh->selectall_arrayref( $sql, { Slice => {} }, @bind_values ) };

    unless (@collections) {
        return;
    }

    return [ map { $class->new( %{$_} ) } @collections ];
}

sub store {
    my $self = shift;

    foreach my $attribute ( 'name', 'users_id' ) {
        unless ( defined $self->{$attribute} ) {
            Trackability::API::Exception::Missing->throw( { message => "$attribute is required" } );
        }
    }

    my ( $sql, @bind_values );

    if ( $self->id ) {
        $sql = q{
            UPDATE
                collections
            SET
                name = ?,
                users_id = ?
            WHERE
                id = ?
        };

        @bind_values = ( $self->name, $self->users_id, $self->id );
    }
    else {
        $sql = q{
            INSERT INTO
                collections
            SET
                name = ?,
                users_id = ?
        };

        @bind_values = ( $self->name, $self->users_id );
    }

    my $result = try {
        return $self->_dbh->do( $sql, undef, @bind_values );
    }
    catch {
        my $exception = $_;

        # TODO: implement rollback and commit
        die "store collection failed: $exception\n";
    };

    # set id into the object if this is a new record.
    # for now, we're going to leave the parameters for last_insert_id
    # here even though mysql will ignore them.  there are other databases
    # which may require, so a broader support here is better.
    my $insert = $self->_dbh->last_insert_id( undef, undef, 'collections', 'id' );

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
    my @columns = (qw{ name users_id created_at updated_at });

    my $query = 'select ' . ( join ', ', @columns ) . ' from collections where id = ?';

    my $collection_record = $self->_dbh->selectrow_hashref( $query, undef, $self->id );

    foreach my $update (@columns) {
        my $setter = '_set_' . $update;
        $self->$setter( $collection_record->{$update} );
    }

    return;
}

1;
