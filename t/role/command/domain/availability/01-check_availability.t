#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api mock_response );

use List::Util qw( first );

my $eNom = create_api();

subtest 'Test Unavailable Domain' => sub {
    my $sld = 'google';
    my $tld = 'com';

    subtest 'No Suggestions' => sub {
        my $mocked_api = mock_response(
            method   => 'Check',
            response => {
                ErrCount => 0,
                Domain   => [ "$sld.$tld" ],
                RRPText  => [ 'Domain not available' ],
                RRPCode  => [ 211 ],
            }
        );

        my $domain_availabilities;
        lives_ok {
            $domain_availabilities = $eNom->check_domain_availability(
                slds => [ $sld ],
                tlds => [ $tld ],
                suggestions => 0,
            );
        } 'Lives through checking domain availability';

        $mocked_api->unmock_all;

        if( cmp_ok( scalar @{ $domain_availabilities }, '==', 1, 'Correct number of domain availability records' ) ) {
            my $domain_availability = $domain_availabilities->[0];

            isa_ok( $domain_availability, 'WWW::eNom::DomainAvailability' );
            cmp_ok( $domain_availability->name, 'eq', "$sld.$tld", 'Correct name' );
            ok( !$domain_availability->is_available, "$sld.$tld is not available" );
        }
    };

    subtest 'With Suggestions' => sub {
        my $mocked_api = mock_response(
            method   => 'Check',
            response => {
                ErrCount => 0,
                Domain   => [qw( google.com google.net google.org google.us )],
                RRPText  => [ map { 'Domain not available' } 1 .. 4 ],
                RRPCode  => [ map { 211 } 1 .. 4  ],
            }
        );

        mock_response(
            mocked_api => $mocked_api,
            method     => 'NameSpinner',
            response   => {
                namespin => {
                    domains => {
                        domain => {
                            'AllGoogles' => {
                                'com' => 'n',
                                'net' => 'n',
                                'org' => 'n',
                                'us'  => 'n',
                            }
                        }
                    }
                }
            }
        );

        my $domain_availabilities;
        lives_ok {
            $domain_availabilities = $eNom->check_domain_availability(
                slds => [ $sld ],
                tlds => [ $tld, 'net', 'org', 'us' ],
                suggestions => 1,
            );
        } 'Lives through checking domain availability';

        $mocked_api->unmock_all;

        if( cmp_ok( scalar @{ $domain_availabilities }, '>', 1, 'Correct number of domain availability records' ) ) {
            my $domain_availability = first {
                $_->name eq "$sld.$tld"
            } @{ $domain_availabilities };

            if( ok( $domain_availability, 'Domain Availability Record Returned' ) ) {
                isa_ok( $domain_availability, 'WWW::eNom::DomainAvailability' );

                cmp_ok( $domain_availability->name, 'eq', "$sld.$tld", 'Correct name' );
                ok( !$domain_availability->is_available, "$sld.$tld is not available" );
            }
        }
    };
};

