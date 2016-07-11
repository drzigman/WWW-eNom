package WWW::eNom::Role::ParseDomain;

use strict;
use warnings;

use Moose::Role;
use MooseX::Aliases;

use WWW::eNom::Types qw( Str );

use Mozilla::PublicSuffix;

requires 'name';

has 'sld' => (
    is       => 'ro',
    isa      => Str,
    builder  => '_build_sld',
    lazy     => 1,
    init_arg => undef,
);

has 'public_suffix' => (
    is       => 'ro',
    isa      => Str,
    alias    => 'tld',
    builder  => '_build_public_suffix',
    lazy     => 1,
    init_arg => undef,
);

sub _build_sld {
    my $self = shift;

    return substr( $self->name, 0, length( $self->name ) - ( length( $self->public_suffix ) + 1 ) );
}

sub _build_public_suffix {
    my $self = shift;

    return Mozilla::PublicSuffix::public_suffix( $self->name );
}

1;
