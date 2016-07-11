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

    use Data::Dumper;
    print STDERR "Register Domain Response: " . Dumper( $response ) . "\n";

    if( $args{request}->is_private ) {
        # Set up Privacy
        ...;
    }

    # Retrieve the Domain Back out and return a WWW::eNom::Domain
    ...;
}

1;

__END__
