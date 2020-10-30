package Trackability::API::Test;

use strict;
use warnings;

use parent 'Test::More';

our $VERSION = '0.001';

our ( $config, $dbh );

my $skip_db = 0;

sub import {
    my $class = shift;
    my %args  = @_;

    if ( $args{tests} ) {
        $class->builder->plan( tests => $args{tests} )
            unless $args{tests} eq 'no_declare';
    }
    elsif ( $args{skip_all} ) {
        $skip_db = 1;  # set skip_db so the END block will not fail on the selectrow
        $class->builder->plan( skip_all => $args{skip_all} );
    }

    if ( $args{skip_db} ) {
        $skip_db = 1;
    }
    else {
        override_database( %args );
    }

    Test::More->export_to_level(1);

    require Test::Exception;
    Test::Exception->export_to_level(1);

    require Test::Deep;
    Test::Deep->export_to_level(1);

    require Test::Warnings;

    return;
}

sub override_database {
    my %args = @_;

    require Trackability::API::DB;
    require Trackability::API::Config;

    $config = Trackability::API::Config->_load_config();

    unless ( exists $config->{database_test} ) {
        Test::More::BAIL_OUT("database_test section is missing from the config");
    }

    foreach my $key (qw( type host port dbname username password )) {
        unless ( exists $config->{database_test}{$key} && defined $config->{database_test}{$key} ) {
            Test::More::BAIL_OUT("$key key is required in the database_test section of config");
        }
    }

    my $driver   = $config->{database_test}{type};
    my $host     = $config->{database_test}{host};
    my $port     = $config->{database_test}{port};
    my $database = $config->{database_test}{dbname};
    my $username = $config->{database_test}{username};
    my $password = $config->{database_test}{password};

    # Trackability::API::DB::load needs to be overridden to return the values for the test db
    override(
        package => 'Trackability::API::DB',
        name    => 'load',
        subref  => sub {
                       return (
                           "DBI:"
                               . $driver
                               . ":database="
                               . $database
                               . ";host="
                               . $host
                               . ";port="
                               . $port,
                           $username, $password
                       );
                   }
    );

    # load is overridden, so we can use the normal connect_db sub to create the dbh
    $dbh = Trackability::API::DB::connect_db();
    Test::More::note("connected to test db: $database on $host");

    return;
}

sub override {
    my %args = (
        package => undef,
        name    => undef,
        subref  => undef,
        @_,
    );

    eval "require $args{package}";

    my $fullname = sprintf "%s::%s", $args{package}, $args{name};

    no strict 'refs';
    no warnings 'redefine', 'prototype';
    *$fullname = $args{subref};

    return;
}

sub write_config {
    my %args = (
        config => undef,
        @_,
    );

    use FindBin;
    require File::Temp;

    my $temp_dir = File::Temp->newdir(
        DIR => $FindBin::RealBin,
    );
    my $rc = "$temp_dir/.trackability-apirc";

    require Config::Tiny;

    my $config_tiny = Config::Tiny->new;
    %{$config_tiny} = %{$args{config}};

    die( "unable to write config\n" )
        unless $config_tiny->write( $rc );

    return $rc;
}

# clean up the test DB after each test to make sure we have an accurate test set.
END {
    unless ( $skip_db ) {
        my ( $database ) = @{ $dbh->selectrow_arrayref( 'select DATABASE()' ) };
        exit if $database ne $Trackability::API::Test::config->{database_test}{dbname};

        if ( $dbh->do( 'delete from users' ) ) {
            Test::More::note( "deleted users table on $database" );

            $dbh->do( 'ALTER TABLE users AUTO_INCREMENT = 1' );
            $dbh->do( 'ALTER TABLE collections AUTO_INCREMENT = 1' );
            $dbh->do( 'ALTER TABLE events AUTO_INCREMENT = 1' );
        }
        else {
            Test::More::note( 'ERROR: did not delete users table' );
        }
    }
}

1;
