# $Id$
package Aegis::Monitor;
use Gnome2::VFS;
use strict;

sub new {
	my $self = bless({}, shift);

	Gnome2::VFS->init;

	my $dir = $Aegis::Config->get_string("$Aegis::Config::Dir/dir");

	$Aegis::Config->notify_add("$Aegis::Config::Dir/dir", sub {
		map { $_->cancel } values(%{$self->{handles}});
		$self->{handles} = {};
	});

	$self->set_watch_on($dir);

	return $self;
}

sub set_watch_on {
	my ($self, $dir) = @_;
	$dir = Gnome2::VFS->escape_path_string($dir);
	my ($result, $info) = Gnome2::VFS->get_file_info($dir, 'default');
	if ($result ne 'ok') {
		return 1;

	} else {
		$self->{handles}->{$dir} = Gnome2::VFS::Monitor->add($dir, 'directory', sub { $self->event(@_) });

		my ($result, @entries) = Gnome2::VFS::Directory->list_load($dir, 'default');
		if ($result ne 'ok') {
			$Aegis::UI->show_error($result);

		} else {
			map { $self->set_watch_on($dir.'/'.$_->{name}) } grep { $_->{type} eq 'directory' && $_->{name} !~ /^\.{1,2}$/ } @entries;

		}

	}

	return 1;
}

sub event {
	my ($self, $handle, $monitor_uri, $info_uri, $event) = @_;

	my $path = Gnome2::VFS->get_local_path_from_uri($info_uri);

	if ($event eq 'created' || $event eq 'changed') {
		my $info = Gnome2::VFS->get_file_info($info_uri, 'default');
		if ($info->{type} eq 'directory') {
			$self->{handles}->{$path} = Gnome2::VFS::Monitor->add($path, 'directory', sub { $self->event(@_) });

		} elsif ($Aegis::Config->get_bool("$Aegis::Config::Dir/enabled")) {
			$Aegis::Scanner->scan_file($path);

		}

	} elsif ($event eq 'deleted') {
		if (defined($self->{handles}->{$path})) {
			$self->{handles}->{$path}->cancel;
			undef($self->{handles}->{$path});
		}
	}

	return 1;
}

1;
