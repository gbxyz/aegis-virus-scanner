# $Id$
package Aegis;
use Aegis::Config;
use Aegis::Monitor;
use Aegis::Scanner;
use Aegis::UI;
use Aegis::I18N;
use vars qw($Name $FullName $Alias $App $Prefix $$Config $Monitor $Scanner $UI);
use strict;

BEGIN {
	our $Name	= __PACKAGE__;
	our $FullName	= sprintf('%s Virus Scanner', $Name);
	our $Alias	= lc($FullName);
	$Alias =~ s/\s/-/g;

	our $Prefix	= $ENV{PWD};
}

our $App = Aegis->new;

sub new {
	Aegis::Config->init;
	our $Monitor	= Aegis::Monitor->new;
	our $Scanner	= Aegis::Scanner->new;
	our $UI		= Aegis::UI->new;
	return bless({}, shift);
}

1;
