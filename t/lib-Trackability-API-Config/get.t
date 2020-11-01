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
};

Trackability::API::Test::override(
    package => 'Trackability::API::Config',
    name    => '_load_config',
    subref  => sub { return $config_expected },
);

Trackability::API::Test::override(
    package => 'Trackability::API::Config',
    name    => '_validate',
    subref  => sub { return 1 },
);

HAPPY_PATH: {
    note( 'happy path' );

    my $obj = $class->get();
    cmp_deeply( $obj, noclass($config_expected), 'returned config contains expected data structure' );
}

done_testing;
