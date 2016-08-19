package WWW::eNom::Role::Command::Domain::PrivateNameServer;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( Domain DomainName PrivateNameServer );

use WWW::eNom::PrivateNameServer;

use Try::Tiny;
use Carp;

requires 'submit', 'update_nameservers_for_domain_name', 'get_domain_by_name';

# VERSION
# ABSTRACT: Domain Private Nameserver Operations

sub create_private_nameserver {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_name        => { isa => DomainName },
        private_nameserver => { isa => PrivateNameServer, coerce => 1 }
    );

    return try {
        my $domain = $self->get_domain_by_name( $args{domain_name} );

        my $response = $self->submit({
            method => 'RegisterNameServer',
            params => {
                Add    => 'true',
                NSName => $args{private_nameserver}->name,
                IP     => $args{private_nameserver}->ip,
            },
        });

        if( $response->{ErrCount} > 0 ) {
            if(    ( grep { $_ eq 'Domain ID not found.' } @{ $response->{errors} } )
                || ( grep { $_ eq 'Domain cannot be found.' } @{ $response->{errors} } ) ) {
                croak 'Domain not found in your account';
            }

            if( grep { $_ eq 'This nameserver is already registered.' } @{ $response->{errors} } ) {
                croak 'Private nameserver already registered';
            }

            croak 'Unknown error';
        }

        my @new_domain_nameservers;
        if( $domain->has_private_nameservers ) {
            @new_domain_nameservers = (
                @{ $domain->ns },
                $args{private_nameserver}->name,
                map { $_->name } @{ $domain->private_nameservers },
            );
        }
        else {
            @new_domain_nameservers = ( @{ $domain->ns }, $args{private_nameserver}->name );
        }

        return $self->update_nameservers_for_domain_name(
            domain_name => $domain->name,
            ns          => \@new_domain_nameservers,
        );
    }
    catch {
        croak $_;
    };
}

sub retrieve_private_nameserver_by_name {
    my $self = shift;
    my ( $name ) = pos_validated_list( \@_, { isa => DomainName } );

    return try {
        my $response = $self->submit({
            method => 'CheckNSStatus',
            params => {
                CheckNSName => $name,
            },
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Error 545 - Name server does not exist' } @{ $response->{errors} } ) {
                croak 'Nameserver does not exist';
            }
            if( grep {
                    $_ eq 'Error 531 - You are not authorized to receive information on this name server'
                } @{ $response->{errors} } ) {
                croak 'Nameserver not found in your account';
            }

            croak 'Unknown error';
        }

        if( !exists $response->{CheckNsStatus} ) {
            croak 'Response did not contain private nameserver data';
        }

        return WWW::eNom::PrivateNameServer->new(
            name => $response->{CheckNsStatus}{name},
            ip   => $response->{CheckNsStatus}{ipaddress},
        );
    }
    catch {
        croak $_;
    };
}

sub delete_private_nameserver {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        domain_name             => { isa => DomainName },
        private_nameserver_name => { isa => DomainName },
    );

    return try {
        # Prevent users from removing last private nameserver
        my $domain = $self->get_domain_by_name( $args{domain_name} );
        if( scalar @{ $domain->ns } == 1 && $domain->ns->[0] eq $args{private_nameserver_name} ) {
            croak 'Blocked deletion - Deleting this would leave this domain with no nameservers!';
        }

        # Remove this private nameserver from the list of authoritative ones
        # and let update_nameservers_for_domain_name handle the deletion.
        if( grep { $_ eq $args{private_nameserver_name} } @{ $domain->ns } ) {
            return $self->update_nameservers_for_domain_name(
                domain_name => $domain->name,
                ns          => [ grep { $_ ne $args{private_nameserver_name} } @{ $domain->ns } ]
            );
        }

        my $response = $self->submit({
            method => 'DeleteNameServer',
            params => {
                NS => $args{private_nameserver_name},
            },
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep {
                    $_ eq 'Nameserver registration failed due to error 545: Object does not exist'
                } @{ $response->{errors} } ) {
                croak 'Nameserver does not exist';
            }

            if(    ( grep { $_ eq 'Domain ID not found.' } @{ $response->{errors} } )
                || ( grep { $_ eq 'Domain cannot be found.' } @{ $response->{errors} } ) ) {
                croak 'Domain not found in your account';
            }

            croak 'Unknown error';
        }

        return;
    }
    catch {
        croak $_;
    };
}

