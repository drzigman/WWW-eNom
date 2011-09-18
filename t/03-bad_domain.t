#!/usr/bin/env perl

use Test::Most tests => 1;
use Net::eNom;

my $enom = Net::eNom->new(
	username => 'resellid',
	password => 'resellpw',
	test     => 1
);
throws_ok {
	$enom->Check( Domain => 'enomfoo' ) }
	qr/does not look like/,
	'Malformed domain exception caught.'
;
