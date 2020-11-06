use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../lib", "$FindBin::RealBin/../../lib";
use Trackability::API::Test skip_db => 1;

my $class = 'Trackability::API::DB';
use_ok( $class );

my $config_expected = {
    database => {
        type => 'mysql',
        host => 'localhost',
        port => 3306,
        dbname => 'trackability',
        username => 'trackability',
        password => 'password',
    },
};

HAPPY_PATH: {
    note( 'happy path' );

    Trackability::API::Test::override(
        package => 'Trackability::API::Config',
        name    => 'get',
        subref  => sub { return $config_expected },
    );

    my ( $dsn, $username, $password ) = Trackability::API::DB::load();

    # DBI:mysql:database=trackability;host=127.0.0.1;port=3306
    my $expected_dsn = "DBI:"
                           . $config_expected->{database}{type}
                           . ":database="
                           . $config_expected->{database}{dbname}
                           . ";host="
                           . $config_expected->{database}{host}
                           . ";port="
                           . $config_expected->{database}{port};
    is( $dsn, $expected_dsn, 'dsn is returned containing the expected parts and format' );

    ok( $username, 'username is returned' );
    ok( $password, 'password is returned' );
}

done_testing;
