#!/usr/bin/env perl

use Test::Most tests => 2;
BEGIN {
	eval { require Moose };
	plan skip_all => 'Moose required for testing' if $@;
	use_ok 'Net::eNom';
}
lives_ok {
	Net::eNom->new(
		username => 'resellid',
		password => 'resellpw',
		test     => 1,
	)
} "Constructed with Moose instead of Mouse."
