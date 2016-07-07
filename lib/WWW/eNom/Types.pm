package WWW::eNom::Types;

use strict;
use warnings;

use URI;

# VERSION
# ABSTRACT: WWW::eNom Moose Type Library

use MooseX::Types -declare => [qw(
    ArrayRef
    Bool
    HashRef
    Str
    Strs

    HTTPTiny
    ResponseType
    URI
)];

use MooseX::Types::Moose
    ArrayRef => { -as => 'MooseArrayRef' },
    Bool     => { -as => 'MooseBool' },
    HashRef  => { -as => 'MooseHashRef' },
    Str      => { -as => 'MooseStr' };

subtype ArrayRef, as MooseArrayRef;
subtype Bool,     as MooseBool;
subtype HashRef,  as MooseHashRef;
subtype Str,      as MooseStr;
subtype Strs,     as ArrayRef[Str];

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

1;

__END__
