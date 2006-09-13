# $Id$
package Aegis::UI;
use base qw(Gtk2::GladeXML::Simple);
use Gtk2;
use Gtk2::TrayIcon;
use strict;

sub new {
	my $package = shift;
	my $self = $package->SUPER::new(sprintf('%s/share/aegis.glade', $Aegis::Prefix));

	Gtk2->init;

	$self->{tips} = Gtk2::Tooltips->new;

	$self->{theme} = Gtk2::IconTheme->get_default;
	$self->{theme}->prepend_search_path(sprintf('%s/share', $Aegis::Prefix));

	$self->{icon} = Gtk2::TrayIcon->new($Aegis::Name);
	$self->{icon}->add(Gtk2::EventBox->new);
	$self->{icon}->child->add(Gtk2::Image->new);

	$self->{icon}->child->child->set_from_pixbuf($self->{theme}->load_icon($Aegis::Alias, 16, 'force-svg'));
	$self->{theme}->signal_connect('changed', sub { $self->{icon}->child->child->set_from_pixbuf($self->{theme}->load_icon($Aegis::Alias, 16, 'force-svg')) });

	$self->{tips}->set_tip($self->{icon}->child, _($Aegis::FullName));
	$self->{icon}->show_all;

	return $self;
}

sub show_error {
	print STDERR "ERROR: $_[1]\n";
	exit;
}

sub report_scan {
	print STDERR "Scanning $_[1]\n";
}

sub report_virus {
	print STDERR "Found $_[2] in $_[1]\n";
}

sub report_error {
	print STDERR "Error scanning $_[1]: $_[2]\n";
}

sub report_suspicious {
	print STDERR "$_[1] is suspicious\n";

}

1;
