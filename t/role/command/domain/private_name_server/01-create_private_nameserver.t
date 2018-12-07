#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_update_nameserver mock_domain_retrieval $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

use WWW::eNom::PrivateNameServer;

subtest 'Create Private Nameserver On Unregistered Domain' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetDomainInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->create_private_nameserver({
            domain_name        => $UNREGISTERED_DOMAIN->name,
            private_nameserver => {
                name   => 'ns1.' . $UNREGISTERED_DOMAIN->name,
                ip     => '127.0.0.1',
            },
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Create Private Nameserver On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    my $mocked_api = mock_response(
        method   => 'GetDomainInfo',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->create_private_nameserver({
            domain_name        => $NOT_MY_DOMAIN->name,
            private_nameserver => {
                name   => 'ns1.' . $NOT_MY_DOMAIN->name,
                ip     => '127.0.0.1',
            },
        });
    } qr/Domain not found in your account/, 'Throws on not my domain';

    $mocked_api->unmock_all;
};

subtest 'Create Private Nameserver' => sub {
    my $api                 = create_api();
    my @initial_nameservers = ( 'ns1.enom.com', 'ns2.enom.com' );
    my $domain              = create_domain( ns => \@initial_nameservers );

    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name   => 'ns1.' . $domain->name,
        ip     => '4.2.2.1',
    );

    my $mocked_api = mock_update_nameserver(
        domain      => $domain,
        nameservers => [ @initial_nameservers, $private_nameserver ],
    );

    lives_ok {
        $api->create_private_nameserver({
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver,
        });
    } 'Lives through registering private nameserver';

    my $retrieved_domain = $api->get_domain_by_name( $domain->name );

    $mocked_api->unmock_all;

    cmp_bag( $retrieved_domain->ns, [ @initial_nameservers, 'ns1.' . $domain->name ], 'Correct ns' );

    ok( $retrieved_domain->has_private_nameservers, 'Correctly has private nameservers');
    cmp_bag( $retrieved_domain->private_nameservers, [ $private_nameserver ], 'Correct private_nameservers' );
};

subtest 'Create Private Nameserver - Other Private Nameservers In Use' => sub {
    my $api                 = create_api();
    my @initial_nameservers = ( 'ns1.enom.com', 'ns2.enom.com' );
    my $domain              = create_domain( ns => \@initial_nameservers );

    my $private_nameserver_ns1 = WWW::eNom::PrivateNameServer->new(
        name   => 'ns1.' . $domain->name,
        ip     => '4.2.2.1',
    );

    my $private_nameserver_ns2 = WWW::eNom::PrivateNameServer->new(
        name   => 'ns2.' . $domain->name,
        ip     => '4.2.2.2',
    );

    my $mocked_api = mock_update_nameserver(
        domain      => $domain,
        nameservers => [ @initial_nameservers, $private_nameserver_ns1 ],
    );

    lives_ok {
        $api->create_private_nameserver({
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver_ns1,
        });
    } 'Lives through registering private nameserver';

    $mocked_api->unmock_all;

    $mocked_api = mock_update_nameserver(
        domain      => $domain,
        nameservers => [ @initial_nameservers, $private_nameserver_ns1, $private_nameserver_ns2 ],
    );

    lives_ok {
        $api->create_private_nameserver({
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver_ns2,
        });
    } 'Lives through registering private nameserver';

    my $retrieved_domain = $api->get_domain_by_name( $domain->name );

    $mocked_api->unmock_all;

    cmp_bag( $retrieved_domain->ns,
        [ @initial_nameservers, map { $_->name } ( $private_nameserver_ns1, $private_nameserver_ns2 ) ], 'Correct ns' );

    ok( $retrieved_domain->has_private_nameservers, 'Correctly has private nameservers' );
    cmp_bag( $retrieved_domain->private_nameservers,
        [ $private_nameserver_ns1, $private_nameserver_ns2 ], 'Correct private_nameservers' );
};

subtest 'Create Private Nameserver - Duplicate' => sub {
    my $api    = create_api();
    my $domain = create_domain();
    my $private_nameserver = WWW::eNom::PrivateNameServer->new(
        name   => 'ns1.' . $domain->name,
        ip     => '4.2.2.1',
    );

    my $mocked_api = mock_update_nameserver(
        domain      => $domain,
        nameservers => [ @{ $domain->ns }, $private_nameserver ],
    );

    lives_ok {
        $api->create_private_nameserver({
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver,
        });
    } 'Lives through registering private nameserver';

    $mocked_api->unmock_all;

    $mocked_api = mock_domain_retrieval(
        name        => $domain->name,
        nameservers => [ @{ $domain->ns }, $private_nameserver->name ],
    );

    mock_response(
        mocked_api => $mocked_api,
        method     => 'RegisterNameServer',
        response   => {
            ErrCount => 1,
            errors   => [ 'This nameserver is already registered.' ],
        }
    );

    mock_response(
        mocked_api => $mocked_api,
        method     => 'CheckNSStatus',
        response   => {
            ErrCount      => 0,
            CheckNsStatus => {
                name      => $private_nameserver->name,
                ipaddress => $private_nameserver->ip,
            },
        }
    );

    throws_ok {
        $api->create_private_nameserver({
            domain_name        => $domain->name,
            private_nameserver => $private_nameserver,
        });
    } qr/Private nameserver already registered/, 'Throws on duplicate';

    $mocked_api->unmock_all;
};

done_testing;
