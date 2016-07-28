#!/usr/bin/env perl

###########################################################################################
# NOTE: If the reseller account you are using does not have acces to delete registrations #
# these tests will fail.                                                                  #
# See "Availability" at https://www.enom.com/api/API%20topics/api_DeleteRegistration.htm  #
###########################################################################################

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'Delete Domain Registration On Unregistered Domain' => sub {
    my $api = create_api();

    throws_ok {
        $api->delete_domain_registration_by_name( $UNREGISTERED_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on unregistered domain';
};

subtest 'Delete Domain Registration On Domain Registered To Someone Else' => sub {
    my $api = create_api();

    throws_ok {
        $api->delete_domain_registration_by_name( $NOT_MY_DOMAIN->name );
    } qr/Domain not found in your account/, 'Throws on domain registered to someone else';
};

subtest 'Delete Domain Registration' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    lives_ok {
        $api->delete_domain_registration_by_name( $domain->name );
    } 'Lives through domain registration';

    subtest 'Delete Already Deleted Domain Registration' => sub {
        throws_ok {
            $api->delete_domain_registration_by_name( $domain->name );
        } qr/Domain not found in your account/, 'Throws on double delete';
    };
};

done_testing;
