#!/usr/bin/env perl

use strict;
use warnings FATAL => "all";
use Test::More tests => 1;
use Test::Exception;
use WWW::eNom;

my $enom = WWW::eNom->new(
    username => "resellid",
    password => "resellpw",
    test     => 1 );
throws_ok { $enom->Check( Domain => "enomfoo" ) } qr/does not look like/,
    "Malformed domain exception caught.";
