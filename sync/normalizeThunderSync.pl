#!/usr/bin/perl -w

=pod

ThunderSync is a Thunderbird addon that exports Thunderbird contacts
as VCF (VCard) files. It has more capabilities than the built-in VCF
functionality, but the files generated are still not being fully
parsed by Android import scripts

=cut

use strict;

my $input = $ARGV[0];
my $output = $ARGV[1];
unless ($output) {
    $output = $input;
    $output =~ s/\.vcf$//;
    $output .= "-Cleaned.vcf";
}

open(IN, "<$input")   || die "Failed to read VCF file:\n  $input\n  $!";
warn "Reading: $input\n";
open(OUT, ">$output") || die "Failed to write VCF file:\n  $output\n  $!";
warn "Writing: $output\n";
while (<IN>) {
    s/[\n\r]+$//;
    if (/^NOTE;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:(.+)/) {
        ## The note field in particular makes Android
        ## unhappy. Apparently it's the CHARSET field?
        my $ntxt = $1;
        ## $ntxt =~ s/=0A=0A/\n/g;
        print OUT "NOTE;ENCODING=QUOTED-PRINTABLE:$ntxt\n";
    } elsif (/^PHOTO;ENCODING=BASE64;TYPE=(.+?):(.+)/) {
        ## Image types appear to need 'TYPE=' removed
        my ($t, $d) = ($1,$2);
        print OUT "PHOTO;ENCODING=BASE64;$t:$d\n";
    } elsif (/^EMAIL;TYPE=INTERNET;(.+?):(.+)/) {
        ## Normalize email categories
        print OUT "EMAIL;$1:$2\n";
        ## Thunderbird uses just two:
        ##  TYPE=INTERNET;SECONDARY
        ##  TYPE=INTERNET;PRIMARY
        
    } else {
        ## Print as-is
        print OUT "$_\n";
    }
}
close IN;
close OUT;
warn "  Done.\n";
