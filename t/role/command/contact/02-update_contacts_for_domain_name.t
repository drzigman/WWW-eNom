#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use String::Random qw( random_string );

use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Contact qw( create_contact );
use Test::WWW::eNom::Domain qw( create_domain $UNREGISTERED_DOMAIN $NOT_MY_DOMAIN );

subtest 'All Contacts At Once' => sub {
    subtest 'Update Contacts for Unregistered Domain' => sub {
        my $api         = create_api();

        throws_ok {
            $api->update_contacts_for_domain_name(
                domain_name        => $UNREGISTERED_DOMAIN->name,
                registrant_contact => create_contact(),
                admin_contact      => create_contact(),
                technical_contact  => create_contact(),
                billing_contact    => create_contact(),
            );
        } qr/Domain not found in your account/, 'Throws on unregistered domain';
    };

    subtest 'Update Contacts for Domain Registered To Someone Else' => sub {
        my $api         = create_api();

        throws_ok {
            $api->update_contacts_for_domain_name(
                domain_name        => $NOT_MY_DOMAIN->name,
                registrant_contact => create_contact(),
                admin_contact      => create_contact(),
                technical_contact  => create_contact(),
                billing_contact    => create_contact(),
            );
        } qr/Domain not found in your account/, 'Throws on unregistered domain';
    };

    subtest 'Update All Contacts at Once' => sub {
        my $api    = create_api();
        my $domain = create_domain();

        my $updated_contacts = {
            registrant_contact => create_contact({
                organization_name => 'London Univeristy',
                job_title         => 'Bug Squisher',
                phone_number      => '18005550000',
            }),
            admin_contact      => create_contact({
                phone_number      => '18005550001',
                fax_number        => '18005551212',
            }),
            technical_contact  => create_contact({
                phone_number      => '18005550002',
            }),
            billing_contact    => create_contact({
                phone_number      => '18005550003',
            }),
        };

        my $retrieved_contacts;
        lives_ok {
            $retrieved_contacts = $api->update_contacts_for_domain_name(
                domain_name => $domain->name,
                %{ $updated_contacts },
            );
        } 'Lives through updating contacts';

        for my $contact_type ( keys %{ $updated_contacts } ) {
            is_deeply( $retrieved_contacts->{$contact_type}, $updated_contacts->{$contact_type}, "Correct $contact_type" );
        }
    };
};

subtest 'Contacts One At A Time' => sub {
    for my $contact_type (qw( registrant_contact admin_contact technical_contact billing_contact )) {
        subtest $contact_type => sub {
            subtest 'Update Contacts One At A Time' => sub {
                my $api         = create_api();

                throws_ok {
                    $api->update_contacts_for_domain_name(
                        domain_name   => $UNREGISTERED_DOMAIN->name,
                        $contact_type => create_contact(),
                    );
                } qr/Domain not found in your account/, 'Throws on unregistered domain';
            };

            subtest 'Update Contacts for Domain Registered To Someone Else' => sub {
                my $api         = create_api();

                throws_ok {
                    $api->update_contacts_for_domain_name(
                        domain_name   => $NOT_MY_DOMAIN->name,
                        $contact_type => create_contact(),
                    );
                } qr/Domain not found in your account/, 'Throws on unregistered domain';
            };

            subtest 'Update Contact' => sub {
                my $api    = create_api();
                my $domain = create_domain();

                my $updated_contact = create_contact({
                    organization_name => 'London Univeristy',
                    job_title         => 'Bug Squisher',
                    phone_number      => '18005550000',
                });

                my $retrieved_contacts;
                lives_ok {
                    $retrieved_contacts = $api->update_contacts_for_domain_name(
                        domain_name   => $domain->name,
                        $contact_type => $updated_contact,
                    );
                } 'Lives through updating contact';

                is_deeply( $retrieved_contacts->{ $contact_type }, $updated_contact, "Correct updated $contact_type" );

                for my $unchanged_contact_type (
                    grep { $_ ne $contact_type } qw( registrant_contact admin_contact technical_contact billing_contact ) ) {

                    is_deeply( $retrieved_contacts->{ $unchanged_contact_type }, $domain->$unchanged_contact_type,
                        "Correct unchanged $unchanged_contact_type ");
                }
            };
        };
    }
};

subtest 'Update Two Contacts at Once' => sub {
    my $api    = create_api();
    my $domain = create_domain();

    my $updated_contacts = {
        registrant_contact => create_contact({
            organization_name => 'London Univeristy',
            job_title         => 'Bug Squisher',
            phone_number      => '18005550000',
        }),
        admin_contact      => create_contact({
            phone_number      => '18005550001',
            fax_number        => '18005551212',
        }),
    };

    my $retrieved_contacts;
    lives_ok {
        $retrieved_contacts = $api->update_contacts_for_domain_name(
            domain_name => $domain->name,
            %{ $updated_contacts },
        );
    } 'Lives through updating contacts';

    for my $contact_type (qw( registrant_contact admin_contact )) {
        is_deeply( $retrieved_contacts->{$contact_type}, $updated_contacts->{$contact_type},
            "Correct changed $contact_type" );
    }

    for my $unchanged_contact_type (qw( technical_contact billing_contact )) {
        is_deeply( $retrieved_contacts->{ $unchanged_contact_type }, $domain->$unchanged_contact_type,
            "Correct unchanged $unchanged_contact_type ");
    }
};

done_testing;
