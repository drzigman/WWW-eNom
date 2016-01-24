#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;
use WWW::eNom;

my $enom = WWW::eNom->new(
    username => 'resellid',
    password => 'resellpw',
    test     => 1
);

my $response = $enom->CertGetApproverEmail( Domain => 'cpan.org' );
is(
    $response->{CertGetApproverEMail}{Approver}[0]{ApproverEmail},
    'eashton@mac.com',
    'Found CPAN domain admin'
);
