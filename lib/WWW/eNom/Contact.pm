package WWW::eNom::Contact;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Params::Validate;
use namespace::autoclean;

use WWW::eNom::Types qw( ContactType EmailAddress HashRef PhoneNumber Str );

use WWW::eNom::PhoneNumber;

use Data::Util qw( is_string );
use Try::Tiny;
use Carp;

# VERSION
# ABSTRACT: eNom Contact

# FirstName
has 'first_name' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

# LastName
has 'last_name' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

# OrganizationName
has 'organization_name' => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_organization_name',
    clearer   => 'clear_organization_name',
);

# JobTitle
# Required if organization_name is specified 
has 'job_title' => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_job_title',
    clearer   => 'clear_job_title',
);

# Address1
has 'address1' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

# Address2
has 'address2' => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_address2',
    clearer   => 'clear_address2',
);

# City
has 'city' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

# StateProvince
has 'state' => (
    is        => 'rw',
    isa       => Str,
    predicate => 'has_state',
    clearer   => 'clear_state',
);

# Country
has 'country' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

# PostalCode
has 'zipcode' => (
    is       => 'rw',
    isa      => Str,
    required => 1,
);

# EmailAddress
has 'email' => (
    is       => 'rw',
    isa      => EmailAddress,
    required => 1,
);

# Phone
has 'phone_number' => (
    is       => 'rw',
    isa      => PhoneNumber,
    required => 1,
    coerce   => 1,
);

# Fax
# Required if OrganizationName is specified
has 'fax_number' => (
    is        => 'rw',
    isa       => PhoneNumber,
    predicate => 'has_fax_number',
    clearer   => 'clear_fax_number',
    coerce    => 1,
);

sub construct_creation_request {
    my $self = shift;
    my ( $contact_type ) = pos_validated_list( \@_, { isa => ContactType, optional => 1 } );

    my $creation_request = {
        FirstName    => $self->first_name,
        LastName     => $self->last_name,
        $self->has_organization_name ? ( OrganizationName => $self->organization_name ) : ( ),
        $self->has_job_title         ? ( JobTitle         => $self->job_title         ) : ( ),
        Address1     => $self->address1,
        $self->has_address2          ? ( Address2         => $self->address2          ) : ( ),
        City         => $self->city,
        $self->has_state             ? ( StateProvince    => $self->state             ) : ( ),
        Country      => $self->country,
        PostalCode   => $self->zipcode,
        EmailAddress => $self->email,
        Phone        => sprintf('+%s.%s', $self->phone_number->country_code, $self->phone_number->number ),
        $self->has_fax_number ? ( Fax => sprintf('+%s.%s', $self->fax_number->country_code, $self->fax_number->number ) ) : ( ),
    };

    if( $contact_type ) {
        for my $key ( keys %{ $creation_request } ) {
            $creation_request->{ $contact_type . $key } = delete $creation_request->{ $key };
        }
    }

    return $creation_request;
}

sub construct_from_response {
    my $self         = shift;
    my ( $response ) = pos_validated_list( \@_, { isa => HashRef } );

    return try {
        return $self->new({
            first_name        => $response->{'FirstName'},
            last_name         => $response->{'LastName'},
            is_string( $response->{'OrganizationName'} ) ? ( organization_name => $response->{'OrganizationName'} ) : ( ),
            is_string( $response->{'JobTitle'}         ) ? ( job_title         => $response->{'JobTitle'}         ) : ( ),
            address1          => $response->{'Address1'},
            is_string( $response->{'Address2'}         ) ? ( address2          => $response->{'Address2'}         ) : ( ),
            city              => $response->{'City'},
            is_string( $response->{'StateProvince'}    ) ? ( state             => $response->{'StateProvince'}    ) : ( ),
            country           => $response->{'Country'},
            zipcode           => $response->{'PostalCode'},
            email             => $response->{'EmailAddress'},
            phone_number      => $response->{'Phone'},
            is_string( $response->{'Fax'}             ) ? ( fax_number        => $response->{'Fax'}              ) : ( ),
        });
    }
    catch {
        croak "Error constructing contact from response: $_";
    };
}

__PACKAGE__->meta->make_immutable;
1;

__END__
