package WWW::eNom;

use strict;
use warnings;
use utf8;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use Carp 'croak';
use Data::Validate::Domain 'is_domain';
use English '-no_match_vars';
use List::MoreUtils 'any';
use ParseUtil::Domain 'parse_domain';
use URI;

# VERSION
# ABSTRACT: Interact with eNom, Inc.'s reseller API

with 'WWW::eNom::Role::Commands';

# Supported response types:
my @response_types = qw/xml_simple xml html text/;
subtype 'eNomResponseType'
	=> as 'Str',
	=> where {
		my $type = $ARG;
		any { $type eq $ARG } @response_types
	},
	=> message {
		 'response_type must be one of: ' . join( ', ', @response_types )
	}
;

has username => (
	isa      => 'Str',
	is       => 'ro',
	reader   => 'username',
	required => 1
);
has password => (
	isa      => 'Str',
	is       => 'ro',
	reader   => 'password',
	required => 1
);
has test => (
	isa     => 'Bool',
	is      => 'ro',
	reader  => 'test',
	default => 0
);
has response_type => (
	isa     => 'eNomResponseType',
	is      => 'ro',
	reader  => 'response_type',
	default => 'xml_simple'
);
has _uri => (
	isa      => 'URI',
	is       => 'ro',
	reader   => '_uri',
	required => 1,
	lazy     => 1,
	builder  => '_build_uri'
);

=encoding utf-8

=head1 SYNOPSIS

	use strict;
	use warnings;
	use WWW::eNom;

	my $enom = WWW::eNom->new(
		username      => 'resellid',
		password      => 'resellpw',
		response_type => 'xml_simple',
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

Constructs a new object for interacting with the eNom API. If the
"test" parameter is given, then the API calls will be made to the test
server instead of the live one.

As of v0.3.1, an optional "response_type" parameter is supported. For the sake
of backward compatibility, the default is "xml_simple"; see below for an
explanation of this response type. Use of any other valid option will lead to
the return of string responses straight from the eNom API. These options are:

=over

=item * xml

=item * html

=item * text

=back

=cut

sub _make_query_string {
	my ( $self, $command, %args ) = @ARG;
	my $uri = $self->_uri;
	if ( $command ne "CertGetApproverEmail"
		and my $domain = delete $args{Domain} )
	{
		my $test_domain = $domain;

		# Look for an eNom wildcard TLD:
		my $wildcard_tld = qr/\.([*12@]+$)/x;
		my ($subbed_tld) = $test_domain =~ $wildcard_tld;
		$test_domain =~
			s/$wildcard_tld
			# Replace eNom wildcard TLD with '.com'
			# to test for domain name well-formedness:
			/.com/x
		if $subbed_tld;
		croak 'Domain name does not look like a domain.'
			if not is_domain($test_domain);
		my $parsed = parse_domain($test_domain);

		# Done testing; substitute TLD back in if necessary:
		$parsed->{zone} = $subbed_tld if $subbed_tld;

		# Finally, add in the neccesary API arguments:
		@args{qw/SLD TLD/} = @$parsed{qw/domain zone/};
	}
	my $response_type = $self->response_type;
	$response_type = 'xml' if $response_type eq 'xml_simple';
	$uri->query_form(
		command      => $command,
		uid          => $self->username,
		pw           => $self->password,
		responseType => $response_type,
		%args
	);
	return $uri;
}

sub _build_uri {
	my $self = shift;
	my $test = 'http://resellertest.enom.com/interface.asp';
	my $live = 'http://reseller.enom.com/interface.asp';
	my $uri  = URI->new( $self->test ? $test : $live );
	return $uri;
}

=head2 AddBulkDomains (and many others)

	my $response = $enom->AddBulkDomains(
		ProductType => 'register',
		ListCount   => 1,
		SLD1        => 'myspiffynewdomain',
		TLD1        => 'com',
		UseCart     => 1
	);

Performs the specified command - see the eNom API users guide
(https://www.enom.com/resellers/APICommandCatalogEnom.pdf) for the commands
and their arguments.

For convenience, if you pass the 'Domain' argument, it will be split
into 'SLD' and 'TLD'; that is, you can say

	my $response = $enom->Check( SLD => 'myspiffynewdomain', TLD => 'com' );

or

	my $response = $enom->Check( Domain => 'myspiffynewdomain.com' );

The default return value is a Perl hash (via L<XML::Simple>) representing the
response XML from the eNom API; the only differences are

=over 3

=item *

The "errors" key returns an array instead of a hash

=item *

"responses" returns an array of hashes

=item *

Keys which end with a number are transformed into an array

=back

So for instance, a command C<Check( Domain => 'enom.@' )> (the "@" means
"com, net, org") might return:

	{
		'Domain'  => [ 'enom.com', 'enom.net', 'enom.org' ],
		'Command' => 'CHECK',
		'RRPCode' => [ '211', '211', '211' ],
		'RRPText' => [
			'Domain not available',
			'Domain not available',
			'Domain not available'
		]
	};

You will need to read the API guide to check whether to expect responses
in "RRPText" or "responses"; it's not exactly consistent.

=head1 RELEASE NOTE

As of v1.0.0, this module has been renamed to WWW::eNom. Net::eNom is now a thin
wrapper to preserve backward compatibility.

=head1 AUTHOR

Simon Cozens, C<< <simon at simon-cozens.org> >>
Richard Simões, C<< <rsimoes at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-enom at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-eNom>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc WWW::eNom

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-eNom>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-eNom>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-eNom>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-eNom/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the UK Free Software Network (http://www.ukfsn.org/) for their
support of this module's development. For free-software-friendly hosting
and other Internet services, try UKFSN.

=head1 COPYRIGHT & LICENSE

Copyright 2011 Simon Cozens and Richard Simões.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;
1;    # End of WWW::eNom
