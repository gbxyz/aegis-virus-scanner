# $Id$
package Aegis::UI;
use base qw(Gtk2::GladeXML::Simple);
use Gtk2;
use Gtk2::Ex::Simple::List;
use Gtk2::TrayIcon;
use POSIX qw(strftime);
use HTML::Entities qw(encode_entities_numeric);
use strict;

sub new {
	my $package = shift;

	Gtk2->init;

	my $self = $package->SUPER::new(sprintf('%s/share/%s.glade', $Aegis::Prefix, $Aegis::Alias));

	$self->{scanlog} = Gtk2::Ex::Simple::List->new_from_treeview(
		$self->{scan_log_view},
		_('File') => 'text',
		_('Status') => 'text',
		_('Time') => 'text',
	);
	$self->{scanlog}->get_column(0)->set_expand(1);
	($self->{scanlog}->get_column(0)->get_cell_renderers)[0]->set('ellipsize-set' => 0, 'ellipsize' => 'start');

	$self->{tips} = Gtk2::Tooltips->new;

	$self->{theme} = Gtk2::IconTheme->get_default;
	$self->{theme}->prepend_search_path(sprintf('%s/share', $Aegis::Prefix));

	$self->{icon} = Gtk2::TrayIcon->new($Aegis::Name);
	$self->{icon}->add(Gtk2::EventBox->new);
	$self->{icon}->child->add(Gtk2::Image->new);

	$self->{icon}->child->child->set_from_pixbuf($self->{theme}->load_icon($Aegis::Alias, 16, 'force-svg'));
	$self->{theme}->signal_connect('changed', sub { $self->{icon}->child->child->set_from_pixbuf($self->{theme}->load_icon($Aegis::Alias, 16, 'force-svg')) });

	$self->{icon}->child->signal_connect('button_release_event', sub { $self->show_menu if ($_[1]->button == 3) });

	$self->{tips}->set_tip($self->{icon}->child, _($Aegis::FullName));
	$self->{icon}->show_all;

	Gtk2::AboutDialog->set_url_hook(sub { $self->open_url(@_) });

	return $self;
}

sub show_menu {
	my $self = shift;

	if (!defined($self->{menu})) {
		$self->{menu} = Gtk2::Menu->new;

		my $enabled_item = Gtk2::CheckMenuItem->new_with_mnemonic(_('Background Scanner _Enabled'));
			$enabled_item->set_active($Aegis::Config->get_bool("$Aegis::Config::Dir/enabled"));
			$enabled_item->signal_connect('toggled', sub { $Aegis::Config->set_bool("$Aegis::Config::Dir/enabled", $enabled_item->get_active) });
			$Aegis::Config->notify_add("$Aegis::Config::Dir/enabled", sub { $enabled_item->set_active($Aegis::Config->get_bool("$Aegis::Config::Dir/enabled")) });
			$self->{menu}->append($enabled_item);

		my $scanner_item = Gtk2::ImageMenuItem->new_with_mnemonic(_('_Scan...'));
			$scanner_item->set_image(Gtk2::Image->new_from_stock('gtk-execute', 'menu'));
			$scanner_item->signal_connect('activate', sub { $self->start_on_demand_scan });
			$self->{menu}->append($scanner_item);

		my $log_item = Gtk2::MenuItem->new_with_mnemonic(_('View Scan _Log...'));
			$log_item->signal_connect('activate', sub { $self->{scan_log_window}->show_all });
			$self->{menu}->append($log_item);

		my $about_item = Gtk2::ImageMenuItem->new_with_mnemonic(_('_About...'));
			$about_item->set_image(Gtk2::Image->new_from_stock('gtk-about', 'menu'));
			$about_item->signal_connect('activate', sub { $self->show_about_dialog });
			$self->{menu}->append($about_item);

		$self->{menu}->append(Gtk2::SeparatorMenuItem->new);

		my $quit_item = Gtk2::ImageMenuItem->new_from_stock('gtk-quit');
			$quit_item->signal_connect('activate', sub { $Aegis::App->shutdown });
			$self->{menu}->append($quit_item);
	}

	$self->{menu}->show_all;
	$self->{menu}->popup(undef, undef, undef, undef, 3, undef);

	return 1;
}

sub show_error {
	my ($self, $error) = @_;
	my $dialog = Gtk2::MessageDialog->new(undef, 'modal', 'error', 'ok', sprintf(_('Fatal Error in %s'), $Aegis::FullName));
	$dialog->format_secondary_text(_('%s encountered the following error and will shut down: %s'), $Aegis::Name, $error);
	$dialog->signal_connect('close', sub { $Aegis::App->shutdown });
	$dialog->signal_connect('response', sub { $Aegis::App->shutdown });
	$dialog->signal_connect('delete_event', sub { $Aegis::App->shutdown });
	$dialog->set_position('center');
	$dialog->set_urgency_hint(1);
	$dialog->run;
	return 1;
}

sub show_info {
	my ($self, $info) = @_;
	my $dialog = Gtk2::MessageDialog->new(undef, 'modal', 'info', 'ok', $info);
	$dialog->signal_connect('close', sub { $dialog->destroy });
	$dialog->signal_connect('response', sub { $dialog->destroy });
	$dialog->signal_connect('delete_event', sub { $dialog->destroy });
	$dialog->set_position('center');
	$dialog->set_urgency_hint(1);
	$dialog->run;
	return 1;
}

