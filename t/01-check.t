#!/usr/bin/env perl

use strict;
use warnings FATAL => "all";
use Test::More tests => 3;
use Test::Deep;
use WWW::eNom;

my $enom = WWW::eNom->new(
    username => "resellid",
    password => "resellpw",
    test     => 1 );
my $response = $enom->Check( Domain => "enom.*1" );
cmp_deeply(
    $response->{Domain},
    [ qw(enom.com enom.net enom.org enom.info enom.biz enom.us) ],
    "Domain check returned sensible response." );
$response = $enom->Check( DomainFFFFFF => "enom.*1" );
is( $response->{ErrCount}, 1,
    "Domain check with missing parameter threw one error" );
cmp_deeply( $response->{errors}, ["An SLD and TLD must be entered"],
    "Domain check with missing parameter returned an error response." );
