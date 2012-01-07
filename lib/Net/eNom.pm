package Net::eNom;

use strict;
use warnings;
use utf8;
use Any::Moose;

extends "WWW::eNom";

warnings::warnif(
	deprecated => "This module is deprecated; use WWW::eNom instead."
);

# VERSION
# ABSTRACT: DEPRECATED: namespace retired

1;

__END__

=head1 NAME

	Net::eNom - DEPRECATED: namespace retired

=cut
