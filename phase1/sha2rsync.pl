#!/usr/bin/perl -w

# ./sha2rsync.pl <rlist> <llist> <torsync>

# <rlist> is the filename of sha256sums fetched from server
# <llist> is the filename of sha256sums generated locally
# <torsync> is the filename of the list of files to upload

# <rlist> and <llist> are files formatted as follows:
#checksum *pathtofile

# both files must be sorted based on pathtofile: the script performs
# in-place merge (O(n+m)) of both lists based on that assumption.
# <rlist> and <llist> are parsed only once.

# the script cannot currently handle any other type of input

# the script will generate <torsync>, a list of files suitable for
# using with "rsync --files-from=<torsync>"

# if <rlist> doesn't exist, all files in <llist> are added to the
# upload list.
# if <rlist> exists, the <llist> files are added if:
# - they're not present in <rlist>
# - they're present in <rlist> AND their checksums differ

# the script will clobber <torsync>

use strict;
use warnings;
use integer;

die ("wrong number of arguments!") if ($#ARGV+1 != 3);

my $shapat = qr/^(\w+) \*(.+)$/;

my $rlist = $ARGV[0];
my $llist = $ARGV[1];
my $torsync = $ARGV[2];

my $rlist_fh = undef;
my $llist_fh = undef;
my $torsync_fh = undef;

open($torsync_fh, ">", $torsync) or die("can't create output file!");
open($llist_fh, "<", $llist) or die("can't read local list!");
open($rlist_fh, "<", $rlist);

my $lline = readline($llist_fh);
my $rline = readline($rlist_fh);


MAINLOOP: while () {
	# run this loop as long as we have content from both rlist and llist
	last (MAINLOOP) unless (defined($lline) && defined($rline));

	chomp($lline);
	my ($lcsum, $lfname) = $lline =~ $shapat;

	chomp($rline);
	my ($rcsum, $rfname) = $rline =~ $shapat;

	# compare current remote and local filenames
	my $rtlcmp = ($rfname cmp $lfname);

	while ($rtlcmp < 0) {	# remote fname is before current local fname: remote file doesn't exist localy
		$rline = readline($rlist_fh);
		next (MAINLOOP);
	}

	while ($rtlcmp > 0) {	# remote fname is after current local fname: local file doesn't exist remotely
		add_file($lfname);	# add lfname to upload list
		$lline = readline($llist_fh);
		next (MAINLOOP);
	}

	# if we end here, rtlcmp == 0: fnames matched, the file exist localy and remotely

	# fetch next line of both streams for the next iteration
	$lline = readline($llist_fh);
	$rline = readline($rlist_fh);

	# and skip if csums match
	next (MAINLOOP) if ($lcsum eq $rcsum);

	# otherwise add the file as it's different
	add_file($lfname);
}

# deal with remainder of llist if any
while (defined($lline)) {
	chomp($lline);
	my ($lcsum, $lfname) = $lline =~ $shapat;
	add_file($lfname);
	$lline = readline($llist_fh);
}

# unconditionally add some mandatory files to rsynclist
# add them last so they're transferred last: if everything else transferred correctly
add_file("packages/Packages.asc");
add_file("sha256sums.asc");
add_file("sha256sums");

exit (0);

sub add_file {
	my $fname = shift;
	print $torsync_fh "$fname\n";
}
