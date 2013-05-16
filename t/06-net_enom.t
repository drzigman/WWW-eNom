#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 2;
use Test::Deep;
use Test::Warn;

warning_is { require Net::eNom }
    "This module is deprecated; use WWW::eNom instead.";

my $enom = Net::eNom->new(
    username => "resellid",
    password => "resellpw",
    test     => 1 );
my $response = $enom->Check( Domain => "enom.*1" );
cmp_deeply(
    $response->{Domain},
    [ qw(enom.com enom.net enom.org enom.info enom.biz enom.us) ],
    "Domain check returned sensible response with Net::eNom wrapper." );
