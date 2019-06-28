#!/usr/bin/env perl

use strict;
use MIME::Base64;

my @lines = (-t STDIN) ? () : <>;

if (@lines == 0) {
	die "Usage: $0 < key.sec > key.pub\n";
}

my $seckey = decode_base64(pop @lines);
my $comment = shift(@lines) || "untrusted comment: secret key";

chomp($comment);

$comment =~ s/\bsecret key$/public key/;

if (length($seckey) != 104) {
	die "Unexpected secret key length\n";
}

my $pubkey = encode_base64(substr($seckey, 0, 2) . substr($seckey, 32, 8) . substr($seckey, 72), "");

printf "%s\n%s\n", $comment, $pubkey;
