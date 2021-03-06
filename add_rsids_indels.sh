#!/bin/bash

##	INFO
##	to add rsids to per sample report
	
###########################
#		$1		=		TempFolder
#		$2		=		snv input file
#		$3		=		indel input file
#		$3		=		chromomse index
#		$4		=		run info
###############################

if [ $# != 4 ];
then
	echo -e "script to add rsids to the indel report\nUsage: ./add.rsids_indels.sh </path/to/TempReportDir> <indel file><chromosome> </path/to/run info>";
else	
	set -x
	echo `date`
	TempReports=$1
	indel=$2
	chr=$3
	run_info=$4
	tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
	script_path=$( cat $tool_info | grep -w '^WORKFLOW_PATH' | cut -d '=' -f2 )
	dbsnp_rsids_indel=$( cat $tool_info | grep -w '^dbSNP_INDEL_rsIDs' | cut -d '=' -f2)
	GenomeBuild=$( cat $run_info | grep -w '^GENOMEBUILD' | cut -d '=' -f2) 
	num=`cat $TempReports/$indel | wc -l`
	if [ $num -eq 0 ]
	then
		$script_path/errorlog.sh $TempReports/$indel ERROR "not exist"
		exit 1;
	fi	
	
	cat $TempReports/$indel | awk 'NR>1' > $TempReports/$indel.forrsIDs
	if [ `cat $TempReports/$indel.forrsIDs | wc -l` -gt 1 ]
	then
		$script_path/add_dbsnp_indel.pl -i $TempReports/$indel.forrsIDs -b 1 -s $dbsnp_rsids_indel -c 1 -p 2 -x 3 -o $TempReports/$indel.forrsIDs.added -r $chr
	else
		value=`echo $dbsnp_rsids_indel | perl -wlne 'print $1 if /.+dbSNP(\d+)/'`
		echo -e "dbsnp${value}\tdbsnp${value}Alleles" > $TempReports/$indel.forrsIDs.added
		cat $TempReports/$indel.forrsIDs | sed 's/[ \t]*$//' > $TempReports/$indel.forrsIDs.tmp
		mv $TempReports/$indel.forrsIDs.tmp $TempReports/$indel.forrsIDs
		paste $TempReports/$indel.forrsIDs $TempReports/$indel.forrsIDs.added > $TempReports/$indel.forrsIDs.added.tmp
		mv $TempReports/$indel.forrsIDs.added.tmp $TempReports/$indel.forrsIDs.added
	fi		
	cat $TempReports/$indel.forrsIDs.added | awk '{if(NR != 1) print $0"\t0"; else print $0"\tDiseaseVariant"}' > $TempReports/$indel.forrsIDs.added.disease
	$script_path/extract.rsids.pl -i $TempReports/$indel -r $TempReports/$indel.forrsIDs.added.disease -o $TempReports/$indel.rsIDs -v INDEL
	num_a=`cat $TempReports/$indel.rsIDs | wc -l`
	if [ $num == $num_a ]
	then
		rm $TempReports/$indel.forrsIDs.added
		rm $TempReports/$indel.forrsIDs
		rm $TempReports/$indel.forrsIDs.added.disease
		rm $TempReports/$indel
	else
		$script_path/errorlog.sh $TempReports/$indel.rsIDs add.rsids_indel.sh ERROR "failed to create"
		exit 1;
	fi	
	echo `date`
fi	
	
	
