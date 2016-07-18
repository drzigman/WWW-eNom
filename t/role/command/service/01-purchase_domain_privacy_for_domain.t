#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain );

use DateTime;
use DateTime::Format::DateParse;

subtest 'Purchase Domain Privacy For Unregistered Domain' => sub {
    my $api         = create_api();
    my $domain_name = 'NOT-REGISTERED-' . random_string('ccnnccnnccnnccnnccnnccnn') . '.com';

    throws_ok{
        $api->purchase_domain_privacy_for_domain({
            domain_name   => $domain_name,
            years         => 1,
            is_auto_renew => 0,
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Purchase Domain Privacy For Domain Registered To Someone Else' => sub {
    my $api         = create_api();
    my $domain_name = 'enom.com';

    throws_ok{
        $api->purchase_domain_privacy_for_domain({
            domain_name   => $domain_name,
            years         => 1,
            is_auto_renew => 0,
        });
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Purchase Domain Privacy For Domain - 1 Years - Manual Renew' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    lives_ok {
        $api->purchase_domain_privacy_for_domain({
            domain_name   => $domain->name,
            years         => 1,
            is_auto_renew => 0,
        });
    } 'Lives through purchase of domain privacy';

    subtest 'Inspect Domain' => sub {
        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $api->get_domain_by_name( $domain->name );
        } 'Lives through retrieving domain';

        cmp_ok( $retrieved_domain->is_private, '==', 1, 'Correct is_private' );
    };

    subtest 'Inspect Privacy Service' => sub {
        my $response;
        my $lived_through_wpps_info = lives_ok {
            $response = $api->submit({
                method => 'GetWPPSInfo',
                params => {
                    Domain => $domain->name,
                }
            });
        } 'Lives through fetching details about Privacy';

        if( $lived_through_wpps_info ) {
            cmp_ok( $response->{GetWPPSInfo}{WPPSAutoRenew}, 'eq', 'No', 'Correct auto_renew' );

            my $privacy_expiration_date = DateTime::Format::DateParse->parse_datetime( $response->{GetWPPSInfo}{WPPSExpDate} );
            cmp_ok( $privacy_expiration_date->year - DateTime->now->year, 'eq', 1, 'Correct years' );
        }
    };
};

subtest 'Purchase Domain Privacy For Domain - 2 Years - Auto Renew' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 0 );

    lives_ok {
        $api->purchase_domain_privacy_for_domain({
            domain_name   => $domain->name,
            years         => 2,
            is_auto_renew => 1,
        });
    } 'Lives through purchase of domain privacy';

    subtest 'Inspect Domain' => sub {
        my $retrieved_domain;
        lives_ok {
            $retrieved_domain = $api->get_domain_by_name( $domain->name );
        } 'Lives through retrieving domain';

        cmp_ok( $retrieved_domain->is_private, '==', 1, 'Correct is_private' );
    };

    subtest 'Inspect Privacy Service' => sub {
        my $response;
        my $lived_through_wpps_info = lives_ok {
            $response = $api->submit({
                method => 'GetWPPSInfo',
                params => {
                    Domain => $domain->name,
                }
            });
        } 'Lives through fetching details about Privacy';

        if( $lived_through_wpps_info ) {
            cmp_ok( $response->{GetWPPSInfo}{WPPSAutoRenew}, 'eq', 'Yes', 'Correct auto_renew' );

            my $privacy_expiration_date = DateTime::Format::DateParse->parse_datetime( $response->{GetWPPSInfo}{WPPSExpDate} );
            cmp_ok( $privacy_expiration_date->year - DateTime->now->year, 'eq', 2, 'Correct years' );
        }
    };
};

subtest 'Purchase Domain privacy For Domain That Already Has It' => sub {
    my $api    = create_api();
    my $domain = create_domain( is_private => 1 );

    throws_ok {
        $api->purchase_domain_privacy_for_domain({
            domain_name   => $domain->name,
        });
    } qr/Domain privacy is already purchased for this domain/, 'Throws if domain privacy has already been purchased';
};

done_testing;
