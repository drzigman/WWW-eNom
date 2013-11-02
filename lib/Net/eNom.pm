package Net::eNom;

use strict;
use warnings;
use utf8;
use Moo;

extends 'WWW::eNom';

warnings::warnif(
    deprecated => 'This module is deprecated; use WWW::eNom instead.'
);

# VERSION
# ABSTRACT: DEPRECATED: namespace retired

1;

