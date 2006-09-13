# $Id$
package Aegis::Scanner;
use base qw(File::Scan);
use strict;

sub scan {
	my ($self, $file) = @_;

	if ($Aegis::Config->get_bool("$Aegis::Config::Dir/enabled")) {
		Aegis::UI->report_scan($file);

		if (-e $file) {
			my $virus = $self->SUPER::scan($file);
			if ($virus ne '') {
				$Aegis::UI->report_virus($file, $virus);

			} elsif (my $error = $self->error) {
				$Aegis::UI->report_error($file, $error);

			} elsif ($self->suspicious) {
				$Aegis::UI->report_suspicious($file);

			}
		}

	}

	return 1;
}

1;
