#!/usr/bin/env perl

use Test::Most tests => 2;
BEGIN {
	eval { require Moose };
	plan skip_all => 'Moose required for testing' if $@;
	use_ok 'WWW::eNom';
}
lives_ok {
	WWW::eNom->new(
		username => 'resellid',
		password => 'resellpw',
		test     => 1,
	)
} 'Used guts from a Moose instead of a Mouse.'
