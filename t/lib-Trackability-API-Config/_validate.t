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

HAPPY_PATH: {
    note( 'happy path' );

    lives_ok { Trackability::API::Config::_validate( $config_expected ) }
        'expected keys and values all validate';
}

EXCEPTIONS: {
    note( 'exceptions' );

    subtest 'dies if missing any of the config keys' => sub {
        plan tests => 1;

        foreach my $required ( keys %{ $config_expected } ) {
            my $stored = delete $config_expected->{ $required };

            dies_ok { Trackability::API::Config::_validate( $config_expected ) }
                "dies if config is missing $required key";

            $config_expected->{ $required } = $stored;
        }
    };

    subtest 'dies if missing any of the config sub keys' => sub {
        plan tests => 6;

        foreach my $required ( keys %{ $config_expected } ) {
            foreach my $required_sub_key ( keys %{ $config_expected->{$required} } ) {
                my $stored = delete $config_expected->{$required}{$required_sub_key};

                dies_ok { Trackability::API::Config::_validate( $config_expected ) }
                    "dies if config is missing $required $required_sub_key key";

                $config_expected->{$required}{$required_sub_key} = $stored;
            }
        }
    };
}

done_testing;
