# $Id$
package Aegis::I18N;
use POSIX qw(setlocale);
use Locale::gettext;
use strict;

*main::_ = \&Locale::gettext::gettext;

1;
