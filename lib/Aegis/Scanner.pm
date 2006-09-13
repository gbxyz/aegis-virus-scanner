# $Id$
package Aegis::Scanner;
use base qw(File::Scan);
use strict;

sub scan_file {
	my ($self, $file) = @_;

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
