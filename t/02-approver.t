#!/usr/bin/env perl

use Test::Most tests => 1;
use Net::eNom;

my $enom = Net::eNom->new(
	username => 'resellid',
	password => 'resellpw',
	test     => 1,
);

my $response = $enom->CertGetApproverEmail( Domain => 'cpan.org' );
is(
	$response->{CertGetApproverEMail}{Approver}[0]{ApproverEmail},
	'elaine@chaos.wustl.edu',
	'Found CPAN domain admin'
);
