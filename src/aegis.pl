#!/usr/bin/perl
# $Id$
use Gtk2;
use strict;

my $PREFIX = (-e '@PREFIX@' ? '@PREFIX@/share/aegis-virus-scanner' : $ENV{PWD});

push(@INC, sprintf('%s/lib', $PREFIX));

eval { require Aegis };

$Aegis::Version = '2.0.0';
$Aegis::Prefix	= $PREFIX;

Gtk2->main;
