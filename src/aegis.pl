#!/usr/bin/perl
# $Id$
use strict;

my $PREFIX = (-e '@PREFIX@' ? '@PREFIX@' : $ENV{PWD});

push(@INC, sprintf('%s/share/aegis-virus-scanner/lib', $PREFIX));

eval { require Aegis };
if ($@) {
	print STDERR $@;
	exit 1;
}

$Aegis::Version = '2.0.1';
$Aegis::Prefix	= $PREFIX;
$Aegis::App	= Aegis->new;

Gtk2->main;
