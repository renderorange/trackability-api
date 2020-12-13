package Trackability::API::Model::Events;

use strictures version => 2;

use Types::Common::Numeric qw{ PositiveInt };
use Types::Common::String qw{ NonEmptyStr };
use JSON::Parse                ();
use DateTime::Format::Strptime ();

use Trackability::API::DB                 ();
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

has collections_id => (
    is       => 'rw',
    required => 1,
    isa      => PositiveInt,
    writer   => '_set_collections_id',
);

has data => (
    is       => 'rw',
    required => 1,
    isa      => sub {
        my $json = $_[0];
        try {
            JSON::Parse::assert_valid_json($json);
        }
        catch {
            my $exception = $_;
            die "not a valid JSON structure: $exception\n";
        };
    },
    writer => '_set_data',
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
        id             => undef,
        collections_id => undef,
        @_,
    };

    my $sql = q{
        SELECT
            id,
            collections_id,
            data,
            created_at,
            updated_at
        FROM
            events
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

    my @events = @{ $class->_dbh->selectall_arrayref( $sql, { Slice => {} }, @bind_values ) };

    unless (@events) {
        return;
    }

    return [ map { $class->new( %{$_} ) } @events ];
}

sub store {
    my $self = shift;

    foreach my $attribute ( 'collections_id', 'data' ) {
        unless ( defined $self->{$attribute} ) {
            Trackability::API::Exception::Missing->throw( { message => "$attribute is required" } );
        }
    }

    # check if collections_id is known before storing.
    my $check_sql    = q{ SELECT count(id) from collections where id = ? };
    my $check_result = try {
        return $self->_dbh->selectrow_array( $check_sql, undef, ( $self->collections_id ) );
    }
    catch {
        my $exception = $_;

        # TODO: implement rollback and commit
        die "check collections_id failed: $exception\n";
    };

    unless ($check_result) {
        Trackability::API::Exception::Invalid->throw( { message => "collections_id argument is not a known collection." } );
    }

    my ( $sql, @bind_values );

    if ( $self->id ) {
        $sql = q{
            UPDATE
                events
            SET
                collections_id = ?,
                data = ?
            WHERE
                id = ?
        };

        @bind_values = ( $self->collections_id, $self->data, $self->id );
    }
    else {
        $sql = q{
            INSERT INTO
                events
            SET
                collections_id = ?,
                data = ?
        };

        @bind_values = ( $self->collections_id, $self->data );
    }

    my $result = try {
        return $self->_dbh->do( $sql, undef, @bind_values );
    }
    catch {
        my $exception = $_;

        # TODO: implement rollback and commit
        die "store events failed: $exception\n";
    };

    # set id into the object if this is a new record.
    # for now, we're going to leave the parameters for last_insert_id
    # here even though mysql will ignore them.  there are other databases
    # which may require, so a broader support here is better.
    my $insert = $self->_dbh->last_insert_id( undef, undef, 'events', 'id' );

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
    my @columns = (qw{ collections_id data created_at updated_at });

    my $query = 'select ' . ( join ', ', @columns ) . ' from events where id = ?';

    my $set_record = $self->_dbh->selectrow_hashref( $query, undef, $self->id );

    foreach my $update (@columns) {
        my $setter = '_set_' . $update;
        $self->$setter( $set_record->{$update} );
    }

    return;
}

1;
