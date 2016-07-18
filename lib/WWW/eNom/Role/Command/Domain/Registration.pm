package WWW::eNom::Role::Command::Domain::Registration;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( DomainRegistration );
use WWW::eNom::DomainRequest::Registration;

use Try::Tiny;
use Carp;

requires 'submit', 'purchase_domain_privacy_for_domain';

# VERSION
# ABSTRACT: Domain Registration API Calls

sub register_domain {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        request => { isa => DomainRegistration, coerce => 1 },
    );

    return try {
        my $response = $self->submit({
            method => 'Purchase',
            params => $args{request}->construct_request(),
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not available' } @{ $response->{errors} } ) {
                croak 'Domain not available for registration';
            }

            croak 'Unknown error';
        }

        if( $args{request}->is_private ) {
            $self->purchase_domain_privacy_for_domain({
                domain_name   => $args{request}->name,
                years         => $args{request}->years,
                is_auto_renew => $args{request}->is_auto_renew,
            });
        }

        # Because there can be some lag between domain creation and being able to
        # fetch the data from eNom, give it a few tries before calling it a failure
        for ( my $attempt_number = 1; $attempt_number <= 3; $attempt_number++ ) {
            my $domain;
            try {
                $domain = $self->get_domain_by_name( $args{request}->name )
            }
            catch {
                sleep $attempt_number;
            };

            $domain and return $domain;
        }

        croak 'Domain registered but unable to retrieve it';
    }
    catch {
        croak $_;
    };
}

1;

__END__
