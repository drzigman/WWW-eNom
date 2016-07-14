#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Role::Command::Domain;

use Readonly;
Readonly my $ROLE => 'WWW::eNom::Role::Command::Domain';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );
    requires_method_ok( $ROLE, 'get_contacts_by_domain_name' );
};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'get_domain_by_name' );
    has_method_ok( $ROLE, 'get_is_domain_locked_by_name' );
    has_method_ok( $ROLE, 'get_domain_name_servers_by_name' );
    has_method_ok( $ROLE, 'get_is_domain_auto_renew_by_name' );
};

done_testing;
