package WWW::eNom::Role::Command::Contact;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( DomainName );

use WWW::eNom::Contact;

use Try::Tiny;
use Carp;

use Readonly;
Readonly my $ENOM_CONTACT_TYPE_MAPPING => {
    Registrant => 'registrant_contact',
    Admin      => 'admin_contact',
    Tech       => 'technical_contact',
    AuxBilling => 'billing_contact',
};

requires 'submit';

# VERSION
# ABSTRACT: Contact API Calls

sub get_contacts_by_domain_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetContacts',
            params => {
                Domain => $domain_name
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            croak 'Unknown error';
        }

        my $billing_party_id = $response->{GetContacts}{Billing}{BillingPartyID};

        my $contacts;
        for my $contact_type ( keys %{ $ENOM_CONTACT_TYPE_MAPPING } ) {
            my $raw_contact_response = $response->{GetContacts}{$contact_type};

            my $common_contact_response;
            for my $field ( keys %{ $raw_contact_response } ) {
                if( $field !~ m/$contact_type/ ) {
                    next;
                }

                $common_contact_response->{ substr( $field, length( $contact_type ) ) } =
                    $raw_contact_response->{ $field } // { };
            }

            # If no other contact has been provided then MY information (the reseller)
            # is used.  Treat this as no info.
            if( $common_contact_response->{PartyID} eq $billing_party_id ) {
                next;
            }

            $contacts->{ $ENOM_CONTACT_TYPE_MAPPING->{ $contact_type} } =
                WWW::eNom::Contact->construct_from_response( $common_contact_response );
        }

        # Check for anyone who used the reseller's contact info for a contact and replace
        # it with the registrant contact data.
        for my $contact_type ( values %{ $ENOM_CONTACT_TYPE_MAPPING } ) {
            if( !exists $contacts->{ $contact_type } ) {
                $contacts->{ $contact_type }  = $contacts->{registrant_contact};
                # TODO: Save this contact back, a sort of just in time repair
            }
        }

        return $contacts;
    }
    catch {
        croak $_;
    }
}

1;

__END__
