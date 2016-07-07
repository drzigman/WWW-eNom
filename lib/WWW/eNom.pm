package WWW::eNom;

use strict;
use warnings;
use utf8;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use WWW::eNom::Types qw( Bool Str ResponseType URI );

use URI;

# VERSION
# ABSTRACT: Interact with eNom, Inc.'s Reseller API

has username => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has password => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has test => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has response_type => (
    is      => 'ro',
    isa     => ResponseType,
    default => 'xml_simple',
);

has _uri => (
    isa     => URI,
    is      => 'ro',
    lazy    => 1,
    builder => '_build_uri',
);

with 'WWW::eNom::Role::Commands';

sub _build_uri {
    my $self = shift;

    my $subdomain = $self->test ? 'resellertest' : 'reseller';
    return URI->new("http://$subdomain.enom.com/interface.asp");
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

WWW::eNom - Interact with eNom, Inc.'s reseller API

=head1 SYNOPSIS

    use WWW::eNom;

    my $enom = WWW::eNom->new(
        username      => "resellid",
        password      => "resellpw",
        response_type => "xml_simple",
        test          => 1
    );

    $enom->AddToCart(
        EndUserIP => "1.2.3.4",
        ProductType => "Register",
        SLD => "myspiffynewdomain",
        TLD => "com"
    );

    ...

=head1 METHODS

=head2 new

Constructs a new object for interacting with the eNom API. If the "test" parameter is given, then the API calls will be made to the test server instead of the live one.

As of v0.3.1, an optional "response_type" parameter is supported. For the sake of backward compatibility, the default is "xml_simple"; see below for an explanation of this response type. Use of any other valid option will lead to the return of string responses straight from the eNom API. These options are:

=for Pod::Coverage username password response_type test

=over

=item * xml

=item * html

=item * text

=back

=head2 AddBulkDomains (and many others)

    my $response = $enom->AddBulkDomains(
        ProductType => "register",
        ListCount   => 1,
        SLD1        => "myspiffynewdomain",
        TLD1        => "com",
        UseCart     => 1
    );

Performs the specified command - see the L<eNom API users guide|http://www.enom.com/APICommandCatalog/> for the commands and their arguments.

For convenience, if you pass the "Domain" argument, it will be split into "SLD" and "TLD"; that is, you can say

    my $response = $enom->Check( SLD => "myspiffynewdomain", TLD => "com" );

or

    my $response = $enom->Check( Domain => "myspiffynewdomain.com" );

The default return value is a Perl hash (via L<XML::Simple>) representing the response XML from the eNom API; the only differences are

=over 4

=item *

The "errors" key returns an array instead of a hash

=item *

"responses" returns an array of hashes

=item *

Keys which end with a number are transformed into an array

=back

So for instance, a command C<Check( Domain => "enom.@" )> (the "@" means "com, net, org, biz, info") might return:

    {
        Domain  => [qw(enom.com enom.net enom.org enom.biz enom.info)],
        Command => "CHECK",
        RRPCode => [qw(211 211 211 211 211)],
        RRPText => [
            "Domain not available",
            "Domain not available",
            "Domain not available",
            "Domain not available",
            "Domain not available"
        ]
    }

You will need to read the API guide to check whether to expect responses in "RRPText" or "responses"; it's not exactly consistent.

=head1 RELEASE NOTE

As of v1.0.0, this module has been renamed to WWW::eNom. Net::eNom is now a thin wrapper to preserve backward compatibility.

=head1 AUTHOR

Robert Stone, C<< <drzigman AT cpan DOT org> >>

Original version by Simon Cozens C<< <simon at simon-cozens.org> >>.
Then maintained and expanded by Richard Simões, C<< <rsimoes AT cpan DOT org> >>.

=head1 COPYRIGHT & LICENSE

Copyright © 2016 Robert Stone. This module is released under the terms of the B<MIT License> and may be modified and/or redistributed under the same or any compatible license.
