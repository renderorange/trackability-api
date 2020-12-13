package Trackability::API::Crypt::Storage;

use strictures version => 2;

use Session::Storage::Secure ();

our $VERSION = '0.001';

sub new {
    my $class = shift;
    my $arg   = {
        secret_key => undef,
        @_,
    };

    unless ( $arg->{secret_key} ) {
        die "secret_key argument is required\n";
    }

    my $self = { _store_obj => Session::Storage::Secure->new( secret_key => $arg->{secret_key} ), };

    return bless $self, $class;
}

sub encode {
    my $self = shift;
    my $arg  = {
        string => undef,
        @_,
    };

    unless ( $arg->{string} ) {
        die "string argument is required\n";
    }

    return $self->{_store_obj}->encode( $arg->{string} );
}

sub decode {
    my $self = shift;
    my $arg  = {
        string => undef,
        @_,
    };

    unless ( $arg->{string} ) {
        die "string argument is required\n";
    }

    return $self->{_store_obj}->decode( $arg->{string} );
}

1;

=pod

=head1 NAME

Trackability::API::Crypt::Storage - secure string encoding and decoding

=head1 SYNOPSIS

 use Trackability::API::Crypt::Storage;

 my $store = Trackability::API::Crypt::Storage->new(
     secret_key => $secret_key,
 );

 my $encoded = $store->encode( string => $string );
 my $decoded = $store->decode( string => $encoded );

=head1 DESCRIPTION

This module provides secure encoding and decoding for strings.

=head1 SUBROUTINES/METHODS

=head2 new

=head3 ARGUMENTS

=over

=item secret_key

The secret_key to use to encode and decode.

=back

=head3 RETURNS

A C<Trackability::API::Crypt::Storage> object.

=head2 encode

Method to encode strings.

=head3 ARGUMENTS

=over

=item string

The plain text string for encrypting.

=back

=head3 RETURNS

The encoded string.

=head2 decode

Method to decode strings.

=head3 ARGUMENTS

=over

=item string

The encoded string for decrypting.

=back

=head2 RETURNS

The decoded string.

=head1 AUTHOR

Blaine Motsinger C<blaine@renderorange.com>

=cut
