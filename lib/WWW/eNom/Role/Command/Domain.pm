package WWW::eNom::Role::Command::Domain;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( DomainName );

use WWW::eNom::Domain;

use Mozilla::PublicSuffix qw( public_suffix );
use Try::Tiny;
use Carp;

requires 'submit', 'get_contacts_by_domain_name';

# VERSION
# ABSTRACT: Domain API Calls

sub get_domain_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetDomainInfo',
            params => {
                Domain => $domain_name,
            }
        });

        if( !exists $response->{GetDomainInfo} ) {
            croak 'Response did not contain domain info';
        }

        return WWW::eNom::Domain->construct_from_response(
            domain_info   => $response->{GetDomainInfo},
            is_auto_renew => $self->get_is_domain_auto_renew_by_name( $domain_name ),
            is_locked     => $self->get_is_domain_locked_by_name( $domain_name ),
            name_servers  => $self->get_domain_name_servers_by_name( $domain_name ),
            contacts      => $self->get_contacts_by_domain_name( $domain_name ),
        );
    }
    catch {
        croak $_;
    };
}

sub get_is_domain_locked_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetRegLock',
            params => {
                Domain => $domain_name,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( $response->{RRPText} =~ m/Command blocked/ ) {
                croak 'Domain owned by someone else';
            }

            if( $response->{RRPText} =~ m/Object does not exist/ ) {
                croak 'Domain is not registered';
            }

            croak $response->{RRPText};
        }

        if( !exists $response->{'reg-lock'} ) {
            croak 'Response did not contain lock data';
        }

        return !!$response->{'reg-lock'};
    }
    catch {
        croak $_;
    };
}

sub get_domain_name_servers_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetDNS',
            params => {
                Domain => $domain_name,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            croak 'Unknown error';
        }

        if( !exists $response->{dns} ) {
            croak 'Response did not contain nameserver data';
        }

        return $response->{dns};
    }
    catch {
        croak $_;
    };
}

sub get_is_domain_auto_renew_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetRenew',
            params => {
                Domain => $domain_name,
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            croak 'Unknown error';
        }

        if( !exists $response->{'auto-renew'} ) {
            croak 'Response did not contain renewal data';
        }

        return !!$response->{'auto-renew'};
    }
    catch {
        croak $_;
    };

}

1;

__END__
