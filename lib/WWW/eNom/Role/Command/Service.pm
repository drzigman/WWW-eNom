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

=pod

=head1 NAME

WWW::eNom::Role::Command::Service - Addon Services That Can Be Purchased

=head1 SYNOPSIS

    use WWW::eNom;

    my $api = WWW::eNom->new( ... );

    # Be sure to wrap this in a try/catch block, presented here for clarity
    my $order_id = $api->purchase_domain_privacy_for_domain( 'drzigman.com' );

=head1 REQUIRES

=over 4

=item submit

=back

=head1 DESCRIPTION

Implements addon service related API calls (such as L<WPPS Service|https://www.enom.com/api/Value%20Added%20Topics/ID%20Protect.htm>, what eNom calls Privacy Protection).

=head1 METHODS

=head2 purchase_domain_privacy_for_domain

    # Be sure to wrap this in a try/catch block, presented here for clarity
    my $order_id = $api->purchase_domain_privacy_for_domain( 'drzigman.com' );

Abstraction of the L<PurchaseServices for ID Protect|https://www.enom.com/api/API%20topics/api_PurchaseServices.htm#input> eNom API Call.  Given a FQDN, attempts to purchase Domain Privacy for the specified domain.  On success, the OrderID of this purchase is returned.

There are several reason this method could fail and croak.

=over 4

=item Domain not found in account

=item Domain privacy is already purchased for this domain

=item Unknown error

This is almost always caused by attempting to add privacy protection to a public suffix that does not support it.

=back

Noting this, consumers should take care to ensure safe handling of these potential errors.

=cut
