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
    is      => 'rw',
    isa     => ResponseType,
    default => 'xml_simple',
);

has _uri => (
    isa     => URI,
    is      => 'ro',
    lazy    => 1,
    builder => '_build_uri',
);

with 'WWW::eNom::Role::Command';

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

=head1 METHODS

=head2 new

Constructs a new object for interacting with the eNom API. If the "test" parameter is given, then the API calls will be made to the test server instead of the live one.

As of v0.3.1, an optional "response_type" parameter is supported. For the sake of backward compatibility, the default is "xml_simple"; see below for an explanation of this response type. Use of any other valid option will lead to the return of string responses straight from the eNom API. These options are:

=over

=item * xml

=item * html

=item * text

=back

=head1 RELEASE NOTE

As of v1.0.0, this module has been renamed to WWW::eNom. Net::eNom is now a thin wrapper to preserve backward compatibility.

=head1 AUTHOR

Robert Stone, C<< <drzigman AT cpan DOT org> >>

Original version by Simon Cozens C<< <simon at simon-cozens.org> >>.
Then maintained and expanded by Richard Simões, C<< <rsimoes AT cpan DOT org> >>.

=head1 COPYRIGHT & LICENSE

Copyright © 2016 Robert Stone. This module is released under the terms of the B<MIT License> and may be modified and/or redistributed under the same or any compatible license.

=cut
