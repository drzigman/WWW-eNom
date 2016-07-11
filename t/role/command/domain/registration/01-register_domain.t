#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Contact qw( create_contact );

subtest 'Register Available Domain - No Privacy, Locking, Auto Renew, or Queueable' => sub {
    my $eNom = create_api();

    my $request;
    lives_ok {
        $request = WWW::eNom::DomainRequest::Registration->new({
            name               => 'test-' . random_string('ccnnccnnccnnccnnccnnccnnccnn') . '.com',
            ns                 => [ 'ns1.enom.com', 'ns2.enom.com' ],
            is_ns_fail_fatal   => 0,
            is_locked          => 0,
            is_private         => 0,
            is_auto_renew      => 0,
            years              => 1,
            is_queueable       => 0,
            registrant_contact => create_contact(),
            admin_contact      => create_contact(),
            technical_contact  => create_contact(),
            billing_contact    => create_contact(),
        });
    } 'Lives through creating request object';

    lives_ok {
        $eNom->register_domain( request => $request );
    } 'Lives through registering domain';
};

#subtest 'Register Available Domain - With Privacy'
#subtest 'Attempt to Register Unavailable'

done_testing;
