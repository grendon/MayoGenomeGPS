## Perl script to append SeattleSeq results to the List.report results from MAQ
## 10/03/2010 : replace blank columns by underscore

use strict;
use Getopt::Std;

our ($opt_i, $opt_s, $opt_o);
print "INFO: script to add sseq results to the variant report\n";
print "RAW paramters: @ARGV\n";
getopt('iso');
if ( (!defined $opt_i) && (!defined $opt_s) && (!defined $opt_o) ) {
	die ("Usage: $0 \n\t-i [variant file] \n\t-s [snpeff] \n\t-o [output file] \n");
}
else    {
	my $source = $opt_i;
	my $eff = $opt_s;
	my $dest = $opt_o;
	my %hashreport=();
	my %hasheff=();
	
	open REPORT, "<$source" or die " can not open $source : $! \n";
	open OUT, ">$dest" or die "can not open $dest :$! \n";
	open SNPEFF, "<$eff" or die " can not open $eff :$! \n";
	my $len_header=0;
	my $eff_head=<SNPEFF>;
	my @eff_head_array=split(/\t/,$eff_head);
	my $num_tabs=$#eff_head_array-4;
	while(my $line = <REPORT>)	{
		chomp $line;
		if ($. == 1)	{
			print OUT "$line". "\t"x 5 . "SNPEFF Annotation" . "\t" x $num_tabs . "\n";
		}	
		elsif($. == 2)	{
			chomp $line;
			print OUT "$line\t$eff_head\n";
		}	
		else	{
			chomp $line;
			my @array = split(/\t/,$line);
			my $uniq = $array[0]."_".$array[1]."_".$array[2]."_".$array[3];
			push( @{$hashreport{$uniq}},join("\t",@array) );
		}
	}	
	close REPORT;

	#Form a unique key with chr_pos from snpeff, push the duplicates per key into array
	while(my $line = <SNPEFF>)	{
		chomp $line;
		my @array = split(/\t/,$line);
		# make a unique id using chr and position as a set
		my $uniq = $array[0]."_".$array[1]."_".$array[2]."_".$array[3];
		push( @{$hasheff{$uniq}},join("\t",@array));
	}
	close SNPEFF;

	#Loop over unique key from %hashreport and compare with %hashsseq;
	
	foreach my $find (sort keys %hashreport)	{
		if(defined $hasheff{$find} )	{
			my $count = scalar(@{$hasheff{$find}});
			my $count_report= scalar(@{$hashreport{$find}});
				for(my $j = 0; $j <= $count_report-1; $j++)	{
					print OUT "${$hashreport{$find}}[$j]";
					print OUT "\t${$hasheff{$find}}[0]\n";
					if($count > 1)	{
						for(my $i = 1; $i <= $count-1; $i++)	{
							print OUT "\t"x$#eff_head_array;
							print OUT "${$hasheff{$find}}[$i]\n";
						}	
					}
				}							
		}
	}
	undef %hashreport;
	undef %hasheff;
}
	
close OUT;
