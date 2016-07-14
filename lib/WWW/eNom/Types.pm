package WWW::eNom::Types;

use strict;
use warnings;

use Data::Validate::Domain qw( is_domain );
use Data::Validate::Email qw( is_email );
use URI;

# VERSION
# ABSTRACT: WWW::eNom Moose Type Library

use MooseX::Types -declare => [qw(
    ArrayRef
    Bool
    HashRef
    Int
    PositiveInt
    Str
    Strs

    ContactType
    DateTime
    DomainName
    DomainNames
    EmailAddress
    HTTPTiny
    NumberPhone
    ResponseType
    URI

    Contact
    DomainAvailability
    DomainAvailabilities
    DomainRegistration
    PhoneNumber
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

enum ContactType, [qw( Registrant Tech Admin AuxBilling )];

subtype DomainName, as Str,
    where { is_domain( $_ ) },
    message { "$_ is not a valid domain" };
subtype DomainNames, as ArrayRef[DomainName];

subtype EmailAddress, as Str,
    where { is_email( $_ ) },
    message { "$_ is not a valid email address" };

subtype PositiveInt, as Int,
    where { $_ > 0 },
    message { "$_ is not a positive integer" };

my @response_types = qw( xml xml_simple html text );
subtype ResponseType, as Str,
    where {
        my $response_type = $_;
        grep { $response_type eq $_ } @response_types;
    },
    message { 'response_type must be one of: ' . join ', ', @response_types };

class_type DateTime,    { class => 'DateTime' };
class_type HTTPTiny,    { class => 'HTTP::Tiny' };
class_type NumberPhone, { class => 'Number::Phone' };
class_type URI,         { class => 'URI' };
coerce URI, from Str, via { URI->new( $_ ) };

class_type Contact,            { class => 'WWW::eNom::Contact' };
class_type DomainAvailability, { class => 'WWW::eNom::DomainAvailability' };
subtype DomainAvailabilities, as ArrayRef[DomainAvailability];
class_type DomainRegistration, { class => 'WWW::eNom::DomainRequest::Registration' };
class_type PhoneNumber,        { class => 'WWW::eNom::PhoneNumber' };
coerce PhoneNumber, from Str,
    via { WWW::eNom::PhoneNumber->new( $_ ) };
coerce PhoneNumber, from NumberPhone,
    via { WWW::eNom::PhoneNumber->new( $_->format ) };

1;

__END__
