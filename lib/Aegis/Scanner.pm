# $Id$
package Aegis::Scanner;
use base qw(File::Scan);
use strict;

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
			my $virus = $self->scan($file);
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
