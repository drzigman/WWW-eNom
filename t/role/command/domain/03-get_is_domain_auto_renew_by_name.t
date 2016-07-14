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

subtest 'Get Auto Renew Status For Unregistered Domain' => sub {
    my $api         = create_api();
    my $domain_name = 'NOT-REGISTERED-' . random_string('ccnnccnnccnnccnnccnnccnn') . '.com';

    throws_ok{
        $api->get_is_domain_auto_renew_by_name( $domain_name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Get Auto Renew Status For Domain Registered To Somone Else' => sub {
    my $api         = create_api();
    my $domain_name = 'enom.com';

    throws_ok{
        $api->get_is_domain_auto_renew_by_name( $domain_name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Get Auto Renew Status - Manual Renew Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        is_auto_renew => 0,
    });

    my $is_auto_renew;
    lives_ok {
        $is_auto_renew = $api->get_is_domain_auto_renew_by_name( $domain->name );
    } 'Lives through getting domain lock status';

    cmp_ok( $is_auto_renew, '==', 0, 'Correctly not auto renew' );
};

subtest 'Get Auto Renew Status - Auto Renew Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        is_auto_renew => 1,
    });

    my $is_auto_renew;
    lives_ok {
        $is_auto_renew = $api->get_is_domain_auto_renew_by_name( $domain->name );
    } 'Lives through getting domain lock status';

    cmp_ok( $is_auto_renew, '==', 1, 'Correctly auto renew' );
};

done_testing;
