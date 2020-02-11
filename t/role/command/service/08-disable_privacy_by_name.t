#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api mock_response );
use Test::WWW::eNom::Domain qw( create_domain mock_domain_retrieval $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );
use Test::WWW::eNom::Service qw( mock_disable_services mock_enable_services mock_get_wpps_info );

subtest 'Disable Privacy For Unregistered Domain' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'DisableServices',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->disable_privacy_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';

    $mocked_api->unmock_all;
};

subtest 'Disable Privacy For Domain Registered To Someone Else' => sub {
    my $api        = create_api();
    my $mocked_api = mock_response(
        method   => 'DisableServices',
        response => {
            ErrCount => 1,
            errors   => [ 'Domain name not found' ],
        }
    );

    throws_ok {
        $api->disable_privacy_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';

    $mocked_api->unmock_all;
};

subtest 'Disable Privacy For Domain That Lacks Privacy' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    my $mocked_api = mock_response(
        method   => 'DisableServices',
        response => {
            ErrCount => 1,
            errors   => [ 'ID Protect is not purchased for this domain' ],
        }
    );

    mock_response(
        mocked_api => $mocked_api,
        method     => 'GetWPPSInfo',
        response   => {
            ErrCount    => 0,
            GetWPPSInfo => {
                WPPSExists => 0,
            }
        }
    );

    mock_domain_retrieval(
        mocked_api => $mocked_api,
        name       => $domain->name,
        is_private => 0,
    );

    cmp_ok( $api->get_is_privacy_purchased_by_name( $domain->name ), '==', 0, 'Original domain correctly lacks privacy' );

    my $retrieved_domain;
    lives_ok {
        $retrieved_domain = $api->disable_privacy_by_name( $domain->name );
    } 'Lives through disabling privacy';

    cmp_ok( $api->get_is_privacy_purchased_by_name( $domain->name ), '==', 0, 'Domain lacks privacy purchased' );
    cmp_ok( $retrieved_domain->is_private, '==', 0, 'Domain correctly not private' );

    $mocked_api->unmock_all;
};

subtest 'Disable Privacy For Domain With Privacy' => sub {
    subtest 'Privacy Enabled' => sub {
        my $api    = create_api();
        my $domain = create_domain( is_private => 1 );

        my $mocked_api = mock_disable_services();

        mock_domain_retrieval(
            mocked_api => $mocked_api,
            name       => $domain->name,
            is_private => 0,
        );

        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $api->disable_privacy_by_name( $domain->name );
        } 'Lives through disabling privacy';

        $mocked_api->unmock_all;

        cmp_ok( $retrieved_domain->is_private, '==', 0, 'Domain correctly not private' );
    };

    subtest 'Privacy Disabled' => sub {
        my $api    = create_api();
        my $domain = create_domain( is_private => 1 );

        my $mocked_api = mock_disable_services();

        mock_domain_retrieval(
            mocked_api => $mocked_api,
            name       => $domain->name,
            is_private => 0,
        );

        lives_ok {
            $api->disable_privacy_by_name( $domain->name );
        } 'Lives through disabling privacy';

        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $api->disable_privacy_by_name( $domain->name );
        } 'Lives through disabling privacy';

        $mocked_api->unmock_all;

        cmp_ok( $retrieved_domain->is_private, '==', 0, 'Domain correctly not private' );
    };
};

done_testing;
