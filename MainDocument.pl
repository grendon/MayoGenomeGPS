#!/usr/local/biotools/perl/5.10.0/bin/perl

# use strict;
# use warnings;
use Getopt::Std;
our ($opt_r,$opt_p);
print "RAW paramters: @ARGV\n";
getopt('rp');
if ( (!defined $opt_r) && (!defined $opt_p) ) {
        die ("Usage: $0 \n\t-r [ run info file ] \n\t-p [ output folder path ] \n");
}
else    {
	my ($run_info) = $opt_r;chomp $run_info;
	my ($path) = $opt_p;chomp $path;
	my $desc = $path."/StatisticsDescription.html";
	open DESC, ">$desc" or die "can not open $desc : $!\n";
	$vars=read_files_var($run_info);
	my $disease=$vars->{DISEASE};
	my $workflow=$vars->{TOOL};
	my $tool=$vars->{TYPE};lc($tool);
	my $date=$vars->{DATE};
	my $sampleNames=$vars->{SAMPLENAMES};
	my $groupNames=$vars->{GROUPNAMES};
	my $multi=$vars->{MULTISAMPLE};$multi=uc($multi);
	my $laneNumbers=$vars->{LANEINDEX};
	my $SNV_caller=$vars->{SNV_CALLER};
	my $GenomeBuild=$vars->{GENOMEBUILD};
	my $tool_info=$vars->{TOOL_INFO};
	my $sampleinfo=$vars->{SAMPLEINFORMATION};
	my $sample_info=$vars->{SAMPLE_INFO};
	my $paired=$vars->{PAIRED};
	my $analysis=$vars->{ANALYSIS};$analysis=lc($analysis);
	my $run_num=$vars->{OUTPUT_FOLDER};
	my $labindex=$vars->{LABINDEXES};
	my $dbsnp_file=$vars->{dbSNP_SNV_rsIDs};$dbsnp_file =~ m/.+dbSNP(\d+)/;$dbsnp_v = $1;
	my $read_length=$vars->{READLENGTH};
	my $variant_type=$vars->{VARIANT_TYPE};
	my $Aligner=$vars->{ALIGNER};
	my $delivery=$vars->{DELIVERY_FOLDER};
	my $tertiary=$vars->{TERTIARY_FOLDER};
	my $version=$vars->{VERSION};
	$fastqc=$vars->{FASTQC};
	$vars=read_files_var($tool_info);
	my $port=$vars->{TB_PORT};
	my $host=$vars->{TB_HOST};
	my $script_path=$vars->{WORKFLOW_PATH};
	my $upload_tb=$vars->{UPLOAD_TABLEBROWSER};
	my $somatic_calling=$vars->{SOMATIC_CALLING};$somatic_calling=uc($somatic_calling);
	
	my @sampleArray = split(/:/,$sampleNames);
	my @groupArray = split(/:/,$groupNames);
	my @laneArray = split(/:/,$laneNumbers);
	my @IndexArray = split(/:/,$labindex);
	
	if ( ( $analysis eq 'external' ) || ( $analysis eq 'variant' ) || ($analysis eq 'mayo') || ($analysis eq 'realignment') || ($analysis eq 'realign-mayo') )	{
		if ($tool eq 'exome')	{
			$ontarget=$vars->{CAPTUREKIT};
			$target_region=`awk '{sum+=\$3-\$2+1; print sum}' $ontarget | tail -1`;chomp $target_region;
		}
		elsif ($tool eq 'whole_genome'){
			$ontarget=$vars->{MATER_GENE_BODY};
			$target_region=`awk '{sum+=\$3-\$2+1; print sum}' $ontarget | tail -1`;chomp $target_region;
		}
		$server=$vars->{HTTP_SERVER};	
	}
	print "Run : $run_num \n";
	print "Result Folder : $path \n";
	my $numbers=$path."/numbers";
	print "Disease: $disease\n";
	print "Date: $date\n";
	print "Samples: $sampleNames\n";
	print "lanes: $laneNumbers\n";
	print "Region: $target_region\n";
	print "PairedEnd: $paired\n";
	print "Type of Tool: $tool\n";
	print "ReadLength: $read_length\n";
	print "AnalysisType: $analysis\n";
	print "Delivery Folder: $delivery\n";
	print "Tool Info: $tool_info\n";
	my $output = "$path/Main_Document.html";
	my $s_output= "$path/SampleStatistics.tsv";
	print "Generating the Document... \n";
	open (OUT,">$output");
	open (SOUT,">$s_output");
	print OUT "<html>"; 
	print OUT "<head>"; 
	print OUT "<title>${tool} Analysis Main Document for $run_num</title>"; 
	print OUT "<style>";
	print OUT "table.helpT	{ text-align: center;font-family: Verdana;font-weight: normal;font-size: 11px;color: #404040;width: auto;
	background-color: #fafafa;border: 1px #6699CC solid;border-collapse: collapse;border-spacing: 0px; }
	td.helpHed	{ border-bottom: 2px solid #6699CC;border-left: 1px solid #6699CC;background-color: #BEC8D1;text-align: left;
	text-indent: 5px;font-family: Verdana;font-weight: bold;font-size: 11px;color: #404040; }
	td.helpBod	{ border-bottom: 1px solid #9CF;border-top: 0px;border-left: 1px solid #9CF;border-right: 0px;text-align: left;
	text-indent: 10px;font-family: Verdana, sans-serif, Arial;font-weight: normal;font-size: 11px;color: #404040;
	background-color: #fafafa; }
	table.sofT	{ text-align: center;font-family: Verdana;font-weight: normal;font-size: 11px;color: #404040;width: 580px;
	background-color: #fafafa;border: 1px #6699CC solid;border-collapse: collapse;border-spacing: 0px; }"; 
	print OUT "</style>";
	print OUT "</head>";
	print OUT "<body>";
	print DESC "<html>"; 
	print DESC "<head>"; 
	print OUT "<title>${tool} Column Description for Statistics per sample</title>"; 
	print DESC "<style>";
	print DESC "table.helpT	{ text-align: center;font-family: Verdana;font-weight: normal;font-size: 11px;color: #404040;width: auto;
	background-color: #fafafa;border: 1px #6699CC solid;border-collapse: collapse;border-spacing: 0px; }
	td.helpHed	{ border-bottom: 2px solid #6699CC;border-left: 1px solid #6699CC;background-color: #BEC8D1;text-align: left;
	text-indent: 5px;font-family: Verdana;font-weight: bold;font-size: 11px;color: #404040; }
	td.helpBod	{ border-bottom: 1px solid #9CF;border-top: 0px;border-left: 1px solid #9CF;border-right: 0px;text-align: left;
	text-indent: 10px;font-family: Verdana, sans-serif, Arial;font-weight: normal;font-size: 11px;color: #404040;
	background-color: #fafafa; }
	table.sofT	{ text-align: center;font-family: Verdana;font-weight: normal;font-size: 11px;color: #404040;width: 580px;
	background-color: #fafafa;border: 1px #6699CC solid;border-collapse: collapse;border-spacing: 0px; }"; 
	print DESC "</style>";
	print DESC "</head>";
	print DESC "<body>";
	
	##################
	### PAGE TITLE ###
	##################
	 
	print OUT "<p align='center'> ��� <b>Mayo BIC PI Support</b> ���   </p>";
	
	###########################
	# GENERATE DOCUMENT INDEX #
	###########################
	
	print OUT "<a name=\"top\"></a>";
	print OUT "
	<table id=\"toc\" class=\"toc\" ><tr><td><div id=\"toctitle\"><h2>Contents</h2></div>
	<ul>
	<li class=\"toclevel-1\"><a href=\"#Project Title\"><span class=\"tocnumber\">1</span>
	<span class=\"toctext\">Project Title</span></a></li>
	<li class=\"toclevel-1\"><a href=\"#Project Description\"><span class=\"tocnumber\">2</span>
	<span class=\"toctext\">Project Description</span></a></li>
	<ul>
	<li class=\"toclevel-2\"><a href=\"#Background\"><span class=\"tocnumber\">2.1</span>
	<span class=\"toctext\">Background</span></a></li>
	<li class=\"toclevel-2\"><a href=\"#Study design\"><span class=\"tocnumber\">2.2</span>
	<span class=\"toctext\">Study design</span></a></li>
	</ul>
	<li class=\"toclevel-1\"><a href=\"#Analysis plan\"><span class=\"tocnumber\">3</span>
	<span class=\"toctext\">Analysis plan</span></a></li>
	<li class=\"toclevel-1\"><a href=\"#Received Data\"><span class=\"tocnumber\">4</span>
	<span class=\"toctext\">Received Data</span></a></li>
	<ul>
	<li class=\"toclevel-2\"><a href=\"#Sample Summary\"><span class=\"tocnumber\">4.1</span>
	<span class=\"toctext\">Sample Summary</span></a></li>
	</ul>
	<li class=\"toclevel-1\"><a href=\"#Results Summary\"><span class=\"tocnumber\">5</span>
	<span class=\"toctext\">Results Summary</span></a></li>
	<ul>
	<li class=\"toclevel-2\"><a href=\"#Statistics based on per sample analysis\"><span class=\"tocnumber\">5.1</span>
	<span class=\"toctext\">Statistics based on per sample analysis</span></a></li>";
	if ( ( $analysis eq 'variant' ) || ( $analysis eq 'external' ) || ( $analysis eq 'mayo' ) || ($analysis eq 'realignment') || ($analysis eq 'realign-mayo') )
	{
		if ($tool eq 'exome' )	{
			print OUT "
			<li class=\"toclevel-2\"><a href=\"#Percent coverage of CaptureRegion\"><span class=\"tocnumber\">5.2</span>
			<span class=\"toctext\">Percent coverage of CaptureRegion</span></a></li>";
		}
		elsif ($tool eq 'whole_genome')	{
			print OUT "
			<li class=\"toclevel-2\"><a href=\"#Percent coverage of CodingRegion\"><span class=\"tocnumber\">5.2</span>
			<span class=\"toctext\">Percent coverage of CodingRegion</span></a></li>";
		}	
	}
	print OUT "
	</ul>
	<li class=\"toclevel-1\"><a href=\"#Results and Conclusions\"><span class=\"tocnumber\">6</span>
	<span class=\"toctext\">Results and Conclusions</span></a></li>
	<li class=\"toclevel-1\"><a href=\"#Results Delivered\"><span class=\"tocnumber\">7</span>
	<span class=\"toctext\">Results Delivered</span></a></li>
	<li class=\"toclevel-1\"><a href=\"#Useful Links\"><span class=\"tocnumber\">8</span>
	<span class=\"toctext\">Useful Links</span></a></li></ul><br>
	</td></tr></table>
	</script>";
	
	#############################
	# SECTION I - Project Title #
	#############################
	
	print OUT "<a name=\"Project Title\" id=\"Project Title\"></a><p align='left'><b><u> I. Project Title : </p></b></u>\n";
	print OUT "<ul><table cellspacing=\"0\" class=\"sofT\" > <tr> <td class=\"helpHed\">NGS Bioinformatics for ${tool} sequencing</td> </tr> </table> <br></ul>\n";
	
	
	####################################
	# SECTION II - Project Description #
	####################################
	
	my $read_call;	if($paired == 1)	{	$read_call = 'PE';	}	else	{	$read_call = 'SR';	}	
	my $num_samples=scalar(@sampleArray);
	my $num_groups=scalar(@groupArray);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;   ## to pull todays date
	$year += 1900;$mon++;
	my $username = getpwuid( $< );
	my @user=split(/[:;]/,`finger $username`);
	print OUT "<a name=\"Project Description\" id=\"Project Description\"></a><p align='left'><b><u> II. Project Description</p></b></u>";
	print OUT "<ul><a name=\"Background\" id=\"Background\"></a><p align='left'> 1. Background</p>";
	
	### Added link to tool_info CR 2/11/2013 ###
	
	print OUT "<table cellspacing=\"0\" class=\"sofT\"><tr>
	<td class=\"helpHed\">Item</td>
	<td class=\"helpHed\">Description</td></tr>
	<td class=\"helpBod\">Disease Type</td><td class=\"helpBod\">$disease</td></tr>
	<td class=\"helpBod\">Number of Samples</td><td class=\"helpBod\">$num_samples</td></tr>
	<td class=\"helpBod\">Workflow</td><td class=\"helpBod\">$workflow $version</td></tr>
	<td class=\"helpBod\">Tool Info</td><td class=\"helpBod\"><a href=\"config/tool_info.txt\" target=\"_blank\">Tool Info File</a></td></tr>";
	if ($tool eq 'exome')	{
		my $target=$target_region/1000000;$target=sprintf("%.2f",$target);
		print OUT "<td class=\"helpBod\">Capture Kit used</td><td class=\"helpBod\">$ontarget ($target Mbp)</td></tr>";
	}	
	if ($analysis ne 'annotation')	{
		print OUT "<td class=\"helpBod\">Read Length</td><td class=\"helpBod\">$read_length</td></tr>
		<td class=\"helpBod\">PairedEnd(PE)/SingleRead(SR)</td><td class=\"helpBod\">$read_call</td></tr>";
	}
	print OUT "<td class=\"helpBod\">Genome Build (hg18/hg19)</td><td class=\"helpBod\">$GenomeBuild</td></tr>
	<td class=\"helpBod\">StartDate</td><td class=\"helpBod\">$date</td></tr>
	<td class=\"helpBod\">EndDate</td><td class=\"helpBod\">$mon/$mday/$year</td></tr>
	<td class=\"helpBod\">Results Compiled By</td><td class=\"helpBod\">$user[2]</td></tr>
	</table>";
	
	#### SECTION II TABLE COMMENT
	print OUT "Note: Further raw NGS data will be used for statistical analysis<br>\n";
	
	### SECTION II DELIVERY SUMMARY ###
	my $loc=$path;
	$loc =~ s/\//\\/g;
	$tertiary=~ s/\//\\/g;
	$delivery=~ s/\//\\/g;
	my @WG_ver=split(/\//,$script_path);
	if ($tertiary ne 'NA')	{
		print OUT "Tertiary Location:: <b><u>\\\\rcfcluster-cifs$tertiary</b></u> <br>";
		print OUT "(Data is available for 60 Days from the Delivered Date)<br>";
	}
	if ($delivery ne 'NA')	{
		print OUT "Results Location:: <b><u>\\\\rcfcluster-cifs$delivery</b></u> <br>";
		print OUT "(Data is available for 60 Days from the Delivered Date)<br>";
	}
	
	### SECTION II STUDY DESIGN ###
	print OUT "<a name=\"Study design\" id=\"Study design\"></a><p align='left'> 2. Study design</p>";
	print OUT "<ul>
	<li><b> What are the samples? </b><br>
	${sampleinfo}
	<li><b> Goals of the project</b><br>";
	if ($analysis eq 'alignment')	{
		print OUT "Aligning sequencing samples using ${Aligner}";
	}
	else	{	
		if ($tool eq 'whole_genome')	{
			print OUT "${tool} sequencing analysis on the given set of samples, to align, realign, recalibrate, identify SNVs, INDELs, CNVs and SVs and annotate them.";
		}
		elsif ($tool eq 'exome')	{
			print OUT "${tool} sequencing analysis on the given set of samples, to align, realign, recalibrate, identify SNVs, INDELs and annotate them";
		}	
	}	
	print OUT "</ul></ul>\n";
	print OUT "<p align='right'><a href=\"#top\">-top-</a></p>";
	
	###################################
	### SECTION III - ANALYSIS PLAN ###
	###################################
	
	print OUT "<a name=\"Analysis Plan\" id=\"Analysis Plan\"></a><p align='left'><b><u> III. Analysis Plan</p></b></u><br>\n";
	print OUT "<b><P ALIGN=\"CENTER\">What's new: New features and updates </b> <a href= \"http://bioinformatics.mayo.edu/BMI/bin/view/Main/BioinformaticsCore/Analytics/$workflow\"target=\"_blank\">$workflow</a></P>";
	print OUT "<a href= \"${tool}_workflow.png\"target=\"_blank\"><P ALIGN=\"CENTER\"><img border=\"0\" src=\"${tool}_workflow.png\" width=\"700\" height=\"478\"><b><u><caption align=\"bottom\">$workflow  $version</caption></b></u></p>";
	print OUT "<p align='right'><a href=\"#top\">-top-</a></p>";
	
	##################################
	### SECTION IV - RECEIVED DATA ###
	##################################
	
	print OUT "<a name=\"Received Data\" id=\"Received Data\"></a><p align='left'><b><u> IV. Received Data</p></b></u> 
	<ul>
	1. Run Name<br>
	<br><table cellspacing=\"0\" class=\"sofT\"><tr><td class=\"helpHed\">Run #</td><td class=\"helpBod\">$run_num</td> </table><br>\n";
	
	
	# Build sample information table #
	
	print OUT "<a name=\"Sample Summary\" id=\"Sample Summary\"></a> 2. Sample Summary<br>
	<br><table cellspacing=\"0\" class=\"sofT\"><tr>
	<td class=\"helpHed\">Lane</td>
	<td class=\"helpHed\">Index</td>
	<td class=\"helpHed\">Sample Names</td></tr>";
	for (my $i = 0; $i < $num_samples; $i++)        {
		my @LaneNumbers= split(/,/,$laneArray[$i]);
		my @Indexes=split(/,/,$IndexArray[$i]);
		my $len_lanes = scalar(@LaneNumbers);
		for (my $j =0; $j < $len_lanes; $j++)   {
				print OUT "
				<td class=\"helpBod\">$LaneNumbers[$j]</td>
				<td class=\"helpBod\">$Indexes[$j]</td>
				<td class=\"helpBod\">$sampleArray[$i]</td></tr>
				\n";
		}
	}
	print OUT "<td class=\"helpHed\"></td><td class=\"helpHed\"></td><td class=\"helpHed\"></td></tr>";
	print OUT "</table>";
	
	if ($multi eq 'YES')	{
		print OUT "<br><br><table cellspacing=\"0\" class=\"sofT\"><tr>
        <td class=\"helpHed\">GroupName</td>";
        if ($somatic_calling eq "YES")	{
		print OUT "<td class=\"helpHed\">Normal Sample</td>
        <td class=\"helpHed\">Tumor Samples</td></tr>";
		}else{
		print OUT "<td class=\"helpHed\">Samples</td></tr>";}	
		for (my $i = 0; $i < $num_groups; $i++)	{
			my $sams=`cat $sample_info | grep -w "^$groupArray[$i]" | cut -d '=' -f2`;
			my @sam=split('\s+',$sams);
			my $normal=$sam[0];
			my $tumor=$sams;
			$tumor=~ s/$normal//g;
			# $tumor=~ s/\s+//g;
			if ($somatic_calling eq "YES")	{
			print OUT "
			<td class=\"helpBod\">$groupArray[$i]</td>
                        <td class=\"helpBod\">$normal</td>
                        <td class=\"helpBod\">$tumor</td></tr>
                        \n";}
			else	{
			print OUT"	
					<td class=\"helpBod\">$groupArray[$i]</td>
                        <td class=\"helpBod\">$sams</td></tr>
                        \n";}	
		}
	}	
    print OUT "<td class=\"helpHed\"></td><td class=\"helpHed\"></td><td class=\"helpHed\"></td></tr>";
	print OUT "</table>";
	print OUT "<p align='right'><a href=\"#top\">-top-</a></p>";
	
	###################################
	### SECTION V - RESULTS SUMMARY ### 
	###################################
	
	print OUT "</ul>
	<a name=\"Results Summary\" id=\"Results Summary\"></a><p align='left'><u><b> V.  Results Summary:</p></u></b>\n";
	
	
	##########
	### QC ###
	##########
	
	if ( ($analysis eq "mayo") || ($analysis eq "realign-mayo") || ($analysis eq "external" ) || ($analysis eq "alignment") )	{
		if($fastqc eq "YES")	{
			print OUT "
			<ul>
			<li><a name=\"QC steps\" id=\"QC steps\"></a> QC steps - FastQC-report
			<ul>
			FastQC aims to provide a simple way to do some quality control checks on raw sequence data coming from high throughput sequencing pipelines. It provides a modular set of analyses which you can use to give a quick impression of whether your data has any problems of which you should be aware before doing any further analysis.
			<u> <a href= \"fastqc\"target=\"_blank\">ClickMe</a></u>
			<br><b><u>NOTE:</b></u> FastQC runs a series of tests and will flag potential problems with your data<br>\n";
			print OUT "</ul></ul>";
		}
		else	{
			print OUT "
			<ul>
			<li><a name=\"QC steps\" id=\"QC steps\"></a> QC steps - FastQC-report
			<ul>
			FastQC aims to provide a simple way to do some quality control checks on raw sequence data coming from high throughput sequencing pipelines. It provides a modular set of analyses which you can use to give a quick impression of whether your data has any problems of which you should be aware before doing any further analysis.
			<u> <a href= \"http://${server}/reports/$run_num/fastqc/ \"target=\"_blank\"><br>ClickMe</a></u>
			<br><b><u>NOTE:</b></u> FastQC runs a series of tests and will flag up and potential problems with your data<br>\n";
		print OUT "</ul></ul>";
		}	
	}
	
	##################
	### STATISTICS ###
	##################
	
	print OUT"
	<ul><li><a name=\"Statistics based on per sample analysis\" id=\"Statistics based on per sample analysis\"></a>Statistics based on per Sample Analysis(<u><a href=\"StatisticsDescription.html\"target=\"_blank\">ColumnDescription</a></u>)<br>\n";
	print OUT "<br><table cellspacing=\"0\" class=\"sofT\"><tr><td class=\"helpHed\"><p align='center'></td>";
	my %sample_numbers=();
	my $uniq;
	
	# storing all the numbers in a Hash per sample
	chomp $multi;
	print SOUT "SampleNamesUsed/info";
	
	if ($multi eq 'NO')	{
		for(my $k = 0; $k < $num_samples;$k++)	
		{
			print OUT "<td class=\"helpHed\"><p align='center'>$sampleArray[$k]</td>";
			print SOUT "\t$sampleArray[$k]";
			my $file="$path/numbers/$sampleArray[$k].out";
			open SAMPLE, "<$file", or die "could not open $file : $!";
			print"reading numbers from $sampleArray[$k]\n";
			my $id=0;
			while(my $l = <SAMPLE>)	{			
				chomp $l;
				if ( $l !~ /^\d/)	{
					$uniq = $id;
					$id++;
				}	
				else	{
					push (@{$sample_numbers{$uniq}},$l);
				}
			}	
			close SAMPLE;
		}
	}
	else	{
		for (my $i = 0; $i < $num_groups; $i++)	{
			my @sams=split(/\t/,`cat $sample_info | grep -w "^$groupArray[$i]" | cut -d '=' -f2`);
			for (my $j = 0; $j <=$#sams; $j++)	{
				chomp $sams[$j];
				print OUT "<td class=\"helpHed\"><p align='center'>$groupArray[$i]-$sams[$j]</td>";
				print SOUT "\t$groupArray[$i]-$sams[$j]";
				my $file="$path/numbers/$groupArray[$i].$sams[$j].out";
				open SAMPLE, "<$file", or die "could not open $file : $!";
				print"reading numbers from $groupArray[$i] - $sams[$j]\n";
				my $id=0;
				while(my $l = <SAMPLE>)	{			
					chomp $l;
					if ( $l !~ /^\d/)	{
						$uniq = $id;
						$id++;
					}	
					else	{
						push (@{$sample_numbers{$uniq}},$l);
					}
				}	
				close SAMPLE;
			}
		}	
	} 
	
	
	print SOUT "\n";
	print SOUT "lanes";
	if ($multi eq "NO")	{
		for(my $k = 0; $k < $num_samples;$k++)  {
			print SOUT "\t$laneArray[$k]";
		}
		print SOUT "\n";
	}
	else	{
		for (my $i = 0; $i < $num_groups; $i++)	{
			my @sams=split(/\t/,`cat $sample_info | grep -w "^$groupArray[$i]" | cut -d '=' -f2`);
			for (my $j = 0; $j <=$#sams; $j++)	{
				my $id_n=-1;
				chomp $sams[$j];
				for(my $k = 0; $k < $num_samples;$k++)  {
					chomp $sampleArray[$k];
					if ($sams[$j] eq $sampleArray[$k])	{
						$id_n=$k;
						last;
					}
				}
				print SOUT "\t$laneArray[$id_n]";	
			}
		}
		print SOUT "\n";
	}
	print SOUT "indexes";
	if ($multi eq "NO")	{
		for(my $k = 0; $k < $num_samples;$k++)  {
			print SOUT "\t$IndexArray[$k]";
		}
		print SOUT "\n";
    }
	else	{
		for (my $i = 0; $i < $num_groups; $i++)	{
			my @sams=split(/\t/,`cat $sample_info | grep -w "^$groupArray[$i]" | cut -d '=' -f2`);
			for (my $j = 0; $j <=$#sams; $j++)	{
				my $id_n=-1;
				chomp $sams[$j];
				for(my $k = 0; $k < $num_samples;$k++)  {
					chomp $sampleArray[$k];
					if ($sams[$j] eq $sampleArray[$k])	{
						$id_n=$k;
						last;
					}
				}
				print SOUT "\t$IndexArray[$id_n]";	
			}
		}
		print SOUT "\n";
	}
	print OUT "</tr>";
	
	
	my @To_find;
	my ( $avg_per, $avg_mapped_reads, $per_mapped, $per_mapped_reads );
	my @what;
	$multi =~ s/\s+$//;
	$analysis =~ s/\s+$//;
	
	my (@align,@snv,@indel,@sv);
	my (@align_h,@snv_h,@indel_h,@sv_h);
	my (@names,@values);
	
	if ($multi eq 'NO')	{
		if ($analysis eq 'realignment' || $analysis eq 'realign-mayo' || $analysis eq 'mayo' || $analysis eq 'external')	{
			if ($tool eq 'exome')	{
				@align=("Total Reads","Mapped Reads","Percent duplication","Realigned Mapped Reads","Mapped Reads(in CaptureRegion)");
				@align_h=("Total number of reads obtained","Number of reads mapped to the reference using ${Aligner}","Percent of duplicated reads flagged in BAM(using Picard)","Number of reads after recalibration and realignment (using GATK)","Number of mapped reads overlapping with the capture kit used");
				
				@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","SNVs in CaptureRegion",
				"Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME",
				"Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions","Number of SNVs observed in  Capture Region",
				"Total number of SNVs in dbSNP$dbsnp_v or 1000 Genomes", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v or 1000 Genomes", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","INDELs in CaptureRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","Number of INDELs observed in  Capture Region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				@names=(@align,@snv,@indel);
				@values=(@align_h,@snv_h,@indel_h);
			}	
			elsif ($tool eq 'whole_genome')	{
				@align=("Total Reads","Mapped Reads","Percent duplication","Realigned Mapped Reads","Mapped Reads(in CodingRegion)");
				@align_h=("Total number of reads obtained","Number of reads mapped to the reference using ${Aligner}","Percent of duplicated reads flagged in BAM(using Picard)","Number of reads after recalibration and realignment (using GATK)","Number of mapped reads overlapping with the coding region from UCSC refFlat file");
				
				@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME","Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions",
				"Total number of SNVs in dbSNP$dbsnp_v or 1000 Genomes", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v or 1000 Genomes", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				
				@sv=("Total CNVs","Coding CNVs","Coding Deletions","Coding Duplications","Total SVs","Coding SVs","Intra-chr translocations","Inversions","Deletions","Insertions","Inter-chr translocations");
				@sv_h=("Total number of CNVs","Number of CNVs observed in UCSC RefFlat coding regions","Number of deletions in UCSC RefFlat coding regions","Number of duplications in UCSC RefFlat coding regions","total number of SVs","Number of SVs observed in UCSC RefFlat coding regions","Number of ITX in UCSC RefFlat coding regions","Number of INV in UCSC RefFlat coding regions","Number of DEL in UCSC RefFlat coding regions","Number of INS in UCSC RefFlat coding regions","Number of CTX in UCSC RefFlat coding regions");
				@names=(@align,@snv,@indel,@sv);
				@values=(@align_h,@snv_h,@indel_h,@sv_h);
			}		
		}
		elsif ($analysis eq 'variant')	{
			if ($tool eq 'exome')	{
				@align=("Total Reads","Realigned Mapped Reads","Mapped Reads(in CaptureRegion)");
				@align_h=("Total number of reads obtained","Number of reads after recalibration and realignment (using GATK)","Number of mapped reads overlapping with the capture kit used");
				
				@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","SNVs in CaptureRegion",
				"Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME",
				"Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions","Number of SNVs observed in  Capture Region",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","INDELs in CaptureRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","Number of INDELs observed in  Capture Region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				@names=(@align,@snv,@indel);
				@values=(@align_h,@snv_h,@indel_h);
			}	
			elsif ($tool eq 'whole_genome')	{
				@align=("Total Reads","Realigned Mapped Reads","Mapped Reads(in CodingRegion)");
				@align_h=("Total number of reads obtained","Number of reads after recalibration and realignment (using GATK)","Number of mapped reads overlapping with the coding region from UCSC refFlat file");
				
				@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME","Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				
				@sv=("Total CNVs","Coding CNVs","Coding Deletions","Coding Duplications","Total SVs","Coding SVs","Intra-chr translocations","Inversions","Deletions","Insertions","Inter-chr translocations");
				@sv_h=("Total number of CNVs","Number of CNVs observed in UCSC RefFlat coding regions","Number of deletions in UCSC RefFlat coding regions","Number of duplications in UCSC RefFlat coding regions","total number of SVs","Number of SVs observed in UCSC RefFlat coding regions","Number of ITX in UCSC RefFlat coding regions","Number of INV in UCSC RefFlat coding regions","Number of DEL in UCSC RefFlat coding regions","Number of INS in UCSC RefFlat coding regions","Number of CTX in UCSC RefFlat coding regions");
				@names=(@align,@snv,@indel,@sv);
				@values=(@align_h,@snv_h,@indel_h,@sv_h);
			}
		}
		elsif ($analysis eq 'alignment')	{
			@align=("Total Reads","Mapped Reads","Percent duplication");
			@align_h=("Total number of reads obtained","Number of reads mapped to the reference using ${Aligner}","Percent of duplicated reads flagged in BAM(using Picard)");
			@names=(@align);
			@values=(@align_h);
		}
		elsif ($analysis eq 'annotation')	{
			if ($variant_type eq 'BOTH' )	{
				@snv=("Total SNVs (${SNV_caller})","Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME","Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				@names=(@snv,@indel);
				@values=(@snv_h,@indel_h);
			}
			elsif ($variant_type eq 'SNV')	{
				@snv=("Total SNVs (${SNV_caller})","Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME","Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				@names=(@snv);
				@values=(@snv_h);
			}
			elsif ($variant_type eq 'INDEL')	{
				@indel=("Total INDELs (GATK)","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				@names=(@indel);
				@values=(@indel_h);
			}
		}
		elsif ($analysis eq 'ontarget')	{
			if ($tool eq 'exome')	{
				@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","SNVs in CaptureRegion",
				"Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME",
				"Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions","Number of SNVs observed in  Capture Region",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","INDELs in CaptureRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","Number of INDELs observed in  Capture Region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				@names=(@snv,@indel);
				@values=(@snv_h,@indel_h);
			}	
			elsif ($tool eq 'whole_genome')	{
				@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME","Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				@names=(@snv,@indel);
				@values=(@snv_h,@indel_h);
			}
		}
		else	{
			print "incorrect analysis type \n";
			exit 1;
		}	
	}
	elsif ($multi eq 'YES')	{
		if ($analysis eq 'mayo' || $analysis eq 'external' || $analysis eq 'realign-mayo' || $analysis eq 'realignment')	{
			if ($tool eq 'exome')	{
				@align=("Total Reads","Mapped Reads","Percent duplication","Mapped Reads(in CaptureRegion)");
				@align_h=("Total number of reads obtained","Number of reads mapped to the reference using ${Aligner}","Percent of duplicated reads flagged in BAM(using Picard)","Number of mapped reads overlapping with the capture kit used");
				
				@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","SNVs in CaptureRegion",
				"Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME",
				"Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions","Number of SNVs observed in  Capture Region",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","INDELs in CaptureRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","Number of INDELs observed in  Capture Region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				@names=(@align,@snv,@indel);
				@values=(@align_h,@snv_h,@indel_h);
			}	
			elsif ($tool eq 'whole_genome')	{
				@align=("Total Reads","Mapped Reads","Percent duplication","Mapped Reads(in CodingRegion)");
				@align_h=("Total number of reads obtained","Number of reads mapped to the reference using ${Aligner}","Percent of duplicated reads flagged in BAM(using Picard)","Number of mapped reads overlapping with the coding region from UCSC refFlat file");
				
				@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME","Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				
				@sv=("Total CNVs","Coding CNVs","Coding Deletions","Coding Duplications","Total SVs","Coding SVs","Intra-chr translocations","Inversions","Deletions","Insertions","Inter-chr translocations");
				@sv_h=("Total number of CNVs","Number of CNVs observed in UCSC RefFlat coding regions","Number of deletions in UCSC RefFlat coding regions","Number of duplications in UCSC RefFlat coding regions","total number of SVs","Number of SVs observed in UCSC RefFlat coding regions","Number of ITX in UCSC RefFlat coding regions","Number of INV in UCSC RefFlat coding regions","Number of DEL in UCSC RefFlat coding regions","Number of INS in UCSC RefFlat coding regions","Number of CTX in UCSC RefFlat coding regions");
				@names=(@align,@snv,@indel,@sv);
				@values=(@align_h,@snv_h,@indel_h,@sv_h);
			}	
		}
		elsif ($analysis == "variant")	{
			if ($tool eq 'exome')	{
				@align=("Mapped Reads(in CaptureRegion)");
				@align_h=("Number of mapped reads overlapping with the capture kit used");
				
				@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","SNVs in CaptureRegion",
				"Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME",
				"Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions","Number of SNVs observed in  Capture Region",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","INDELs in CaptureRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","Number of INDELs observed in  Capture Region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				@names=(@align,@snv,@indel);
				@values=(@align_h,@snv_h,@indel_h);
			}	
			elsif ($tool eq 'whole_genome')	{
				@align=("Mapped Reads(in CodingRegion)");
				@align_h=("Number of mapped reads overlapping with the coding region from UCSC refFlat file");
				
				@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME","Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				
				@sv=("Total CNVs","Coding CNVs","Coding Deletions","Coding Duplications","Total SVs","Coding SVs","Intra-chr translocations","Inversions","Deletions","Insertions","Inter-chr translocations");
				@sv_h=("Total number of CNVs","Number of CNVs observed in UCSC RefFlat coding regions","Number of deletions in UCSC RefFlat coding regions","Number of duplications in UCSC RefFlat coding regions","total number of SVs","Number of SVs observed in UCSC RefFlat coding regions","Number of ITX in UCSC RefFlat coding regions","Number of INV in UCSC RefFlat coding regions","Number of DEL in UCSC RefFlat coding regions","Number of INS in UCSC RefFlat coding regions","Number of CTX in UCSC RefFlat coding regions");
				@names=(@align,@snv,@indel,@sv);
				@values=(@align_h,@snv_h,@indel_h,@sv_h);
			}
		}	
	}
	
	if ($multi eq "YES")	{
		$num_samples=0;
		for (my $i = 0; $i < $num_groups; $i++)	{
			my @sams=split(/\t/,`cat $sample_info | grep -w "^$groupArray[$i]" | cut -d '=' -f2`);
			for (my $j = 0; $j <=$#sams; $j++)	{
				$num_samples++;
			}
		}
	}		
		
	if ($analysis ne 'annotation' && $analysis ne 'ontarget' )	{
		print OUT "<th class=\"helpBod\">Alignment </th>";
		for (my $c=0; $c < $num_samples;$c++)	{
			print OUT "<td class=\"helpHed\"></td>";
		}		
		print OUT "</tr>\n";
	}
	else	{
		if ($variant_type eq 'BOTH'  || $variant_type eq 'SNV')	{
			print OUT "<th class=\"helpBod\">Single Nucleotide Variants (SNVs)</th>";
		}
		elsif( $variant_type eq 'INDEL')	{
			print OUT "<th class=\"helpBod\">INsertions DELetions (INDELs)</th>";
		}
		for (my $c=0; $c < $num_samples;$c++)	{
			print OUT "<td class=\"helpHed\"></td>";
		}		
		print OUT "</tr>\n";
	}	
	
	foreach my $key (sort {$a <=> $b} keys %sample_numbers)	{
		print OUT "<td class=\"helpHed\"><p align='left'><a href=\"#$names[$key]\" title=\"$values[$key]\">$names[$key]</a></td>";
		print SOUT "$names[$key]";
		if ( $key eq '1' && $analysis ne 'annotation'  && $analysis ne 'ontarget' && $multi eq 'NO' )	{
				for (my $c=0; $c < $num_samples;$c++)	{
					my $per_mapped = sprintf("%.1f",(${$sample_numbers{$key}}[$c] / ${$sample_numbers{0}}[$c]) * 100);
					my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
					print OUT "<td class=\"helpBod\">$print <br> <b>($per_mapped \%) <b></td>";
					print SOUT "\t$print ($per_mapped \%)";
					$avg_mapped_reads=$avg_mapped_reads + ${$sample_numbers{$key}}[$c];
					$per_mapped_reads = $per_mapped_reads + $per_mapped; 
				}
				$avg_mapped_reads=$avg_mapped_reads/$num_samples;$avg_mapped_reads=int($avg_mapped_reads/1000000);
				$per_mapped_reads =$per_mapped_reads/$num_samples;
				print OUT "</tr>\n";
				#print SOUT "\n";
		}
		if ($key eq '1' && ( $analysis eq 'realignment' || $analysis eq 'realign-mayo' || $analysis eq 'external' || $analysis eq 'mayo')	&& $multi eq 'YES')	{
			for (my $c=0; $c < $num_samples;$c++)	{
					my $per_mapped = sprintf("%.1f",(${$sample_numbers{$key}}[$c] / ${$sample_numbers{0}}[$c]) * 100);
					my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
					print OUT "<td class=\"helpBod\">$print <br> <b>($per_mapped \%) <b></td>";
					print SOUT "\t$print ($per_mapped \%)";
					$avg_mapped_reads=$avg_mapped_reads + ${$sample_numbers{$key}}[$c];
					$per_mapped_reads = $per_mapped_reads + $per_mapped; 
				}
				$avg_mapped_reads=$avg_mapped_reads/$num_samples;$avg_mapped_reads=int($avg_mapped_reads/1000000);
				$per_mapped_reads =$per_mapped_reads/$num_samples;
				print OUT "</tr>\n";
				#print SOUT "\n";
		}
		
		if ($key eq '2' && $analysis ne 'annotation' && $analysis ne 'variant' && $analysis ne 'ontarget' && $multi eq 'NO'  )	{
			for (my $c=0; $c < $num_samples;$c++)	{
				my $print=sprintf("%.4f",$sample_numbers{$key}[$c]);
				my $duplicate=sprintf("%.1f",($print * 100));
				print OUT "<td class=\"helpBod\">$duplicate\%</td>";
				print SOUT "\t$duplicate\%";
			}		
			print OUT "</tr>\n";
			#print SOUT "\n";
		}
		elsif ($key eq '2' && $analysis eq 'variant' && $multi eq 'NO')	{
			for (my $c=0; $c < $num_samples;$c++)	{
				my $per_mapped = sprintf("%.1f",(${$sample_numbers{$key}}[$c] / ${$sample_numbers{0}}[$c]) * 100);
				my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
				print OUT "<td class=\"helpBod\">$print <br> <b>($per_mapped \%) <b></td>";	
				print SOUT "\t$print ($per_mapped \%)";	
			}
			print OUT "</tr>\n";
			#print SOUT "\n";
		}
		elsif ($key eq '2' && ( $analysis eq 'realignment' || $analysis eq 'realign-mayo' || $analysis eq 'external' || $analysis eq 'mayo')	&& $multi eq 'YES')	{
			for (my $c=0; $c < $num_samples;$c++)	{
				my $print=sprintf("%.4f",$sample_numbers{$key}[$c]);
				my $duplicate=sprintf("%.1f",($print * 100));
				print OUT "<td class=\"helpBod\">$duplicate\%</td>";
				print SOUT "\t$duplicate\%";
			}		
			print OUT "</tr>\n";
			#print SOUT "\n";
		}
		if ($key eq '3' && $analysis ne 'annotation' && $analysis ne 'variant' && $analysis ne 'ontarget' && $multi eq 'NO' )	{
			for (my $c=0; $c < $num_samples;$c++)	{
				my $per_mapped = sprintf("%.1f",(${$sample_numbers{$key}}[$c] / ${$sample_numbers{0}}[$c]) * 100);
				my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
				print OUT "<td class=\"helpBod\">$print <br> <b>($per_mapped \%) <b></td>";	
				print SOUT "\t$print ($per_mapped \%)";	
			}
			print OUT "</tr>\n";
			#print SOUT "\n";
		}
		if ($key eq '3' && ( $analysis eq 'realignment' || $analysis eq 'realign-mayo' || $analysis eq 'external' || $analysis eq 'mayo')	&& $multi eq 'YES')	{
			for (my $c=0; $c < $num_samples;$c++)	{
				my $per_mapped = sprintf("%.1f",(${$sample_numbers{$key}}[$c] / ${$sample_numbers{0}}[$c]) * 100);
				my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
				print OUT "<td class=\"helpBod\">$print <br> <b>($per_mapped \%) <b></td>";	
				print SOUT "\t$print ($per_mapped \%)";
			}
			print OUT "</tr>\n";
			#print SOUT "\n";
		}
		if ($key eq '4' && $analysis ne 'annotation' && $analysis ne 'variant' && $analysis ne 'ontarget' && $multi ne 'YES')	{
			for (my $c=0; $c < $num_samples;$c++)	{
				my $per_mapped = sprintf("%.1f",(${$sample_numbers{$key}}[$c] / ${$sample_numbers{0}}[$c]) * 100);
				my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
				print OUT "<td class=\"helpBod\">$print <br> <b>($per_mapped \%) <b></td>";	
				print SOUT "\t$print ($per_mapped \%)";
			}
			print OUT "</tr>\n";
			#print SOUT "\n";
		}
					
		
		if ($analysis ne 'annotation' && $analysis ne 'ontarget')	{
			for ( my $c=0; $c < $num_samples; $c++ )	{
				if ($multi eq 'NO')	{
					if ($analysis ne 'variant')	{
						if ( ( $key ne '1') && ( $key ne '3' ) && ($key ne '2') && ($key ne '4') )	{
							my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
							print OUT "<td class=\"helpBod\">$print</td>\n";	
							print SOUT "\t$print";
						}
					}
					elsif ($analysis eq 'variant')	{
						if ( ( $key ne '1') && ( $key ne '2') )	{
							my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
							print OUT "<td class=\"helpBod\">$print</td>\n";	
							print SOUT "\t$print";
						}
					}
				}
				elsif ($multi eq 'YES')	{
					if ($analysis ne 'variant')	{
						if ( ( $key ne '1') && ( $key ne '3' ) && ($key ne '2'))	{
							my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
							print OUT "<td class=\"helpBod\">$print</td>\n";
							print SOUT "\t$print";							
						}
					}
					elsif ($analysis eq 'variant')	{
							my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
							print OUT "<td class=\"helpBod\">$print</td>\n";	
							print SOUT "\t$print";
						
					}
				}	
			}
		}
		else	{
			for ( my $c=0; $c < $num_samples; $c++ )	{
					my $print=CommaFormatted(${$sample_numbers{$key}}[$c]);
					print OUT "<td class=\"helpBod\">$print</td>\n";
					print SOUT "\t$print";
			}
		}
		print OUT "</tr>";
		print SOUT "\n";
		if ( ( $analysis eq 'external' ) || ($analysis eq 'realignment') || ($analysis eq 'mayo') || ($analysis eq 'realign-mayo')) {	
			if ($tool eq 'whole_genome')	{
				my @key_num;
				my @subheader=("Single Nucleotide Variants (SNVs)","Known SNVs","HIGH Impact","Moderate Impact","Low Impact","Novel SNVs","HIGH Impact","Moderate Impact","Low Impact","INsertions DELetions (INDELs)","HIGH Impact","Moderate Impact");
				if ($multi eq 'NO')	{
					@key_num=("4","7","9","15","16","24","26","32","33","41","44","46","57","61");
					@subheader=(@subheader,"Copy Number Variants (CNVs)","Structural Variants (SVs)");
				} else	{
					@key_num=("3","6","8","14","15","23","25","31","32","40","43","45");
				}	
				for (my $h=0;$h<=$#key_num;$h++)	{
					if ($key eq $key_num[$h] )	{
						print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
						for (my $c=0; $c < $num_samples;$c++)	{
							print OUT "<td class=\"helpHed\"></td>";
							#print SOUT "\t";
						}		
						print OUT "</tr>\n";
						#print SOUT "\n";
					}	
				}		
			}
			else	{
				if ($multi eq 'NO')	{
					my @key_num=("4","8","10","16","17","25","27","33","34","42","46","48");
					my @subheader=("Single Nucleotide Variants (SNVs)","Known SNVs","HIGH Impact","Moderate Impact","Low Impact","Novel SNVs","HIGH Impact","Moderate Impact","Low Impact","INsertions DELetions (INDELs)","HIGH Impact","Moderate Impact");
					for (my $h=0;$h<=$#key_num;$h++)	{
						if ($key eq $key_num[$h] )	{
							print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
							for (my $c=0; $c < $num_samples;$c++)	{
								print OUT "<td class=\"helpHed\"></td>";
								#print SOUT "\t";
							}		
							print OUT "</tr>\n";
							#print SOUT "\n";
						}	
					}		
				}
				elsif ($multi eq 'YES')	{
					my @key_num=("3","7","9","15","16","24","26","32","33","41","45","47");
					my @subheader=("Single Nucleotide Variants (SNVs)","Known SNVs","HIGH Impact","Moderate Impact","Low Impact","Novel SNVs","HIGH Impact","Moderate Impact","Low Impact","INsertions DELetions (INDELs)","HIGH Impact","Moderate Impact");
					for (my $h=0;$h<=$#key_num;$h++)	{
						if ($key eq $key_num[$h] )	{
							print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
							for (my $c=0; $c < $num_samples;$c++)	{
								print OUT "<td class=\"helpHed\"></td>";
								#print SOUT "\t";
							}		
							print OUT "</tr>\n";
							#print SOUT "\n";
						}	
					}			
				}
			}	
		}
		elsif ($analysis eq 'annotation') {
			if ($variant_type eq 'BOTH'  || $variant_type eq 'SNV')	{
				my @key_num=("0","2","8","9","17","19","25","26");
				my @subheader=("Known SNVs","HIGH Impact","Moderate Impact","Low Impact","Novel SNVs","HIGH Impact","Moderate Impact","Low Impact",);
				for (my $h=0;$h<=$#key_num;$h++)	{
					if ($key eq $key_num[$h] )	{
						print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
						for (my $c=0; $c < $num_samples;$c++)	{
							print OUT "<td class=\"helpHed\"></td>";
							#print SOUT "\t";
						}		
						print OUT "</tr>\n";
						#print SOUT "\n";
					}	
				}
				if ($variant_type eq 'BOTH')	{
					my @key_num=("34","35","37");
					my @subheader=("INsertions DELetions (INDELs)","HIGH Impact","Moderate Impact");
					for (my $h=0;$h<=$#key_num;$h++)	{
						if ($key eq $key_num[$h] )	{
							print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
							for (my $c=0; $c < $num_samples;$c++)	{
								print OUT "<td class=\"helpHed\"></td>";
								#print SOUT "\t";
							}		
							print OUT "</tr>\n";
							#print SOUT "\n";
						}	
					}	
				}
			}
			elsif ($variant_type eq 'INDEL')	{
				my @key_num=("0","2");
				my @subheader=("HIGH Impact","Moderate Impact");
				for (my $h=0;$h<=$#key_num;$h++)	{
					if ($key eq $key_num[$h] )	{
						print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
						for (my $c=0; $c < $num_samples;$c++)	{
							print OUT "<td class=\"helpHed\"></td>";
							#print SOUT "\t";
						}		
						print OUT "</tr>\n";
						#print SOUT "\n";
					}	
				}	
			}
		}
		elsif ($analysis eq 'ontarget')	{
			my @key_num=("3","5","11","12","20","22","28","29","37","41","43");
			my @subheader=("Known SNVs","HIGH Impact","Moderate Impact","Low Impact","Novel SNVs","HIGH Impact","Moderate Impact","Low Impact","INsertions DELetions (INDELs)","HIGH Impact","Moderate Impact");
			for (my $h=0;$h<=$#key_num;$h++)	{
				if ($key eq $key_num[$h] )	{
					print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
					for (my $c=0; $c < $num_samples;$c++)	{
						print OUT "<td class=\"helpHed\"></td>";
						#print SOUT "\t";
					}		
					print OUT "</tr>\n";
					#print SOUT "\n";
				}	
			}	
		}
		elsif ($analysis eq 'variant') {
			if ($multi eq 'NO')	{
				if ($tool eq 'exome')	{
					my @key_num=("2","6","8","14","15","23","25","31","32","40","44","46");
					my @subheader=("Single Nucleotide Variants (SNVs)","Known SNVs","HIGH Impact","Moderate Impact","Low Impact","Novel SNVs","HIGH Impact","Moderate Impact","Low Impact","INsertions DELetions (INDELs)","HIGH Impact","Moderate Impact");
					for (my $h=0;$h<=$#key_num;$h++)	{
						if ($key eq $key_num[$h] )	{
							print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
							for (my $c=0; $c < $num_samples;$c++)	{
								print OUT "<td class=\"helpHed\"></td>";
								#print SOUT "\t";
							}		
							print OUT "</tr>\n";
							#print SOUT "\n";
						}	
					}		
				}
				elsif ($tool eq 'whole_genome')	{
					my @key_num=("2","5","7","13","14","22","24","30","31","39","42","44","55","59");
					my @subheader=("Single Nucleotide Variants (SNVs)","Known SNVs","HIGH Impact","Moderate Impact","Low Impact","Novel SNVs","HIGH Impact","Moderate Impact","Low Impact","INsertions DELetions (INDELs)","HIGH Impact","Moderate Impact","Copy Number Variants (CNVs)","Structural Variants (SVs)");
					for (my $h=0;$h<=$#key_num;$h++)	{
						if ($key eq $key_num[$h] )	{
							print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
							for (my $c=0; $c < $num_samples;$c++)	{
								print OUT "<td class=\"helpHed\"></td>";
								#print SOUT "\t";
							}		
							print OUT "</tr>\n";
							#print SOUT "\n";
						}	
					}
				}	
			}
			else	{
				my @subheader=("Single Nucleotide Variants (SNVs)","Known SNVs","HIGH Impact","Moderate Impact","Low Impact","Novel SNVs","HIGH Impact","Moderate Impact","Low Impact","INsertions DELetions (INDELs)","HIGH Impact","Moderate Impact");
				if ($tool eq 'exome')	{
					my @key_num=("0","4","6","12","13","21","23","29","30","38","42","44");
					for (my $h=0;$h<=$#key_num;$h++)	{
						if ($key eq $key_num[$h] )	{
							print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
							for (my $c=0; $c < $num_samples;$c++)	{
								print OUT "<td class=\"helpHed\"></td>";
								print SOUT "\t";
							}		
							#print OUT "</tr>\n";
							#print SOUT "\n";
						}	
					}			
				}
				elsif ($tool eq 'whole_genome')	{
					my @key_num=("0","3","5","11","12","20","22","28","29","37","40","44");
					for (my $h=0;$h<=$#key_num;$h++)	{
						if ($key eq $key_num[$h] )	{
							print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
							for (my $c=0; $c < $num_samples;$c++)	{
								print OUT "<td class=\"helpHed\"></td>";
								#print SOUT "\t";
							}		
							print OUT "</tr>\n";
							#print SOUT "\n";
						}	
					}			
				}
			}
		}
	}	
	undef %sample_numbers;
	print OUT "</table>";
	close SOUT;
	my %group_numbers=();
	if ($multi eq 'YES' && $somatic_calling eq 'YES')	{
		$s_output= "$path/SampleStatistics.pair.tsv";
		open SOUT, ">$s_output" or die "can not open $s_output : $!\n";
		print OUT"
		<br><a name=\"Statistics based on per Group analysis\" id=\"Statistics based on per Group analysis\"></a>Statistics based on per Group Analysis(<u><a href=\"StatisticsDescription.html\"target=\"_blank\">ColumnDescription</a></u>)<br>\n";
		print OUT "<br><table cellspacing=\"0\" class=\"sofT\"><tr><td class=\"helpHed\"><p align='center'></td>";
		my $tot=0;
		print SOUT "GroupNamesUsed/info";
		for(my $k = 0; $k < $num_groups;$k++)	
		{
			my $sams=`cat $sample_info | grep -w "^$groupArray[$k]" | cut -d '=' -f2`;
			my @sam=split('\s+',$sams);
			for (my $q=1;$q <=$#sam;$q++)	{
				chomp $sam[$q];
				print OUT "<td class=\"helpHed\"><p align='center'>SOMATIC:$groupArray[$k] - $sam[$q] </td>";
				print SOUT "\tSOMATIC:$groupArray[$k] - $sam[$q]";
				my $file="$path/numbers/TUMOR.$groupArray[$k].$sam[$q].out";
				open SAMPLE, "<$file", or die "could not open $file : $!";
				print"reading numbers from $groupArray[$k] - $sam[$q]\n";
				my $id=0;
				while(my $l = <SAMPLE>)	
				{			
					chomp $l;
					if ( $l !~ /^\d/)	{
						$uniq = $id;
						$id++;
					}	
					else	{
						push (@{$group_numbers{$uniq}},$l);
					}
				}	
				close SAMPLE;
			}
			$tot=$tot+$#sam;
		}
		$tot=$tot-1;
		print OUT "</tr>";
		print SOUT "\n";
		@align=("Combined Total Reads","Combined Mapped Reads");
		@align_h=("Total number of combined reads of the pair after realignment and recalibration","Number of reads mapped of the pair after realignment and recalibration");
		if ($tool eq 'exome')	{
			@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","SNVs in CaptureRegion",
				"Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME",
				"Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
			@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions","Number of SNVs observed in  Capture Region",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","INDELs in CaptureRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","Number of INDELs observed in  Capture Region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
			@names=(@align,@snv,@indel);
				@values=(@align_h,@snv_h,@indel_h);
		}
		elsif ($tool eq 'whole_genome')	{
			@snv=("Total SNVs (${SNV_caller})","Filtered SNVs (${SNV_caller})","SNVs in CodingRegion","Total SNVs (KNOWN)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME","Total SNVs (NOVEL)","Ti/Tv Ratio","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","START_LOST","STOP_GAINED","STOP_LOST","RARE_AMINO_ACID","NON_SYNONYMOUS_CODING","SYNONYMOUS_START","NON_SYNONYMOUS_START","START_GAINED","SYNONYMOUS_CODING","SYNONYMOUS_STOP","NON_SYNONYMOUS_STOP","UTR_5_PRIME","UTR_3_PRIME");
				@snv_h=("Total number of SNVs obtained using ${SNV_caller}","Filtered SNVs obtained using ${SNV_caller} recommendations","Number of SNVs observed in  UCSC RefFlat coding regions",
				"Total number of SNVs in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region",
				"Total number of SNVs not in dbSNP$dbsnp_v", "Transition to Transversion Ratio. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon)","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon)","Variant causes start codon to be mutated into a non-start codon","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes stop codon to be mutated into a non-stop codon","The variant hits a rare amino acid thus is likely to produce protein loss of function","Variant causes a codon that produces a different amino acid","Variant causes start codon to be mutated into another start codon","Variant causes start codon to be mutated into another start codon (the new codon produces a different AA)","A variant in 5'UTR region produces a three base sequence that can be a START codon","Variant causes a codon that produces the same amino acid","Variant causes stop codon to be mutated into another stop codon.","Variant causes stop codon to be mutated into another stop codon","Variant hits 5'UTR region","Variant hits 3'UTR region");
				
				@indel=("Total INDELs (GATK)","Filtered INDELs (GATK)","INDELs in CodingRegion","EXON_DELETED","FRAME_SHIFT","CODON_CHANGE","UTR_5_DELETED","UTR_3_DELETED","CODON_INSERTION","CODON_CHANGE_PLUS_CODON_INSERTION","CODON_DELETION","CODON_CHANGE_PLUS_CODON_DELETION","SPLICE_SITE_ACCEPTOR","SPLICE_SITE_DONOR","UTR_5_PRIME","UTR_3_PRIME");
				@indel_h=("Total  number of INDELs obtained using GATK","Filtered INDELs obtained using GATK recommendations","Number of INDELs observed in  UCSC RefFlat coding region","A deletion removes the whole exon","Insertion or deletion causes a frame shift","One or many codons are changed","	The variant deletes and exon which is in the 5'UTR of the transcript","The variant deletes and exon which is in the 3'UTR of the transcript","One or many codons are inserted","One codon is changed and one or many codons are inserted","	One or many codons are deleted ","One codon is changed and one or more codons are deleted ","The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). ","The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon). ","Variant hits 5'UTR region ","	Variant hits 3'UTR region ");
				
				@sv=("Total CNVs","Coding CNVs","Coding Deletions","Coding Duplications","Total SVs","Coding SVs","Intra-chr translocations","Inversions","Deletions","Insertions","Inter-chr translocations");
				@sv_h=("Total number of CNVs","Number of CNVs observed in UCSC RefFlat coding regions","Number of deletions in UCSC RefFlat coding regions","Number of duplications in UCSC RefFlat coding regions","total number of SVs","Number of SVs observed in UCSC RefFlat coding regions","Number of ITX in UCSC RefFlat coding regions","Number of INV in UCSC RefFlat coding regions","Number of DEL in UCSC RefFlat coding regions","Number of INS in UCSC RefFlat coding regions","Number of CTX in UCSC RefFlat coding regions");
				@names=(@align,@snv,@indel,@sv);
				@values=(@align_h,@snv_h,@indel_h,@sv_h);
		}
		print OUT "<th class=\"helpBod\">Re-Alignment </th>";
                for (my $c=0; $c <= $tot;$c++)   {
                        print OUT "<td class=\"helpHed\"></td>";
                }               
                print OUT "</tr>\n";
				
        
		foreach my $key (sort {$a <=> $b} keys %group_numbers)	{	
			
			if ($tool eq 'exome')	{
				my @key_num=("2","6","8","14","15","23","25","31","32","40","44","46","64");
				my @subheader=("Single Nucleotide Variants (SNVs)","Known SNVs","HIGH Impact","Moderate Impact","Low Impact","Novel SNVs","HIGH Impact","Moderate Impact","Low Impact","INsertions DELetions (INDELs)","HIGH Impact","Moderate Impact");
				for (my $h=0;$h<=$#key_num;$h++)	{
					if ($key eq $key_num[$h] )	{
						print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
						for (my $c=0; $c <= $tot;$c++)	{
							print OUT "<td class=\"helpHed\"></td>";
						}		
						print OUT "</tr>\n";
					}
				}
				my $flag=1;
				for (my $h=0;$h<=$#key_num;$h++)	{
					if ($key ne $key_num[$h] )	{
						$flag=1;
					}
					else	{
						$flag=0;
					}
				}		
				if ($flag == 1)	{
						print OUT "<td class=\"helpHed\"><p align='left'><a href=\"#$names[$key]\" title=\"$values[$key]\">$names[$key]</a></td>";
						print SOUT "$names[$key]";
					for(my $k = 0; $k <= $tot;$k++)	{
						my $print=CommaFormatted(${$group_numbers{$key}}[$k]);
						print OUT "<td class=\"helpBod\">$print</td>\n";
						print SOUT "\t$print";
					}
					print OUT "</tr>\n";
					print SOUT "\n";
				}				
			}
			elsif ($tool eq 'whole_genome')	{
				my @key_num=("2","5","7","13","14","22","24","30","31","39","42","44","55","59","66");
				my @subheader=("Single Nucleotide Variants (SNVs)","Known SNVs","HIGH Impact","Moderate Impact","Low Impact","Novel SNVs","HIGH Impact","Moderate Impact","Low Impact","INsertions DELetions (INDELs)","HIGH Impact","Moderate Impact","Copy Number Variants (CNVs)","Structural Variants (SVs)");
				for (my $h=0;$h<=$#key_num;$h++)	{
					if ($key eq $key_num[$h] )	{
						print OUT "<th class=\"helpBod\"><b>$subheader[$h]<b></th>";
						for (my $c=0; $c <= $tot;$c++)	{
							print OUT "<td class=\"helpHed\"></td>";
						}		
						print OUT "</tr>\n";
					}
				}
				my $flag=1;
				for (my $h=0;$h<=$#key_num;$h++)	{
					if ($key ne $key_num[$h] )	{
						$flag=1;
					}
					else	{
						$flag=0;
					}
				}		
				if ($flag == 1)	{
						print OUT "<td class=\"helpHed\"><p align='left'><a href=\"#$names[$key]\" title=\"$values[$key]\">$names[$key]</a></td>";
						print SOUT "$names[$key]";
					for(my $k = 0; $k <= $tot;$k++)	{
						my $print=CommaFormatted(${$group_numbers{$key}}[$k]);
						print OUT "<td class=\"helpBod\">$print</td>\n";
						print SOUT "\t$print";
					}
					print OUT "</tr>\n";
					print SOUT "\n";
				}			
			}	
		}
	}
	undef %group_numbers;
	print OUT "</table>";
	close SOUT;
	
	print DESC "
	<p align='left'><b> Row description for Statistics Table:</p></b>
	<table cellspacing=\"0\" class=\"sofT\"><tr><td class=\"helpHed\">Column</td><td class=\"helpHed\">Description</td></tr>";
	if ($analysis eq 'alignment' )	{
		print DESC"
		<td class=\"helpBod\">Total Reads</td><td class=\"helpBod\">Total number of reads obtained</td></tr>
		<td class=\"helpBod\">Mapped Reads</td><td class=\"helpBod\">Number and percentage of reads mapped to reference genome(${GenomeBuild}) using $Aligner</td></tr>
		<td class=\"helpBod\">Percent duplication</td><td class=\"helpBod\">Percentage of duplicated reads as identified by(picard)</td></tr>
		</table></ul>";	
	}	
	
	if ( ($analysis eq "external") || ($analysis eq "variant" ) || ($analysis eq 'realignment') || ($analysis eq "mayo") || ($analysis eq 'realign-mayo') || ($analysis eq "ontarget") || ($analysis eq "annotation") )	{
		if ($analysis != "annotation")	{
			print DESC"
		<td class=\"helpBod\">Total Reads</td><td class=\"helpBod\">Total number of reads obtained</td></tr>
		<td class=\"helpBod\">Mapped Reads</td><td class=\"helpBod\">Number and percentage of reads mapped to reference genome(${GenomeBuild})</td></tr>
		<td class=\"helpBod\">Percent duplication</td><td class=\"helpBod\">Percentage of duplicated reads as identified by(${SNV_caller}) and flagged in the BAM files</td></tr>
		<td class=\"helpBod\">Realigned Reads </td><td class=\"helpBod\">Number and percenatge of realigned reads with a quality >= 20 mapped to reference genome(${GenomeBuild})</td></tr>";
		}
		print DESC "<td class=\"helpBod\">Total SNVs ${SNV_caller}</td><td class=\"helpBod\">Total number of SNVs obtained using ${SNV_caller} </td></tr>
		<td class=\"helpBod\">Filtered SNVs ${SNV_caller}</td><td class=\"helpBod\">Number of SNVs obtained after passing through ${SNV_caller} VQSR filtering</td></tr>
		<td class=\"helpBod\">Coding SNVs</td><td class=\"helpBod\">Number of SNVs observed to occur in UCSC RefFlat genomic coordinates</td></tr>
		<td class=\"helpBod\">Total SNVs </td><td class=\"helpBod\">Total number of known SNVs, either in dbSNP$dbsnp_v or 1000 Genomes</td></tr>
		<td class=\"helpBod\">Ti/Tv Ratio</td><td class=\"helpBod\">Number of transtitions over number of transversions. Transition is defined as a change among purines or pyrimidines (A to G, G to A, C to T, and T to C). Transversion is defined as a change from purine to pyrimidine or vice versa (A to C, A to T, G to C, G to T, C to A, C to G, T to A, and T to G)</td></tr>
		<td class=\"helpBod\">SPLICE_SITE_ACCEPTOR</td><td class=\"helpBod\">The variant hits a splice acceptor site (defined as two bases before exon start, except for the first exon). </td></tr>
		<td class=\"helpBod\">SPLICE_SITE_DONOR</td><td class=\"helpBod\">The variant hits a Splice donor site (defined as two bases after coding exon end, except for the last exon).</td></tr>
		<td class=\"helpBod\">START_LOST</td><td class=\"helpBod\">	Variant causes start codon to be mutated into a non-start codon. 	aTg/aGg, M/R </td></tr>
		<td class=\"helpBod\">STOP_GAINED</td><td class=\"helpBod\">Variant causes a STOP codon 	Cag/Tag, Q/* </td></tr>
		<td class=\"helpBod\">STOP_LOST</td><td class=\"helpBod\">Variant causes stop codon to be mutated into a non-stop codon 	Tga/Cga, */R </td></tr>
		<td class=\"helpBod\">RARE_AMINO_ACID</td><td class=\"helpBod\">The variant hits a rare amino acid thus is likely to produce protein loss of function </td></tr>
		<td class=\"helpBod\">NON_SYNONYMOUS_CODING</td><td class=\"helpBod\">	Variant causes a codon that produces a different amino acid</td></tr>
		<td class=\"helpBod\">SYNONYMOUS_START</td><td class=\"helpBod\">Variant causes start codon to be mutated into another start codon.</td></tr>
		<td class=\"helpBod\">NON_SYNONYMOUS_START</td><td class=\"helpBod\">Variant causes start codon to be mutated into another start codon (the new codon produces a different AA). </td></tr>
		<td class=\"helpBod\">START_GAINED</td><td class=\"helpBod\">A variant in 5'UTR region produces a three base sequence that can be a START codon. </td></tr>
		<td class=\"helpBod\">SYNONYMOUS_CODING</td><td class=\"helpBod\">Variant causes a codon that produces the same amino acid </td></tr>
		<td class=\"helpBod\">SYNONYMOUS_STOP</td><td class=\"helpBod\">	Variant causes stop codon to be mutated into another stop codon. </td></tr>
		<td class=\"helpBod\">NON_SYNONYMOUS_STOP</td><td class=\"helpBod\">	Variant causes stop codon to be mutated into another stop codon. </td></tr>
		<td class=\"helpBod\">UTR_5_PRIME</td><td class=\"helpBod\">Variant hits 5'UTR region </td></tr>
		<td class=\"helpBod\">UTR_3_PRIME</td><td class=\"helpBod\">Variant hits 3'UTR region </td></tr>
		<td class=\"helpBod\">EXON_DELETED</td><td class=\"helpBod\">Number of Known SNVs that lead to a stop codon</td></tr>
		<td class=\"helpBod\">FRAME_SHIFT</td><td class=\"helpBod\">Insertion or deletion causes a frame shift (An indel size is not multple of 3 )</td></tr>
		<td class=\"helpBod\">CODON_CHANGE</td><td class=\"helpBod\">One or many codons are changed </td></tr>
		<td class=\"helpBod\">UTR_5_DELETED</td><td class=\"helpBod\">The variant deletes and exon which is in the 5'UTR of the transcript </td></tr>
		<td class=\"helpBod\">UTR_3_DELETED</td><td class=\"helpBod\">	The variant deletes and exon which is in the 3'UTR of the transcript </td></tr>
		<td class=\"helpBod\">CODON_INSERTION</td><td class=\"helpBod\">One or many codons are inserted </td></tr>
		<td class=\"helpBod\">CODON_CHANGE_PLUS_CODON_INSERTION</td><td class=\"helpBod\">One codon is changed and one or many codons are inserted </td></tr>
		<td class=\"helpBod\">CODON_DELETION</td><td class=\"helpBod\">	One or many codons are deleted </td></tr>
		<td class=\"helpBod\">CODON_CHANGE_PLUS_CODON_DELETION</td><td class=\"helpBod\">One codon is changed and one or more codons are deleted</td></tr>";
		
		if ($tool eq 'whole_genome')	{
			print DESC"
			<td class=\"helpBod\">Total CNVs</td><td class=\"helpBod\">Total number of CNVs identified</td></tr>
			<td class=\"helpBod\">Coding CNVs</td><td class=\"helpBod\">Number of CNVs observed to occur in genomic coordinates</td></tr>
			<td class=\"helpBod\">Deletions</td><td class=\"helpBod\">Number of deletions found in coding regions</td></tr>
			<td class=\"helpBod\">Duplications</td><td class=\"helpBod\">Number of duplications found in coding regions</td></tr>
			<td class=\"helpBod\">Total SVs</td><td class=\"helpBod\">Ttoal number of SVs identified</td></tr>
			<td class=\"helpBod\">Coding SVs</td><td class=\"helpBod\">Number of SVs observed to occur in genomic coordinates</td></tr>
			<td class=\"helpBod\">Intra-chr translocations</td><td class=\"helpBod\">Number of intra-chromosomal translocations</td></tr>
			<td class=\"helpBod\">Inversions</td><td class=\"helpBod\">Number of inversions</td></tr>
			<td class=\"helpBod\">Deletions</td><td class=\"helpBod\">Number of deletions</td></tr>
			<td class=\"helpBod\">Insertions</td><td class=\"helpBod\">Number of insertions</td></tr>
			<td class=\"helpBod\">Inter-chr translocations</td><td class=\"helpBod\">Number of inter-chromosomal translocations</td></tr>";
		}	
		print DESC "</table></ul>";
	}
	print DESC "</ul>";
	print DESC "</body>\n"; 
	print DESC "</html>\n"; 
	close DESC;
	print OUT "</ul>";
	print OUT "<p align='right'><a href=\"#top\">-top-</a></p>";
	my $re;
	if ($tool eq 'exome')	{
		$re="CaptureRegion";
	}
	elsif($tool eq 'whole_genome')	{
		$re="CodingRegion";
	}	
	if ( ( $analysis eq "external" ) || ( $analysis eq "variant") || ($analysis eq "realignment") || ($analysis eq "mayo") || ($analysis eq 'realign-mayo')  )	{
		my $target=$target_region/1000000;$target=sprintf("%.2f",$target);
		print OUT "
		<ul><li><a name=\"Percent coverage of $re\" id=\"Percent coverage of $re\"></a>Percent coverage of $re
		<ul>
		The Probes Captured a region of $target Mbp. The figure below lists the percentage of that target region which is covered by at least N depth of coverage.
		</ul></ul>";
		print OUT "<a href= \"Coverage.JPG\"target=\"_blank\"><P ALIGN=\"CENTER\"><img border=\"0\" src=\"Coverage.JPG\" width=\"704\" height=\"628\">";
		print OUT "<p align='right'><a href=\"#top\">-top-</a></p>";		
	}
	print OUT "<a name=\"Results and Conclusions\" id=\"Results and Conclusions\"></a><p align='left'><u><b> VI.  Results and Conclusions:</p></u></b>";
	$per_mapped_reads=sprintf("%.2f",$per_mapped_reads);
	if  ($analysis ne "annotation" && $analysis ne "ontarget" && $analysis ne "variant" ) 	{
		print OUT"
		<ul>
		<li> $per_mapped_reads % of the data has been mapped to the genome.
		<li> A high throughput with approximately $avg_mapped_reads million reads passed filtering.
		";
	}	
	if ($analysis ne "alignment")	{
		print OUT "</ul><b><u><ul> IGV Visualization</b></u><br>
		The SNV and INDEL annotation reports (both standard and filtered) include visualization links to IGV to enable a realistic view of the variants. Please follow steps in the following link to setup IGV (takes less than 5 minutes) and utilize this feature.<br>
		<a href= \"IGV_Setup.doc\"target=\"_blank\">IGV setup for variant visualization</a><br><br>";
		
		print OUT "<u><b> Annotation Descriptions: </u></b><br><br>";
		
		print OUT "<b><u>SNPEFF annotation</b></u><br>
		It's a variant annotation and effect prediction tool. It annotates and predicts the effects of variants on genes (such as amino acid changes).
		<br>
		Description about the annotations from SNPEFF can be found here<br>
		<a href= \"http://snpeff.sourceforge.net/faq.html\"target=\"_blank\">Annotations</a><br><br>";
		print OUT "<b><u>Synonymous codon change</b></u><br>
		Genetic code associates a set of sibling codons to the same amino acid, some codons occur more frequently than others in gene sequences. Biased codon usage results from a diversity of factors such as:
		<ul>
		<li>GC-content
		<li>preference for codons with G or C at the third nucleotide position
		<li>leading strand richer in G+T than lagging strand
		<li>translational bias frequently observed in fast growing organisms
		</ul>";
		print OUT "<br><b><u>BGI-Danish200 Exome Dataset</b></u><br>
		The data is from Exome resequencing of 200 individuals of Danish nationality, a collaborative project between BGI and Danish researchers. 
		<ul>
		<li>The BGI200exome column shows the two alleles and their frequencies (minor allele/major allele)
		</ul>";
		print OUT "<br><b><u>ESP5400 Exoem variant Server</b></u><br>
		The goal of the NHLBI GO Exome Sequencing Project (ESP) is to discover novel genes and mechanisms contributing to heart, lung and blood disorders by pioneering the application of next-generation sequencing of the protein coding regions of the human genome across diverse, richly-phenotyped populations and to share these datasets and findings with the scientific community to extend and enrich the diagnosis, management and treatment of heart, lung and blood disorders.";
		print OUT "<br><br><b><u>COSMIC Dataset</b></u><br>
		COSMIC (Catalogue of Somatic Mutations In Cancer) is a comprehensive source of somatic mutations and associated data found in human cancer. It's developed and maintained by the Cancer Genome Project (CGP) at the Wellcome Trust Sanger Institute. The curated data come from scientific papers in the literature and large scale experimental screens from CGP. 
			<ul>
			<li>The COSMIC column shows the COSMIC mutation ID; Mutation CDS; Mutation AA; strand
		</ul>";
	}	
	print OUT "</ul>";
	print OUT "<p align='right'><a href=\"#top\">-top-</a></p>";
	print OUT "<a name=\"Results Delivered\" id=\"Results Delivered\"></a><p align='left'><u><b> VII. Results Delivered</p></u></b>";
	if ($analysis ne 'alignment')	{
		print OUT "<ul>
                <li>Merged ${SNV_caller} results along with SIFT and SNPEFF annotation and Indel Annotation for all samples(<u><a href=\"ColumnDescription_Reports.xls\"target=\"_blank\">Column Description for Reports</a></u>)<br>";
				if ($multi eq "NO")	{
					if ($variant_type eq 'BOTH' || $variant_type eq 'SNV')	{
						print OUT "<u> <a href= \"Reports/SNV.xls\"target=\"_blank\">SNV Report</a></u> <br>";
					}
					if ($variant_type eq 'BOTH' || $variant_type eq 'INDEL')	{
						print OUT "<u> <a href= \"Reports/INDEL.xls\"target=\"_blank\">INDEL Report</a></u> <br>";
					}
					print OUT "<br>";
				}
				else	{
					if ($variant_type eq 'BOTH' || $variant_type eq 'SNV')	{
						print OUT "<u> <a href= \"Reports/SNV.xls\"target=\"_blank\">Multi sample SNV Report</a></u> <br>";
					}
					if ($variant_type eq 'BOTH' || $variant_type eq 'INDEL')	{
						print OUT "<u> <a href= \"Reports/INDEL.xls\"target=\"_blank\">Multi sample INDEL Report</a></u> <br>";
					}
					if ($somatic_calling eq 'YES')	{
						if ($variant_type eq 'BOTH' || $variant_type eq 'SNV')	{
							print OUT "<u> <a href= \"Reports/TUMOR.SNV.xls\"target=\"_blank\">Somatic SNV Report</a></u> <br>";
						}
						if ($variant_type eq 'BOTH' || $variant_type eq 'INDEL')	{
							print OUT "<u> <a href= \"Reports/TUMOR.INDEL.xls\"target=\"_blank\">Somatic INDEL Report</a></u> <br>";
						}
					}	
				}		
				print OUT "</ul>";
			
		print OUT "<ul>
		<li>Per sample SNV and INDEL files are available here...
		<br><u> <a href= \"Reports_per_Sample\"target=\"_blank\">Per Sample Reports</a></u></ul>";
		if ($multi eq 'NO')	{
			print OUT "<ul>
			<li>Per sample Gene Summary files are available here<br>
			<u> <a href= \"Reports_per_Sample/ANNOT/\"target=\"_blank\">Per Sample Reports</a></u></ul>";
		}
		else	{
			if ($somatic_calling eq "YES")	{
			print OUT "<ul>
			<li>Per tumor-normal Gene Summary files are available here<br>
			<u> <a href= \"Reports_per_Sample/ANNOT/\"target=\"_blank\">Per tumor-normal Reports</a></u></ul>";}
			else{
			print OUT "<ul>
			<li>Per sample Gene Summary files are available here<br>
			<u> <a href= \"Reports_per_Sample/ANNOT/\"target=\"_blank\">Per Sample Reports</a></u></ul>";}
			
		}
	}
	print OUT "</ul>";
	if ($analysis eq 'alignment')	{
		print OUT "<ul>
		<li>Alignment and sorted BAM<br>
		<u> <a href= \"Alignment\"target=\"_blank\">Aligned Bam</a></u></ul>";
	}	
	print OUT "<ul>
		<li>Statistics based on per Sample Analysis are recorded in the tab delimited file<br>
		<u> <a href= \"SampleStatistics.tsv\"target=\"_blank\">SampleStatistics</a></u>";
	if ($multi eq 'YES' && $somatic_calling eq 'YES')	{
		print OUT
		"<br><u> <a href= \"SampleStatistics.pair.tsv\"target=\"_blank\">paired SampleStatistics</a></u>";
	}	
	print OUT "<\ul>";
	print OUT "</ul>";
	if ($tool eq 'whole_genome' && $analysis ne 'alignment' && $analysis ne 'annotation')	{
		if ($multi eq 'NO' || $somatic_calling eq 'NO')	{
			print OUT "<ul> <li>Per sample Circos plots are displayed (and linked) below. Copy Number Variants and Sructural Variants are plotted for each sample. <br>
			<u> <a href= \"circos\"target=\"_blank\">Per sample CIRCOS plots</a></u></ul>";
			for(my $k = 0; $k < $num_samples;$k++)	
			{
				print OUT "<a href= \"circos/${sampleArray[$k]}.sv_cnv.png\"target=\"_blank\"><P ALIGN=\"CENTER\"><img border=\"0\" src=\"circos/${sampleArray[$k]}.sv_cnv.png\" width=\"50\" height=\"50\"><u><caption align=\"bottom\">${sampleArray[$k]}</caption></u></p>";
			}
		}
		elsif($multi eq 'YES' && $somatic_calling eq 'YES')	{
			print OUT "<ul> <li>Per tumor Circos plots are displayed (and linked) below. Copy Number Variants and Sructural Variants are plotted for each sample. <br>
			<u> <a href= \"circos\"target=\"_blank\">Per sample CIRCOS plots</a></u></ul>";
			for(my $k = 0; $k < $num_groups;$k++)	{
				my $sams=`cat $sample_info | grep -w "$groupArray[$k]" | cut -d '=' -f2`;
				my @sam=split('\s+',$sams);
				for (my $q=1;$q <=$#sam;$q++)	{
					chomp ${sam[$q]};
					print OUT "<a href= \"circos/$groupArray[$k].${sam[$q]}.sv_cnv.png\"target=\"_blank\"><P ALIGN=\"CENTER\"><img border=\"0\" src=\"circos/$groupArray[$k].${sam[$q]}.sv_cnv.png\" width=\"50\" height=\"50\"><u><caption align=\"bottom\">$groupArray[$k].${sam[$q]}</caption></u></p>";	
				}
			}	
		}
	}	
	print OUT "</ul>";
	if ($upload_tb eq 'YES')	{
		print OUT "
		<ul><li>Variant calls can be visualized and filtered using TableBrowser<br>
		<u> <a href= \"http://${host}:${port}/TREATTableBrowser/\"target=\"_blank\">TableBrowser</a></u></ul>";
	}
	
	print OUT "<p align='right'><a href=\"#top\">-top-</a></p>";
	print OUT "<a name=\"Useful Links\" id=\"Useful Links\"></a><p align='left'><b><u> VIII. Useful Links</p></b></u>
	<ul>
	<li><a href= \"http://sift.jcvi.org/www/SIFT_help.html\"target=\"_blank\">SIFT</a>
	<li><a href= \"http://snpeff.sourceforge.net\"target=\"_blank\">snpEff</a>
	<li><a href= \"http://genetics.bwh.harvard.edu/pph2/\"target=\"_blank\">PolyPhen-2</a>
	<li><a href= \"http://circos.ca/\"target=\"_blank\">Circos </a>
	<li><a href= \"http://www.broadinstitute.org/software/igv/\"target=\"_blank\">Integrative Genomics Viewer</a>
	<li><a href= \"http://www.genecards.org/\"target=\"_blank\">GeneCards</a>
	<li><a href= \"http://db.systemsbiology.net/kaviar/\"target=\"_blank\">Kaviar variants</a>
	<li><a href= \"http://www.ncbi.nlm.nih.gov/geo/\"target=\"_blank\">Gene Expression Omnibus</a>
	<li><a href= \"http://genome.ucsc.edu/\"target=\"_blank\">UCSC Genome Browser</a>
	</ul><br>";
	print OUT "
	<b><u>Authorship Consideration</u></b>: Advancing scientific research is a primary motivation of all bioinformaticians and acknowledgment of contribution through authorship on manuscripts arising from this analysis is one way our work is assessed and attributed. We request to be considered for authorship on any manuscripts using the analysis results provided if you believe we have made substantive intellectual contributions to the study.  
	";
	print OUT "
	<p align='center'> ��� <b>Powered by Mayo BIC PI Support</b> ���  </p> ";
	print OUT "<p align='right'><a href=\"#top\">-top-</a></p>";
 	print OUT "</body>\n"; 
	print OUT "</html>\n"; 
	close OUT;
	print "Document is generated with path as $output.......... \n";
}
	
sub CommaFormatted
{
	my $delimiter = ','; # replace comma if desired
	my($n,$d) = split /\./,shift,2;
	my @a = ();
	while($n =~ /\d\d\d\d/)
	{
		$n =~ s/(\d\d\d)$//;
		unshift @a,$1;
	}
	unshift @a,$n;
	$n = join $delimiter,@a;
	$n = "$n\.$d" if $d =~ /\d/;
	return $n;
}

sub read_files_var{
	my ($filename) = @_;
		open INFILE, "<$filename" or die "$filename $!\n";
	my %variables; 
	LINE:while (<INFILE>) {
	next LINE if /^#|^\s/;
	chomp;

	my ($var, $value) = split (/=/,$_);
	$variables{$var}=$value;
	}
	return (\%variables);
}
