#!/usr/bin/env perl

use Test::Most tests => 2;
use ok "Net::eNom";

my $enom = Net::eNom->new(
	username => "resellid",
	password => "resellpw",
	test     => 1 );
my $response = $enom->Check( Domain => "enom.*1" );
cmp_deeply(
	$response->{Domain},
	[ qw(enom.com enom.net enom.org enom.info enom.biz) ],
	"Domain check returned sensible response with Net::eNom wrapper." );
