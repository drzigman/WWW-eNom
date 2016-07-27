#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Update Nameservers On Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->update_nameservers_for_domain_name({
            domain_name => $UNREGISTERED_DOMAIN->name,
            ns          => [ 'ns1.enom.org', 'ns2.enom.org' ],
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Update Nameservers On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->update_nameservers_for_domain_name({
            domain_name => $NOT_MY_DOMAIN->name,
            ns          => [ 'ns1.enom.org', 'ns2.enom.org' ],
        });
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Update Nameservers - No Change' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        ns => [ 'ns1.enom.com', 'ns2.enom.com' ],
    });

    my $updated_domain;
    lives_ok {
        $updated_domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => $domain->ns,
        });
    } 'Lives through updating nameservers';

    is_deeply( $updated_domain->ns, $domain->ns, 'Correct ns' );
};

subtest 'Update Nameservers - Full Change - Valid Nameservers' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        ns => [ 'ns1.enom.com', 'ns2.enom.com' ],
    });

    my $new_ns = [ 'ns1.enom.org', 'ns2.enom.org' ];

    my $updated_domain;
    lives_ok {
        $updated_domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => $new_ns,
        });
    } 'Lives through updating nameservers';

    is_deeply( $updated_domain->ns, $new_ns, 'Correct ns' );
};

subtest 'Update Nameservers - Full Change - Invalid Nameservers' => sub {
    my $api    = create_api();
    my $domain = create_domain({
        ns => [ 'ns1.enom.com', 'ns2.enom.com' ],
    });

    my $updated_domain;
    throws_ok {
        $updated_domain = $api->update_nameservers_for_domain_name({
            domain_name => $domain->name,
            ns          => [ 'ns1.' . $UNREGISTERED_DOMAIN->name, 'ns2.' . $UNREGISTERED_DOMAIN->name ],
        });
    } qr/Invalid Nameserver provided/, 'Throws on invalid nameservers';
};

done_testing;
