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

subtest 'Get Created Date For Unregistered Domain' => sub {
    my $api         = create_api();
    my $domain_name = 'NOT-REGISTERED-' . random_string('ccnnccnnccnnccnnccnnccnn') . '.com';

    throws_ok{
        $api->get_domain_created_date_by_name( $domain_name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Get Created Date For Domain Registered To Somone Else' => sub {
    my $api         = create_api();
    my $domain_name = 'enom.com';

    throws_ok{
        $api->get_domain_created_date_by_name( $domain_name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Get Created Date for Valid Domain' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $created_date;
    lives_ok {
        $created_date = $api->get_domain_created_date_by_name( $domain->name );
    } 'Lives through retrieving created_date';

    cmp_ok( $created_date->time_zone->name, 'eq', 'UTC', 'Correct time_zone' );
    cmp_ok( $created_date->ymd, 'eq', DateTime->now( time_zone => 'UTC' )->ymd, 'Correct created_date' );
};

done_testing;
