#!/usr/bin/env perl

use strict;
use warnings;

sub vernum($) {
	if ($_[0] =~  m!^((?:\d+\.)+\d+)$!) {
		my ($maj, $min) = split /\./, $1;
		return int($maj) * 256 + int($min);
	}

	return 0;
}

sub vercmp($$$) {
	my ($op, $v1, $v2) = @_;

	if    ($op eq 'lt') { return $v1  < $v2 }
	elsif ($op eq 'le') { return $v1 <= $v2 }
	elsif ($op eq 'gt') { return $v1  > $v2 }
	elsif ($op eq 'ge') { return $v1 >= $v2 }
	elsif ($op eq 'eq') { return $v1 == $v2 }

	return 0;
}

sub findbin($$$) {
	my ($basename, $compare, $maxvstr) = @_;

	my $lastversion = 0;
	my $cmpversion = vernum($maxvstr);
	my $prog = undef;

	foreach my $dir (split /:/, $ENV{'PATH'}) {
		foreach my $bin (glob("$dir/$basename?*"), "$dir/$basename") {
			if (-x $bin && open BIN, '-|', $bin, '--version') {
				my $vers = 0;
				my $line = readline(BIN) || '';

				foreach my $token (split /\s+/, $line) {
					$vers = vernum($token);
					last if $vers > 0;
				}

				if ($vers > 0 && (!$cmpversion || vercmp($compare, $vers, $cmpversion))) {
					if ($vers > $lastversion) {
						$lastversion = $vers;
						$prog = $bin;
					}
				}

				close BIN;
			}
		}
	}

	return $prog;
}

my $bin = findbin($ARGV[0], $ARGV[1], $ARGV[2]);

if (defined $bin) {
	printf "%s\n", $bin;
	exit 0;
}
else {
	warn "Cannot find a $ARGV[0] command with version $ARGV[1] $ARGV[2]\n";
	exit 1;
}
