#!/usr/bin/perl
# $Id$
use Aegis;
use strict;

$Aegis::Version = '2.0.0';
$Aegis::Prefix	= $ENV{PWD};

Gtk2->main;