1;

__END__

=head1 NAME

WWW::eNom::Role::Command::Domain::PrivateNameServer - Domain Private Nameserver Operations

=head1 SYNOPSIS

=head1 REQUIRED

=over 4

=item submit

=item get_domain_by_name

=item update_nameservers_for_domain_name

Needed in order to keep private nameservers synced with the authoritative ones.

=back

=head1 DESCRIPTION

Implemented private name server operations with L<eNom|https://www.enom.com>'s API.

=head1 LIMITATIONS

L<eNom|https://www.enom.com>'s API does not offer a method to retrieve a list of registered nameservers.  As a workaround, and so that we do not I<lose track> of L<Private Nameservers|WWW::eNom::PrivateNameServer>, private nameservers are B<always> added to the L<authoritative nameservers|WWW::eNom::Domain/ns>.  In the same vein, if a private nameserver is removed then it is also removed from the L<authoritative nameservers|WWW::eNom::Domain/ns>.

=head1 METHODS

=head2 create_private_nameserver

    my $domain = WWW::eNom::Domain->new( ... );
    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name => 'ns1.' . $domain->name,
        ip   => '4.2.2.1',
    );

    my $updated_domain = $api->create_private_nameserver(
        domain_name        => $domain->name,
        private_nameserver => $private_nameserver,
    );

Abstraction of the L<RegisterNameServer|https://www.enom.com/api/API%20topics/api_RegisterNameServer.htm> eNom API call.  Given a FQDN and a L<WWW::eNom::PrivateNameServer> (or a HashRef that can be coerced into one), creates the private nameserver and adds it to the list of L<authoritative nameservers|WWW::eNom::Domain/ns> for the domain.  Keep in mind, the name of private nameserver must be a root of the domain.  So if the domain is your-domain.com, you can have ns1.your-domain.com as a private nameserver but you can not have ns1.your-other-domain.com as a private nameserver.

This method will croak if the domain is owned by someone else, if it's not registered, or if the private nameserver name or ip are invalid.

=head2 retrieve_private_nameserver_by_name

    my $private_nameserver = $api->retrieve_private_nameserver_by_name( 'ns1.' . $domain->name );

Abstraction of the L<CheckNSStatus|https://www.enom.com/api/API%20topics/api_CheckNSStatus.htm> eNom API Call.  Given a FQDN that is the hostname of a private nameserver, returns an instance of L<WWW::eNom::PrivateNameServer> that describes the registered nameserver.

This method will croak if the domain is owned by someone else, if it's not registered, or if private nameserver does not exist.

=head2 delete_private_nameserver

    $api->delete_private_nameserver(
        domain_name             => $domain->name,
        private_nameserver_name => 'ns1.' . $domain->name,
    );

Abstraction of the L<DeleteNameServer|https://www.enom.com/api/API%20topics/api_DeleteNameServer.htm> eNom API Call.  Given a FQDN and a the FQDN of the private nameserver you wish to delete, deletes the private nameserver and removes it from the L<authoritative nameservers|WWW::eNom::Domain/ns>.

If deleting this private nameserver would leave the domain with no authoritative nameservers this method will croak with 'Blocked deletion - Deleting this would leave this domain with no nameservers!'  This is a safety that is part of the workaround needed in order to implement private nameservers.

This method will also croak if the domain is owned by someone else, if it's not registered, or if private nameserver does not exist.

=cut
