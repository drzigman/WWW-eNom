package WWW::eNom::Role::Command::Service;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( Bool DomainName PositiveInt );

use Try::Tiny;
use Carp;

requires 'submit';

# VERSION
# ABSTRACT: Addon Services That Can Be Purchased

sub purchase_domain_privacy_for_domain {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_name   => { isa => DomainName },
        years         => { isa => PositiveInt, default => 1 },
        is_auto_renew => { isa => Bool,        default => 0 },
    );

    return try {
        my $response = $self->submit({
            method => 'PurchaseServices',
            params => {
                Service   => 'WPPS',
                Domain    => $args{domain_name},
                NumYears  => $args{years},
                RenewName => ( $args{is_auto_renew} ? 1 : 0 ),
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }

            if( grep { $_ eq 'ID Protection is already active for this domain' } @{ $response->{errors} } ) {
                croak 'Domain privacy is already purchased for this domain';
            }

            croak 'Unknown error';
        }

        return $response->{OrderID};
    }
    catch {
        croak $_;
    };
}

1;

__END__
