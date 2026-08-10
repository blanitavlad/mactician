#!/usr/bin/perl
use strict;
use warnings;

my ($iconset, $output) = @ARGV;
die "Usage: $0 ICONSET OUTPUT.icns\n" unless defined $iconset && defined $output;

my @chunks = (
    ["icp4", "icon_16x16.png"],
    ["icp5", "icon_16x16\@2x.png"],
    ["icp6", "icon_32x32\@2x.png"],
    ["ic07", "icon_128x128.png"],
    ["ic08", "icon_128x128\@2x.png"],
    ["ic09", "icon_256x256\@2x.png"],
    ["ic10", "icon_512x512\@2x.png"],
);

my @payloads;
my $total_length = 8;
for my $chunk (@chunks) {
    my ($type, $filename) = @$chunk;
    my $path = "$iconset/$filename";
    open my $input, "<:raw", $path or die "Could not read $path: $!\n";
    local $/;
    my $payload = <$input>;
    close $input;
    push @payloads, [$type, $payload];
    $total_length += 8 + length($payload);
}

open my $destination, ">:raw", $output or die "Could not write $output: $!\n";
print {$destination} "icns", pack("N", $total_length);
for my $chunk (@payloads) {
    my ($type, $payload) = @$chunk;
    print {$destination} $type, pack("N", 8 + length($payload)), $payload;
}
close $destination or die "Could not close $output: $!\n";
