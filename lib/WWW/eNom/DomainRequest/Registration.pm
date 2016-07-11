package WWW::eNom::DomainRequest::Registration;

use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::eNom::Types qw( Bool Contact DomainName DomainNames Int );

# VERSION
# ABSTRACT: Domain Registration Request

# SLD/TLD
has 'name' => (
    is       => 'ro',
    isa      => DomainName,
    required => 1,
);

# UseDNS, NSX
has 'ns' => (
    is        => 'ro',
    isa       => DomainNames,
    predicate => 'has_ns',
);

# IgnoreNSFail
has 'is_ns_fail_fatal' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# UnLockRegistrar
has 'is_locked' => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

# http://www.enom.com/APICommandCatalog/Value%20Added%20Topics/ID%20Protect.htm?Highlight=id%20protect
has 'is_private' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# RenewName
has 'is_auto_renew' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# NumYears
has 'years' => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

# AllowQueueing
has 'is_queueable' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

# Registrant
has 'registrant_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

# Admin
has 'admin_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

# Tech
has 'technical_contact' => (
    is       => 'ro',
    isa      => Contact,
    required => 1,
);

# AuxBilling
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
            : ( map { 'NS' . $_ => $self->ns->[ $_ ] } 0 .. scalar (@{ $self->ns }) ),
        IgnoreNSFail    => ( $self->is_ns_fail_fatal ? 'No' : 'Yes' ),
        UnLockRegistrar => ( $self->is_locked        ? 0    : 1     ),
        RenewName       => ( $self->is_auto_renew    ? 1    : 0     ),
        NumYears        => $self->years,
        AllowQueueing   => ( $self->is_queueable     ? 1    : 0     ),
        %{ $self->registrant_contact->construct_creation_request('Registrant') },
        %{ $self->admin_contact->construct_creation_request('Admin')      },
        %{ $self->technical_contact->construct_creation_request('Tech')  },
        %{ $self->billing_contact->construct_creation_request('AuxBilling')    },
    };
}

__PACKAGE__->meta->make_immutable;
1;

__END__