sub show_warning {
	my ($self, $info) = @_;
	my $dialog = Gtk2::MessageDialog->new(undef, 'modal', 'warning', 'ok', $info);
	$dialog->signal_connect('close', sub { $dialog->destroy });
	$dialog->signal_connect('response', sub { $dialog->destroy });
	$dialog->signal_connect('delete_event', sub { $dialog->destroy });
	$dialog->set_position('center');
	$dialog->set_urgency_hint(1);
	$dialog->run;
	return 1;
}

sub report_scan {
	my ($self, $file) = @_;
	unshift(@{$self->{scanlog}->{data}}, [ $file, _('OK'), strftime('%H:%M:%S', localtime()) ]);
	$self->{scanlog}->get_selection->unselect_all;
	$self->{scanlog}->get_parent->get_vadjustment->set_value(0);
	return 1;
}

sub report_virus {
	my ($self, $file, $virus) = @_;

	for (my $i = 0 ; $i < scalar(@{$self->{scanlog}->{data}}) ; $i++) {
		if ($self->{scanlog}->{data}->[$i]->[0] eq $file) {
			$self->{scanlog}->{data}->[$i]->[1] = 'INF';
		}
	}

	$self->{virus_detected_dialog_file_label}->set_text($file);
	$self->{virus_detected_dialog_virus_label}->set_markup(sprintf('<big><b>%s</b></big>', encode_entities_numeric($virus)));
	$self->{virus_detected_dialog}->set_urgency_hint(1);
	$self->{virus_detected_dialog}->run;
	return 1;
}

sub report_error {
	my ($self, $file, $error) = @_;

	for (my $i = 0 ; $i < scalar(@{$self->{scanlog}->{data}}) ; $i++) {
		if ($self->{scanlog}->{data}->[$i]->[0] eq $file) {
			$self->{scanlog}->{data}->[$i]->[1] = 'ERR';
		}
	}

	$self->show_warning(sprintf(_('Error: cannot scan %s: %s'), $file, $error));

	return 1;
}

sub report_suspicious {
	my ($self, $file) = @_;

	for (my $i = 0 ; $i < scalar(@{$self->{scanlog}->{data}}) ; $i++) {
		if ($self->{scanlog}->{data}->[$i]->[0] eq $file) {
			$self->{scanlog}->{data}->[$i]->[1] = '?';
		}
	}

	$self->show_warning(sprintf(_('Warning: %s may be infected.'), $file));

	return 1;
}

sub close_scan_log_window {
	my $self = shift;
	$self->{scan_log_window}->hide;
	return 1;
}

sub open_url {
	my ($self, undef, $url) = @_;
	system("gnome-open \"$url\" &");
	return 1;
}

sub show_about_dialog {
	my $self = shift;
	Gtk2->show_about_dialog(
		$self->{main_window},
		name		=> $Aegis::FullName,
		version		=> $Aegis::Version,
		copyright	=> _('Copyright 2006 Gavin Brown'),
		website		=> 'http://jodrell.net/projects/aegis',
		logo_icon_name	=> 'aegis-virus-scanner',
		icon_name	=> 'aegis-virus-scanner',
	);

	return 1;
}

sub start_on_demand_scan {
	my $self = shift;

	my $recurse_checkbox = Gtk2::CheckButton->new_with_mnemonic(_('Scan _sub folders'));
	$recurse_checkbox->set_active($self->{last_recurse});

	my $hidden_checkbox = Gtk2::CheckButton->new_with_mnemonic(_('Scan _hidden files'));
	$hidden_checkbox->set_active($self->{last_hidden});

	my $vbox = Gtk2::VBox->new;
	$vbox->set_spacing(6);
	$vbox->pack_start($recurse_checkbox, 1, 1, 0);
	$vbox->pack_start($hidden_checkbox, 1, 1, 0);
	$vbox->show_all;

	my $chooser = Gtk2::FileChooserDialog->new(
		_('Scan Directory'),
		undef,
		'select-folder',
		'gtk-cancel'	=> 'cancel',
		'gtk-ok'	=> 'ok',
	);
	$chooser->set_extra_widget($vbox);
	$chooser->set_current_folder($self->{last_scanned_dir}) if ($self->{last_scanned_dir});
	$chooser->set_local_only(1);
	$chooser->signal_connect('close', sub { $chooser->destroy });
	$chooser->signal_connect('delete_event', sub { $chooser->destroy });
	$chooser->signal_connect('response', sub {
		my $dir = $chooser->get_current_folder;
		$chooser->destroy;
		$self->update;
		if ($_[1] eq 'ok') {
			$self->{last_scanned_dir} = $dir;
			$self->{last_recurse} = $recurse_checkbox->get_active;
			$self->{last_hidden} = $hidden_checkbox->get_active;
			$Aegis::App->initiate_scan(
				$dir,
				$recurse_checkbox->get_active,
				$hidden_checkbox->get_active,
			);
		}
	});
	$chooser->run;

	return 1;
}

sub close_scan_progress_window {
	my $self = shift;
	$Aegis::App->cancel_scan;
	return 1;
}

sub virus_detected_dialog_response {
	my ($self, undef, $code) = @_;
	$code = int($code);

	$self->{virus_detected_dialog}->hide;
	$self->update;

	my $file = $self->{virus_detected_dialog_file_label}->get_text;
	if ($code == 10) {
		$Aegis::App->unlink_infected($file);

	} elsif ($code == 20) {
		$Aegis::App->quarantine_infected($file);

	} else {
		$Aegis::App->secure_infected($file);

	}

	$self->update;

	return 1;
}

sub update { Gtk2->main_iteration while (Gtk2->events_pending) }

1;
