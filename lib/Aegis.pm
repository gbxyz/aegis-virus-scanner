# $Id$
package Aegis;
use Aegis::Config;
use Aegis::Monitor;
use Aegis::Scanner;
use Aegis::UI;
use Aegis::I18N;
use File::Basename qw(basename);
use vars qw($Name $FullName $Alias $App $Prefix $Config $Monitor $Scanner $UI $Quarantine);
use strict;

BEGIN {
	our $Name		= __PACKAGE__;
	our $FullName		= sprintf('%s Virus Scanner', $Name);
	our $Alias		= lc($FullName);
	$Alias =~ s/\s/-/g;
	our $Prefix		= $ENV{PWD};
}

our $App = Aegis->new;

sub new {
	Aegis::Config->init;
	our $Quarantine		= sprintf(_('%s/QUARANTINE'), Glib::get_home_dir);
	our $Monitor		= Aegis::Monitor->new;
	our $Scanner		= Aegis::Scanner->new;
	our $UI			= Aegis::UI->new;

	return bless({}, shift);
}

sub shutdown {
	my $self = shift;
	$Scanner->shutdown;
	Gtk2->main_quit;
	exit;
}

sub initiate_scan {
	my ($self, $dir, $recurse, $scan_hidden) = @_;

	$UI->{scan_progressbar}->set_fraction(0);
	$UI->{scan_progressbar}->set_text(sprintf(_('Preparing to scan %s'), $dir));
	$UI->update;
	$UI->{scan_progress_window}->show_all;

	my @files = $self->get_contents($dir, $recurse, $scan_hidden);

	undef($self->{cancel_scan});

	for (my $i = 0 ; $i < scalar(@files) ; $i++) {
		if ($self->{cancel_scan}) {
			$UI->{scan_progress_window}->hide;
			return 1;

		} else {
			my $fraction = $i / scalar(@files);
			$UI->{scan_progress_window}->set_title(sprintf(_('Scanning... (%d%%)'), ($fraction * 100)));
			$UI->{scan_progressbar}->set_fraction($fraction);
			$UI->{scan_progressbar}->set_text(sprintf(_('Scanning %s'), $files[$i]));
			$UI->update;

			$Scanner->scan_file($files[$i]);
		}
	}

	$UI->{scan_progress_window}->hide;

	$UI->show_info(_('Scan Complete!'));

	return 1;
}

sub get_contents {
	my ($self, $dir, $recurse, $scan_hidden) = @_;
	my @files;

	my ($result, @entries) = Gnome2::VFS::Directory->list_load($dir, 'default');
	return 1 if ($result ne 'ok');

	foreach my $entry (grep { $_->{name} !~ /^\.{1,2}$/ } @entries) {
		$UI->update;
		if ($entry->{name} !~ /^\./ || $scan_hidden) {
			my $path = "$dir/$entry->{name}";
			if ($entry->{type} eq 'directory') {
				push(@files, $self->get_contents($path, $recurse, $scan_hidden)) if ($recurse);

			} else {
				push(@files, $path);

			}

		}
	}
	return @files;
}

sub cancel_scan {
	my $self = shift;
	$self->{cancel_scan} = 1;
	return 1;
}

sub unlink_infected {
	my ($self, $file) = @_;
	my $result = Gnome2::VFS->unlink($file);
	$UI->show_warning(sprintf(_('Unable to delete %s!'), $file)) if ($result ne 'ok');
}

sub quarantine_infected {
	my ($self, $file) = @_;

	Gnome2::VFS->make_directory($Quarantine, 0700);

	my $dest = $Quarantine.'/'.basename($file);
	my $result = Gnome2::VFS->move($file, $dest, 1);

	if ($result ne 'ok') {
		$UI->show_warning(sprintf(_('Unable to quarantine %s (%s)!'), $file, $result));

	} else {
		chmod(0000, $dest);
		$UI->show_info(_('File has been moved into your quarantine folder.'));

	}

	return 1;

}

sub secure_infected {
	my ($self, $file) = @_;

	if (chmod(0000, $file) < 1) {
		$UI->show_warning(sprintf(_('Unable to secure %s!'), $file));

	} else {
		$UI->show_info(_('As a precaution, the file has been locked.'));

	}

	return 1;
}

1;
