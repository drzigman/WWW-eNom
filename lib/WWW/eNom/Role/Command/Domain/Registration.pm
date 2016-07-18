package WWW::eNom::Role::Command::Domain::Registration;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( DomainRegistration );
use WWW::eNom::DomainRequest::Registration;

use Try::Tiny;
use Carp;

requires 'submit';

# VERSION
# ABSTRACT: Domain Registration API Calls

sub register_domain {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        request => { isa => DomainRegistration, coerce => 1 },
    );

    my $response => $self->submit({
        method => 'Purchase',
        params => $args{request}->construct_request(),
    });

    if( $args{request}->is_private ) {
        # Set up Privacy
        ...;
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

1;

__END__
