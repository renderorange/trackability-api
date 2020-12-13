use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../lib", "$FindBin::RealBin/../../lib";
use Trackability::API::Test skip_db => 1;

my $class = 'Trackability::API::Config';
use_ok( $class );

my $config_expected = {
    database => {
        type => 'mysql',
        host => '127.0.0.1',
        port => 3306,
        dbname => 'trackability',
        username => 'trackability',
        password => 'password',
    },
    token => {
        secret_key => 'simplefordevelopment',
    },
};

my $trackabilityapi_rc = Trackability::API::Test::write_config( config => $config_expected );

Trackability::API::Test::override(
    package => 'Cwd',
    name    => 'realpath',
    subref  => sub { return $trackabilityapi_rc },
);

HAPPY_PATH: {
    note( 'happy path' );

    my $config = Trackability::API::Config::_load_config();

    cmp_deeply( $config, $config_expected, 'returned config matches expected' );
}

EXCEPTIONS: {
    note( 'exceptions' );

    unlink $trackabilityapi_rc;

    dies_ok { Trackability::API::Config::_load_config() } 'dies if .trackabilityapi-rc is not present';
}

done_testing;
