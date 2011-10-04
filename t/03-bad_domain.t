#!/usr/bin/env perl

use Test::Most tests => 1;
use WWW::eNom;

my $enom = WWW::eNom->new(
	username => 'resellid',
	password => 'resellpw',
	test     => 1
);
throws_ok {
	$enom->Check( Domain => 'enomfoo' )
	} qr/does not look like/,
	'Malformed domain exception caught.'
;
