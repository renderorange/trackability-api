package Trackability::API::Config;

use strictures version => 2;

use Cwd                   ();
use Config::Tiny          ();
use Data::Structure::Util ();

our $VERSION = '0.001';

sub get {
    my $config = _load_config();
    _validate($config);

    return $config;
}

sub _load_config {
    my $module_path = Cwd::realpath(__FILE__);
    $module_path =~ s/\w+\.pm//;
    my $rc = Cwd::realpath( $module_path . '/../../../.trackability-apirc' );

    unless ( -f $rc ) {
        die "$rc is not present";
    }

    return Data::Structure::Util::unbless( Config::Tiny->read($rc) );
}

sub _validate {
    my $config = shift;

    # verify required config sections
    foreach my $required (qw{ database token }) {
        unless ( exists $config->{$required} ) {
            die "config section $required is required\n";
        }
    }

    # verify database values
    foreach my $required (qw{ type host port dbname username password }) {
        unless ( exists $config->{database}{$required} && $config->{database}{$required} ) {
            die "config section database $required is required\n";
        }
    }

    # verify token values
    foreach my $required (qw{ secret_key }) {
        unless ( exists $config->{token}{$required} && $config->{token}{$required} ) {
            die "config section database $required is required\n";
        }
    }

    return 1;
}

1;
