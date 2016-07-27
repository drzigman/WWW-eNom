#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Role::Command::Service;

use Readonly;
Readonly my $ROLE => 'WWW::eNom::Role::Command::Service';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );

    requires_method_ok( $ROLE, 'submit' );
    requires_method_ok( $ROLE, '_set_domain_auto_renew' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'purchase_domain_privacy_for_domain' );
    has_method_ok( $ROLE, 'get_is_privacy_auto_renew_by_name' );
    has_method_ok( $ROLE, 'get_privacy_expiration_date_by_name' );
    has_method_ok( $ROLE, 'enable_privacy_auto_renew_for_domain' );
    has_method_ok( $ROLE, 'disable_privacy_auto_renew_for_domain' );
};

done_testing;
