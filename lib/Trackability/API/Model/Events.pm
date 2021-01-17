package Trackability::API::Model::Events;

use strictures version => 2;

use Types::Common::Numeric qw{ PositiveInt };
use Types::Common::String qw{ NonEmptyStr };
use JSON::Parse ();

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
    isa => PositiveInt,
);

has updated_at => (
    is  => 'rwp',
    isa => PositiveInt,
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
        created_at     => undef,
        @_,
    };

    my $sql = q{
        SELECT
            id,
            collections_id,
            data,
            UNIX_TIMESTAMP(created_at) as created_at,
            UNIX_TIMESTAMP(updated_at) as updated_at
        FROM
            events
    };

    my ( @where, @bind_values );

    # special handling of created_at, since we need to convert
    # from unixtime to datetime.
    my $created_at = delete $arg->{created_at};

    # allow a start and end epoch time to do date searches between
    if ( $created_at && ref $created_at ) {

        # if both are defined, select everything including and between them
        if ( $created_at->[0] && $created_at->[1] ) {
            push @where, "created_at >= FROM_UNIXTIME(?) AND created_at <= FROM_UNIXTIME(?)";
            push @bind_values, ( $created_at->[0], $created_at->[1] );
        }

        # if the first is undef, select everything older than and equal to the second
        elsif ( !$created_at->[0] && $created_at->[1] ) {
            push @where,       "created_at <= FROM_UNIXTIME(?)";
            push @bind_values, $created_at->[1];
        }

        # if the second is undef, select everything newer than and equal to the first
        elsif ( !$created_at->[1] && $created_at->[0] ) {
            push @where,       "created_at >= FROM_UNIXTIME(?)";
            push @bind_values, $created_at->[0];
        }
    }

    # otherwise, an exact match on created_at
    elsif ($created_at) {
        push @where,       "created_at = FROM_UNIXTIME(?)";
        push @bind_values, $created_at;
    }

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
    my @columns = (qw{ collections_id data });

    my $query =
          'select '
        . ( join ', ', @columns, 'UNIX_TIMESTAMP(created_at) as created_at', 'UNIX_TIMESTAMP(updated_at) as updated_at' )
        . ' from events where id = ?';

    my $set_record = $self->_dbh->selectrow_hashref( $query, undef, $self->id );

    foreach my $update ( @columns, 'created_at', 'updated_at' ) {
        my $setter = '_set_' . $update;
        $self->$setter( $set_record->{$update} );
    }

    return;
}

1;
