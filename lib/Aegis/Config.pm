#$Id$
package Aegis::Config;
use Gnome2::GConf;
use vars qw($Dir);
use strict;

sub init {
	our $Dir = sprintf('/apps/%s', lc($Aegis::Name));
	$Aegis::Config = Gnome2::GConf::Client->get_default;
	$Aegis::Config->set_bool("$Dir/initialised", 1);
	$Aegis::Config->set_string("$Dir/dir", Glib::get_home_dir) if (!$Aegis::Config->get("$Dir/dir"));
	$Aegis::Config->add_dir($Dir, 'preload-recursive');
}

1;
