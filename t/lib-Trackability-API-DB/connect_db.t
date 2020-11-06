use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../lib", "$FindBin::RealBin/../../lib";
use Trackability::API::Test skip_db => 1;

my $class = 'Trackability::API::DB';
use_ok( $class );

HAPPY_PATH: {
    note( 'happy path' );

    my $dbh = Trackability::API::DB::connect_db();

    isa_ok( $dbh, 'DBI::db' );
    ok( ( exists $dbh->{mysql_auto_reconnect} && $dbh->{mysql_auto_reconnect} ), 'mysql_auto_reconnect is set in the dbh' );
}

EXCEPTIONS: {
    note( 'exceptions' );

    Trackability::API::Test::override(
        package => 'DBI',
        name    => 'connect',
        subref  => sub { die "fake your own death\n" },
    );

    dies_ok( sub { Trackability::API::DB::connect_db() }, 'dies if DBI->connect fails' );
}

done_testing;
