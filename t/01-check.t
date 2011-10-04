#!/usr/bin/env perl

use Test::Most tests => 3;
use WWW::eNom;

my $enom = WWW::eNom->new(
	username => 'resellid',
	password => 'resellpw',
	test     => 1
);
my $response = $enom->Check( Domain => 'enom.*1' );
cmp_deeply(
	$response->{Domain},
	['enom.us'],
	'Domain check returned sensible response.'
);
$response = $enom->Check( DomainFFFFFF => 'enom.*1' );
is(
	$response->{ErrCount},
	1,
	"Domain check with missing parameter threw one error"
);
cmp_deeply(
	$response->{errors},
	['An SLD and TLD must be entered'],
	'Domain check with missing parameter returned an error response.'
);
