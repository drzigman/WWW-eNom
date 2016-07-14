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

subtest 'Get Nameservers For Unregistered Domain' => sub {
    my $api         = create_api();
    my $domain_name = 'NOT-REGISTERED-' . random_string('ccnnccnnccnnccnnccnnccnn') . '.com';

    throws_ok{
        $api->get_domain_name_servers_by_name( $domain_name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Get Nameservers For Domain Registered To Somone Else' => sub {
    my $api         = create_api();
    my $domain_name = 'enom.com';

    throws_ok{
        $api->get_domain_name_servers_by_name( $domain_name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Get Nameservers - Valid Domain' => sub {
    my $api         = create_api();
    my $nameservers = [ 'ns1.enom.com', 'ns2.enom.com' ];
    my $domain      = create_domain({
        ns => $nameservers,
    });

    my $retrieved_nameservers;
    lives_ok {
        $retrieved_nameservers = $api->get_domain_name_servers_by_name( $domain->name );
    } 'Lives through getting nameservers';

    is_deeply( $retrieved_nameservers, $nameservers, 'Correct nameservers' );
};

done_testing;
