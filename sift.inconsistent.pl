#!/usr/local/biotools/perl/5.10.0/bin/perl

# script to check the inconsistency by SIFT 
# it automatically flips the alternate base during the annotation

use strict;
use warnings;

my $sift_annot= shift @ARGV;
my $input = shift @ARGV;
	
open INPUT, "<$input" or die "could not open $input : $!";
open ANNOT, "<$sift_annot" or die "could not open $sift_annot : $!";
open OUT, ">${sift_annot}_mod" or die " could not open ${sift_annot}_mod : $! "; 
my $header = <ANNOT>;
print OUT "$header";
my %hash_annot=();
while (my $l = <ANNOT>)	{
	chomp $l;
	my @call = split(/\t/,$l);
	$hash_annot{$call[0]}=$l;
}
close ANNOT;

my %hash_input=();
while(my $l = <INPUT>)	{
	chomp $l;
	$hash_input{$l}=$l;
}

foreach my $entry (keys %hash_annot)	{
		if(defined($hash_input{$entry}))	{
			print OUT "$hash_annot{$entry}\n";
		}
}
close OUT;		
