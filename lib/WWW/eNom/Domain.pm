package WWW::eNom::Domain;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Params::Validate;
use namespace::autoclean;

use WWW::eNom::Types qw( Bool Contact DateTime DomainName DomainNames HashRef PositiveInt Str );

use WWW::eNom::Contact;
use DateTime;
use DateTime::Format::DateParse;

use Try::Tiny;
use Carp;

# DomainNameID
has 'id' => (
    is       => 'ro',
    isa      => PositiveInt,
    required => 1,
);

# SLD.TLD
has 'name' => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

# RegistrationStatus
has 'status' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

# ???
has 'verification_status' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'is_auto_renew' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has 'is_locked' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

# Extracted from Services, look for WPPS 1120 (on) / 1123 (off)
has 'is_private' => (
    is       => 'ro',
    isa      => Bool,
    required => 1,
);

has 'created_date' => (
    is       => 'ro',
    isa      => DateTime,
    required => 1,
);

# Expiration
has 'expiration_date' => (
    is       => 'ro',
    isa      => DateTime,
    required => 1,
);

has 'ns' => (
    is       => 'ro',
    isa      => DomainNames,
    required => 1,
);

# GetContacts
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

sub construct_from_response {
    my $self     = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_info   => { isa => HashRef },
        is_auto_renew => { isa => Bool },
        is_locked     => { isa => Bool },
        name_servers  => { isa => DomainNames },
        contacts      => { isa => HashRef },
        created_date  => { isa => DateTime },
    );

    return try {
        return $self->new({
            id                  => $args{domain_info}{domainname}{domainnameid},
            name                => $args{domain_info}{domainname}{content},
            status              => $args{domain_info}{status}{registrationstatus},
            verification_status => $args{domain_info}{services}{entry}{raasettings}{raasetting}{verificationstatus},
            is_auto_renew       => $args{is_auto_renew},
            is_locked           => $args{is_locked},
            is_private          => ( $args{domain_info}{services}{entry}{wpps}{service}{content} == 1120 ),
            created_date        => $args{created_date},
            expiration_date     => DateTime::Format::DateParse->parse_datetime( $args{domain_info}{status}{expiration} ),
            ns                  => $args{name_servers},
            registrant_contact  => $args{contacts}{registrant_contact},
            admin_contact       => $args{contacts}{admin_contact},
            technical_contact   => $args{contacts}{technical_contact},
            billing_contact     => $args{contacts}{billing_contact},
        });
    }
    catch {
        croak "Error constructing domain from response: $_";
    };
}

__PACKAGE__->meta->make_immutable;
1;

__END__