subtest 'Test Available Domain' => sub {
    my $sld = 'test-' . random_string('ccnnccnnccnnccnnccnn');
    my $tld = 'com';

    subtest 'No Suggestions' => sub {
        my $mocked_api = mock_response(
            method   => 'Check',
            response => {
                ErrCount => 0,
                Domain   => [ "$sld.$tld" ],
                RRPText  => [ 'Domain available' ],
                RRPCode  => [ 210 ],
            }
        );

        my $domain_availabilities;
        lives_ok {
            $domain_availabilities = $eNom->check_domain_availability(
                slds => [ $sld ],
                tlds => [ $tld ],
                suggestions => 0,
            );
        } 'Lives through checking domain availability';

        $mocked_api->unmock_all;

        if( cmp_ok( scalar @{ $domain_availabilities }, '==', 1, 'Correct number of domain availability records' ) ) {
            my $domain_availability = $domain_availabilities->[0];

            isa_ok( $domain_availability, 'WWW::eNom::DomainAvailability' );
            cmp_ok( $domain_availability->name, 'eq', "$sld.$tld", 'Correct name' );
            ok( $domain_availability->is_available, "$sld.$tld is available" );
        }
    };

    subtest 'With Suggestions' => sub {
        my $mocked_api = mock_response(
            method   => 'Check',
            response => {
                ErrCount => 0,
                Domain   => [ "$sld.$tld" ],
                RRPText  => [ 'Domain available' ],
                RRPCode  => [ 210 ],
            }
        );

        mock_response(
            mocked_api => $mocked_api,
            method     => 'NameSpinner',
            response   => {
                namespin => {
                    domains => {
                        domain => {
                            'All' . $sld => {
                                $tld => 'y',
                            }
                        }
                    }
                }
            }
        );

        my $domain_availabilities;
        lives_ok {
            $domain_availabilities = $eNom->check_domain_availability(
                slds => [ $sld ],
                tlds => [ $tld ],
                suggestions => 1,
            );
        } 'Lives through checking domain availability';

        if( cmp_ok( scalar @{ $domain_availabilities }, '>', 1, 'Correct number of domain availability records' ) ) {
            my $domain_availability = first {
                $_->name eq "$sld.$tld"
            } @{ $domain_availabilities };

            if( ok( $domain_availability, 'Domain Availability Record Returned' ) ) {
                isa_ok( $domain_availability, 'WWW::eNom::DomainAvailability' );
                cmp_ok( $domain_availability->name, 'eq', "$sld.$tld", 'Correct name' );
                ok( $domain_availability->is_available, "$sld.$tld is available" );
            }
        }
    };
};

subtest 'Test Multiple Domains' => sub {
    my $unavailable_sld = 'google';
    my $available_sld   = 'test-' . random_string('ccnnccnnccnnccnnccnn');
    my $tlds = [qw( com net )];

    my $mocked_api = mock_response(
        method   => 'Check',
        response => {
            ErrCount => 0,
            Domain   => [
                ( map { $unavailable_sld . '.' . $_ } @{ $tlds } ),
                ( map { $available_sld   . '.' . $_ } @{ $tlds } ),
            ],
            RRPText  => [
                'Domain not available', 'Domain not available',
                'Domain available', 'Domain available'
            ],
            RRPCode  => [ 211, 211, 210, 210 ],
        }
    );

    my $domain_availabilities;
    lives_ok {
        $domain_availabilities = $eNom->check_domain_availability(
            slds => [ $unavailable_sld, $available_sld ],
            tlds => $tlds,
        );
    } 'Lives through checking domain availability';

    subtest 'Inspect Unavailable Domains' => sub {
        for my $tld (@{ $tlds }) {
            my $domain_name = "$unavailable_sld.$tld";

            my $domain_availability = first {
                $_->name eq "$domain_name"
            } @{ $domain_availabilities };

            subtest "Inspect Domain Availability Record for $domain_name" => sub {
                if( ok( $domain_availability, 'Domain Availability Record Returned' ) ) {
                    isa_ok( $domain_availability, 'WWW::eNom::DomainAvailability' );

                    ok( !$domain_availability->is_available, "$domain_name is not available" );
                }
            };
        }
    };

    subtest 'Inspect Available Domains' => sub {
        for my $tld (@{ $tlds }) {
            my $domain_name = "$available_sld.$tld";

            my $domain_availability = first {
                $_->name eq "$domain_name"
            } @{ $domain_availabilities };

            subtest "Inspect Domain Availability Record for $domain_name" => sub {
                if( ok( $domain_availability, 'Domain Availability Record Returned' ) ) {
                    isa_ok( $domain_availability, 'WWW::eNom::DomainAvailability' );

                    ok( $domain_availability->is_available, "$domain_name is available" );
                }
            };
        }
    };

    $mocked_api->unmock_all;
};

done_testing;
