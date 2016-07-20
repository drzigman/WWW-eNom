package Test::WWW::eNom::Domain;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;
use String::Random qw( random_string );

use WWW::eNom::Types qw( Bool Contact DomainName DomainNames PositiveInt );

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api );
use Test::WWW::eNom::Contact qw( create_contact );

use WWW::eNom::DomainRequest::Registration;

use Exporter 'import';
our @EXPORT_OK = qw( create_domain );

sub create_domain {
    my ( %args ) = validated_hash(
        \@_,
        name               => { isa => DomainName,  optional => 1 },
        ns                 => { isa => DomainNames, optional => 1 },
        is_locked          => { isa => Bool,        optional => 1 },
        is_private         => { isa => Bool,        optional => 1 },
        is_auto_renew      => { isa => Bool,        optional => 1 },
        years              => { isa => PositiveInt, optional => 1 },
        registrant_contact => { isa => Contact,     optional => 1 },
        admin_contact      => { isa => Contact,     optional => 1 },
        technical_contact  => { isa => Contact,     optional => 1 },
        billing_contact    => { isa => Contact,     optional => 1 },
    );

    $args{name}               //= 'test-' . random_string('nnccnnccnnccnnccnnccnncc') . '.com';
    $args{ns}                 //= [ 'ns1.enom.com', 'ns2.enom.com' ];
    $args{is_locked}          //= 1;
    $args{years}              //= 1;
    $args{registrant_contact} //= create_contact();
    $args{admin_contact}      //= create_contact();
    $args{technical_contact}  //= create_contact();
    $args{billing_contact}    //= create_contact();

    my $api = create_api();

    my $domain;
    subtest 'Create Domain' => sub {
        my $request;
        lives_ok {
            $request = WWW::eNom::DomainRequest::Registration->new( %args );
        } 'Lives through creating request object';

        lives_ok {
            $domain = $api->register_domain( request => $request );
        } 'Lives through domain registration';

        note( 'Domain ID: ' . $domain->id );
        note( 'Domain Name: ' . $domain->name );
    };

    return $domain;

}

1;
