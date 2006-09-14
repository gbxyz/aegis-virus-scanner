# $Id$
package Aegis::Scanner;
use vars qw($WorkingDir $ConfigFile $LocalSocket $PidFile $LogFile);
use File::Scan::ClamAV;
use bytes;
use strict;

sub new {
	my $self = bless({}, shift);

	our $WorkingDir = sprintf('%s/.%s', Glib::get_home_dir, lc($Aegis::Name));
	Gnome2::VFS->make_directory($WorkingDir, 0700);

	our $ConfigFile		= sprintf('%s/clamd.conf', $WorkingDir);
	our $LocalSocket	= sprintf('%s/clamd.sock', $WorkingDir);
	our $PidFile		= sprintf('%s/clamd.pid', $WorkingDir);
	our $LogFile		= sprintf('%s/clamd.log', $WorkingDir);

	Gnome2::VFS->unlink($ConfigFile);
	my ($result, $handle) = Gnome2::VFS->create($ConfigFile, 'write', 1, 0700);

	my $config = sprintf("LocalSocket %s\nPidFile %s\nLogFile %s\n", $LocalSocket, $PidFile, $LogFile);
	$handle->write($config, length($config));
	$handle->close;

	system("clamd --config-file=\"$ConfigFile\" 1>/dev/null 2>/dev/null");
	my ($result, $size, $data) = Gnome2::VFS->read_entire_file($PidFile);
	$self->{pid} = $data;
	chomp($self->{pid});

	$self->{scanner} = File::Scan::ClamAV->new(port => $LocalSocket);

	return $self;
}

sub scan_file {
	my ($self, $file) = @_;

	if ($file =~ /__aegis__infected__trigger$/) {
		$Aegis::UI->report_virus($file, "Aegis/Trigger");
		return 1;
	}

	if (-e $file) {
		$Aegis::UI->report_scan($file);

		if (!-r $file) {
			$Aegis::UI->report_error($file, "Read access denied.");

		} else {
			my %res = $self->{scanner}->scan($file);
			my $virus = $res{$file};
			if ($virus ne '') {
				$Aegis::UI->report_virus($file, $virus);

			} elsif (my $error = $self->{scanner}->errstr) {
				$Aegis::UI->report_error($file, $error) if ($error !~ /empty$/i && $error !~ /not supported file type/i);

			}

		}

	}

	return 1;
}

sub shutdown {
	my $self = shift;
	kill(9, $self->{pid});
	Gnome2::VFS->unlink($ConfigFile);
	Gnome2::VFS->unlink($LocalSocket);
	Gnome2::VFS->unlink($PidFile);
}

sub DESTROY {
	my $self = shift;
	$self->shutdown;
}

1;
