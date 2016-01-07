package WWW::eNom;

use strict;
use warnings;
use utf8;
use Moo 1.001000;
use Type::Tiny 0.032 ();
use Type::Utils qw(class_type subtype as where message);
use Types::Standard qw(Bool Str);
use Carp qw(croak);
use Mozilla::PublicSuffix qw(public_suffix);
use URI 1.60;

# VERSION
# ABSTRACT: Interact with eNom, Inc.'s reseller API

with 'WWW::eNom::Role::Commands';

# Supported response types:
my @response_types = qw(xml_simple xml html text);

my $URIObject = class_type({ class => 'URI' })->plus_coercions(
    Str, sub { URI->new($_) }
);

my $eNomResponseType = subtype as Str,
    where {
        my $type = $_;
        { $type eq $_ and return 1 for @response_types; 0 }
    },
    message { 'response_type must be one of: ' . join ', ', @response_types };

has username => (
    isa      => Str,
    is       => 'ro',
    required => 1
);

has password => (
    isa      => Str,
    is       => 'ro',
    required => 1
);

has test => (
    isa     => Bool,
    is      => 'ro',
    default => 0
);

has response_type => (
    isa     => $eNomResponseType,
    is      => 'ro',
    default => 'xml_simple'
);

has _uri => (
    isa     => $URIObject,
    is      => 'ro',
    coerce  => $URIObject->coercion,
    lazy    => 1,
    default => \&_default__uri,
);

sub _split_domain {
    my ($self, $domain) = @_;

    # Look for an eNom wildcard TLD:
    my $wildcard_tld = qr{\.([*12@]+)$}x;
    my ($subbed_tld) = $domain =~ $wildcard_tld
        and $domain =~ s/$wildcard_tld/.com/x;
    my $suffix = eval { public_suffix($domain) }
        or croak "Domain name, $domain, does not look like a valid domain.";

    # Finally, add in the neccesary API arguments:
    my ($sld) = $domain =~ /^(.+)\.$suffix$/x;
    $suffix = $subbed_tld if $subbed_tld;

    return ($sld, $suffix);
}

sub _make_query_string {
    my ($self, $command, %opts) = @_;
    my $uri = $self->_uri;
    if ( $command ne "CertGetApproverEmail" && exists $opts{Domain} ) {
        @opts{qw(SLD TLD)} = $self->_split_domain(delete $opts{Domain});
    }

    my $response_type = $self->response_type eq 'xml_simple'
        ? 'xml'
        : $self->response_type;

    $uri->query_form(
        command      => $command,
        uid          => $self->username,
        pw           => $self->password,
        responseType => $response_type,
        %opts
    );

    return $uri;
}

sub _default__uri {
    my $self = shift;
    my $subdomain = $self->test ? 'resellertest' : 'reseller';
    return URI->new("http://$subdomain.enom.com/interface.asp");
}

1;
