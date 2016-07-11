#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Moose::More;

use WWW::eNom::Role::Command::Domain::Registration;

use Readonly;
Readonly my $ROLE => 'WWW::eNom::Role::Command::Domain::Registration';

subtest "$ROLE is a well formed role" => sub {
    is_role_ok( $ROLE );
    requires_method_ok( $ROLE, 'submit' );

};

subtest "$ROLE has the correct methods" => sub {
    has_method_ok( $ROLE, 'register_domain' );
};

done_testing;
