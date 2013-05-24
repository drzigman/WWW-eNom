package WWW::eNom;

use strict;
use warnings;
use utf8;
use Moo;
use Type::Utils qw(class_type subtype as where message);
use Types::Standard qw(Bool Str);
use Carp qw(croak);
use Mozilla::PublicSuffix qw(public_suffix);
use URI;

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
    message {
         'response_type must be one of: ' . join ', ', @response_types
    }
;

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

sub _make_query_string {
    my ($self, $command, %opts) = @_;
    my $uri = $self->_uri;
    if ( $command ne "CertGetApproverEmail" && exists $opts{Domain} ) {
        my $domain = delete $opts{Domain};
        # Look for an eNom wildcard TLD:
        my $wildcard_tld = qr{\.([*12@]+)$}x;
        my ($subbed_tld) = $domain =~ $wildcard_tld
            and $domain =~ s/$wildcard_tld/.com/x;
        my $suffix = eval { public_suffix($domain) }
            or croak "Domain name, $domain, does not look like a valid domain.";


        # Finally, add in the neccesary API arguments:
        my ($sld) = $domain =~ /^(.+)\.$suffix$/x;
        $suffix = $subbed_tld if $subbed_tld;
        @opts{qw(SLD TLD)} = ($sld, $suffix);
    }

    my $response_type = $self->response_type;
    $response_type = 'xml' if $response_type eq 'xml_simple';
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
    my ($self) = @_;
    my $test = "http://resellertest.enom.com/interface.asp";
    my $live = "http://reseller.enom.com/interface.asp";
    return URI->new( $self->test ? $test : $live );
}

1;
