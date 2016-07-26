package WWW::eNom::DomainRequest::Registration;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::eNom::Types qw( Bool Contact DomainName DomainNames Int );

# VERSION
# ABSTRACT: Domain Registration Request

has 'name' => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

has 'ns' => (
    is        => 'ro',
    isa       => DomainNames,
    predicate => 'has_ns',
);

has 'is_ns_fail_fatal' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has 'is_locked' => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has 'is_private' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has 'is_auto_renew' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has 'is_queueable' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has 'years' => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has 'registrant_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

has 'admin_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

has 'technical_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

has 'billing_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

with 'WWW::eNom::Role::ParseDomain';

sub construct_request {
    my $self = shift;

    return {
        SLD => $self->sld,
        TLD => $self->tld,
        !$self->has_ns
            ? ( UseDNS => 'default' )
            : ( map { 'NS' . ( $_ + 1 ) => $self->ns->[ $_ ] } 0 .. ( scalar (@{ $self->ns }) - 1) ),
        IgnoreNSFail    => ( $self->is_ns_fail_fatal ? 'No' : 'Yes' ),
        UnLockRegistrar => ( $self->is_locked        ? 0    : 1     ),
        RenewName       => ( $self->is_auto_renew    ? 1    : 0     ),
        AllowQueueing   => ( $self->is_queueable     ? 1    : 0     ),
        NumYears        => $self->years,
        %{ $self->registrant_contact->construct_creation_request('Registrant') },
        %{ $self->admin_contact->construct_creation_request('Admin')           },
        %{ $self->technical_contact->construct_creation_request('Tech')        },
        %{ $self->billing_contact->construct_creation_request('AuxBilling')    },
    };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

WWW::eNom::DomainRequest::Registration - Domain Registration Request

=head1 SYNOPSIS

    use WWW::eNom;
    use WWW::eNom::Contact;
    use WWW::eNom::DomainRequest::Registration;

    my $api     = WWW::eNom->new( ... );
    my $contact = WWW::eNom::Contact->new( ... );

    # Register a New Domain
    my $registration_request = WWW::eNom::DomainRequest::Registration->new(
        name               => 'drzigman.com',
        ns                 => [ 'ns1.enom.com', 'ns2.enom.com' ],
        is_ns_fail_fatal   => 0,   # Optional, defaults to false
        is_locked          => 1,   # Optional, defaults to true
        is_private         => 1,   # Optional, defaults to false
        is_auto_renew      => 0,   # Optional, defaults to false
        is_queueable       => 0,   # Optional, defaults to false
        years              => 1,
        registrant_contact => $contact,
        technical_contact  => $contact,
        admin_contact      => $contact,
        billing_contact    => $contact,
    );

    # Real way of using this module to register a domain
    my $domain = $api->register_domain( request => $registration_request );


    # Example showing construct_request, contrived!  Use register_domain in real life!
    my $response = $api->submit({
        method => 'Purchase',
        params => $registration_request->construct_request(),
    });

=head1 WITH

=over 4

=item L<WWW::eNom::Role::ParseDomain>

=back

=head1 DESCRIPTION

WWW::eNom::DomainRequest::Registration is a representation of all the data needed in order to complete a domain registration.  It is used when requesting a new registration from L<eNom|https://www.enom.com>.

=head1 ATTRIBUTES

=head2 B<name>

The FQDN to register.

=head2 ns

ArrayRef of Domain Names that are to be authoritative nameservers for this domain.

Predicate of has_ns.  If not specified, L<eNom|https://www.enom.com>'s nameservers (or whatever you specially configured in your L<eNom Reseller Panel|https://www.enom.com/login.aspx>) will be used.

=head2 is_ns_fail_fatal

Boolean that defaults to false.  If set to true, the provided ns values must resolve otherwise the domain registration request will fail.

=head2 is_locked

Boolean that defaults to true.  Indicates if the domain should be locked, preventing transfers.

=head2 is_private

Boolean that defaults to false.  If true, the L<WPPS Service|https://www.enom.com/api/Value%20Added%20Topics/ID%20Protect.htm> (what eNom calls Privacy Protection) will automatically be purchased and enabled.

=head2 is_auto_renew

Boolean that defaults to false.  If true, this domain will be automatically renewed by eNom before it expires.

=head2 is_queueable

Boolean that defaults to false.  If true, eNom will "queue" domain registration requests that it can not be complete in real time (example: the registry connectivity is down).

=head2 B<years>

The number of years to register the domain for.  Keep in mind there are limits (based on the Public Suffix) but generally this is a Positive Integer between 1 and 10.

=head2 B<registrant_contact>

A L<WWW::eNom::Contact> for the Registrant Contact.

=head2 B<admin_contact>

A L<WWW::eNom::Contact> for the Admin Contact.

=head2 B<technical_contact>

A L<WWW::eNom::Contact> for the Technical Contact.

=head2 B<billing_contact>

A L<WWW::eNom::Contact> for the Billing Contact.

B<NOTE> L<eNom|https://www.eNom.com> actually calls this the B<AuxBilling> contact since the primary billing contact is the reseller's information.

=head1 METHODS

=head2 construct_request

    my $registration_request = WWW::eNom::DomainRequest::Registration->new( ... );

    my $response = $api->submit({
        method => 'Purchase',
        params => $registration_request->construct_request(),
    });

Converts $self into a HashRef suitable for the L<Purchase|https://www.enom.com/api/API%20topics/api_Purchase.htm> of a Domain Name.

=cut
