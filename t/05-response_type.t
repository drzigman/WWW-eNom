#!/usr/bin/env perl

use Test::Most tests => 3;
use Net::eNom;

throws_ok {
	Net::eNom->new(
		username      => 'resellid',
		password      => 'resellpw',
		test          => 1,
		response_type => 'json'
	)
} qr/response_type must be one of/, 'Unsupported response type caught okay.';

my $enom;
lives_ok {
	$enom = Net::eNom->new(
		username      => 'resellid',
		password      => 'resellpw',
		test          => 1,
		response_type => 'html'
	)
} 'Supported response type okay.';

SKIP: {
	eval { require HTML::Parser; HTML::Parser->VERSION(v3.67); };
	skip 'HTML::Parser required for testing', 1 if $@;
	my $response = $enom->Check( Domain => 'perl.org' );
	my $html = HTML::Parser->new;
	lives_ok {
		$html->parse($response);
		$html->eof;
	} 'HTML response okay';
}
