package Trackability::API::DB;

use strictures version => 2;

use Trackability::API::Config;

use DBI;

our $VERSION = '0.001';

sub connect_db {
    my ( $dsn, $username, $password ) = load();

    my $dbh = DBI->connect( $dsn, $username, $password, { RaiseError => 1, AutoCommit => 1 } )
        or die "connect db: $DBI::errstr\n";

    $dbh->{mysql_auto_reconnect} = 1;

    return $dbh;
}

sub load {
    my $conf = Trackability::API::Config->get();

    return (
        "DBI:"
            . $conf->{database}{type}
            . ":database="
            . $conf->{database}{dbname}
            . ";host="
            . $conf->{database}{host}
            . ";port="
            . $conf->{database}{port},
        $conf->{database}{username}, $conf->{database}{password}
    );
}

1;
