package WWW::eNom::Role::Command::Service;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( Bool Domain DomainName PositiveInt );

use Try::Tiny;
use Carp;

use DateTime::Format::DateParse;

requires 'submit', '_set_domain_auto_renew';

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

sub get_is_privacy_auto_renew_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetWPPSInfo',
            params => {
                Domain => $domain_name
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }
        }

        if( $response->{GetWPPSInfo}{WPPSExists} == 0 ) {
            croak 'Domain does not have privacy';
        }

        if( !$response->{GetWPPSInfo}{WPPSAutoRenew} ) {
            croak 'Response did not contain privacy renewal data';
        }

        return !!( $response->{GetWPPSInfo}{WPPSAutoRenew} eq 'Yes' );
    }
    catch {
        croak $_;
    };
}

sub get_privacy_expiration_date_by_name {
    my $self = shift;
    my ( $domain_name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'GetWPPSInfo',
            params => {
                Domain => $domain_name
            }
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not found' } @{ $response->{errors} } ) {
                croak 'Domain not found in your account';
            }
        }

        if( $response->{GetWPPSInfo}{WPPSExists} == 0 ) {
            croak 'Domain does not have privacy';
        }

        if( !$response->{GetWPPSInfo}{WPPSExpDate} ) {
            croak 'Response did not contain privacy expiration data';
        }

        return DateTime::Format::DateParse->parse_datetime( $response->{GetWPPSInfo}{WPPSExpDate} );
    }
    catch {
        croak $_;
    };
}

sub enable_privacy_auto_renew_for_domain {
    my $self       = shift;
    my ( $domain ) = pos_validated_list( \@_, { isa => Domain } );

    my $current_is_privacy_auto_renew  = $self->get_is_privacy_auto_renew_by_name( $domain->name );
    if( $current_is_privacy_auto_renew ) {
        return $domain;
    }

    return $self->_set_domain_auto_renew({
        domain_name           => $domain->name,
        is_auto_renew         => $domain->is_auto_renew,
        privacy_is_auto_renew => 1,
    });
}

sub disable_privacy_auto_renew_for_domain {
    my $self       = shift;
    my ( $domain ) = pos_validated_list( \@_, { isa => Domain } );

    my $current_is_privacy_auto_renew  = $self->get_is_privacy_auto_renew_by_name( $domain->name );
    if( !$current_is_privacy_auto_renew ) {
        return $domain;
    }

    return $self->_set_domain_auto_renew({
        domain_name           => $domain->name,
        is_auto_renew         => $domain->is_auto_renew,
        privacy_is_auto_renew => 0,
    });
}

1;

__END__

=pod

=head1 NAME

WWW::eNom::Role::Command::Service - Addon Services That Can Be Purchased

=head1 SYNOPSIS

    use WWW::eNom;

    my $api = WWW::eNom->new( ... );

    # Purchase Domain Privacy
    my $order_id = $api->purchase_domain_privacy_for_domain( 'drzigman.com' );

    # Get Privacy Expiration Date
    my $privacy_expiration_date = $api->get_privacy_expiration_date_by_name( 'drzigman.com' );

    # Get is Privacy Auto Renew
    my $is_privacy_auto_renew = $api->get_is_privacy_auto_renew_by_name( 'drzigman.com' );

    my $domain = WWW::eNom::Domain->new( ... );

    # Enable Auto Renew for Domain Privacy
    my $updated_domain = $api->enable_privacy_auto_renew_for_domain( $domain );

    # Disable Auto Renew for Domain Privacy
    my $updated_domain = $api->disable_privacy_auto_renew_for_domain( $domain );

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

=head2 get_is_privacy_auto_renew_by_name

    my $is_privacy_auto_renew = $api->get_is_privacy_auto_renew_by_name( 'drzigman.com' );

Abstraction of the L<GetWPPSInfo|https://www.enom.com/api/API%20topics/api_GetWPPSInfo.htm> eNom API Call.  Given a FQN, returns a truthy value if auto renew is enabled for domain privacy and a falsey value if auto renew is disabled for domain privacy.

If the domain is not registered or is registered to someone else this method will croak.

B<NOTE> If the specified domain does not have domain privacy this method will croak with the message 'Domain does not have privacy'.

=head2 get_privacy_expiration_date_by_name

    my $privacy_expiration_date = $api->get_privacy_expiration_date_by_name( 'drzigman.com' );

Abstraction of the L<GetWPPSInfo|https://www.enom.com/api/API%20topics/api_GetWPPSInfo.htm> eNom API Call.  Given a FQN, returns a DateTime object representing when domain privacy will expire.

If the domain is not registered or is registered to someone else this method will croak.

B<NOTE> If the specified domain does not have domain privacy this method will croak with the message 'Domain does not have privacy'.

=head2 enable_privacy_auto_renew_for_domain

    my $domain         = WWW::eNom::Domain->new( ... );
    my $updated_domain = $api->enable_privacy_auto_renew_for_domain( $domain );

Abstraction of the L<SetRenew|https://www.enom.com/api/API%20topics/api_SetRenew.htm> eNom API Call.  Given an instance of L<WWW::eNom::Domain> enables auto renew of domain privacy.  If the domain privacy is already set to auto renew this method is effectively a NO OP.

B<NOTE> If the specified domain does not have domain privacy this method will croak with the message 'Domain does not have privacy'.

=head2 disable_privacy_auto_renew_for_domain

    my $domain         = WWW::eNom::Domain->new( ... );
    my $updated_domain = $api->disable_privacy_auto_renew_for_domain( $domain );

Abstraction of the L<SetRenew|https://www.enom.com/api/API%20topics/api_SetRenew.htm> eNom API Call.  Given an instance of L<WWW::eNom::Domain> disables auto renew of domain privacy.  If the domain privacy is already set not to auto renew this method is effectively a NO OP.

B<NOTE> If the specified domain does not have domain privacy this method will croak with the message 'Domain does not have privacy'.

=cut
