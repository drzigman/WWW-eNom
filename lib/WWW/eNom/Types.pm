package WWW::eNom::Types;

use strict;
use warnings;

use Data::Validate::Domain qw( is_domain );
use URI;

# VERSION
# ABSTRACT: WWW::eNom Moose Type Library

use MooseX::Types -declare => [qw(
    ArrayRef
    Bool
    HashRef
    Int
    Str
    Strs

    DomainName
    HTTPTiny
    ResponseType
    URI

    DomainAvailability
    DomainAvailabilities
)];

use MooseX::Types::Moose
    ArrayRef => { -as => 'MooseArrayRef' },
    Bool     => { -as => 'MooseBool' },
    HashRef  => { -as => 'MooseHashRef' },
    Int      => { -as => 'MooseInt' },
    Str      => { -as => 'MooseStr' };

subtype ArrayRef, as MooseArrayRef;
subtype Bool,     as MooseBool;
subtype HashRef,  as MooseHashRef;
subtype Int,      as MooseInt;
subtype Str,      as MooseStr;
subtype Strs,     as ArrayRef[Str];

subtype DomainName, as Str,
    where { is_domain( $_ ) },
    message { "$_ is not a valid domain" };

my @response_types = qw( xml xml_simple html text );
subtype ResponseType, as Str,
    where {
        my $response_type = $_;
        grep { $response_type eq $_ } @response_types;
    },
    message { 'response_type must be one of: ' . join ', ', @response_types };

class_type HTTPTiny, { class => 'HTTP::Tiny' };
class_type URI, { class => 'URI' };
coerce URI, from Str, via { URI->new( $_ ) };

class_type DomainAvailability, { class => 'WWW::eNom::DomainAvailability' };
subtype DomainAvailabilities, as ArrayRef[DomainAvailability];

1;

__END__
