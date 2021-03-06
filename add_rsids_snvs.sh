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
    echo "Usage<TempReportDir> <snv file><chromosome> <run info>";
else	
    set -x
    echo `date`
    TempReports=$1
    snv=$2
    chr=$3
    run_info=$4
    tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
    script_path=$( cat $tool_info | grep -w '^WORKFLOW_PATH' | cut -d '=' -f2 )
    dbsnp_rsids_snv=$( cat $tool_info | grep -w '^dbSNP_SNV_rsIDs' | cut -d '=' -f2)
    GenomeBuild=$( cat $run_info | grep -w '^GENOMEBUILD' | cut -d '=' -f2)
    dbsnp_rsids_disease=$( cat $tool_info | grep -w '^dbSNP_disease_rsIDs' | cut -d '=' -f2) 
    
    num=`cat $TempReports/$snv | wc -l` 
    if [ $num -eq 0 ]
	then
		$script_path/errorlog.sh $TempReports/$snv add.rsids_snvs.sh ERROR "not created"
		exit 1;
	fi	
	cat $TempReports/$snv | awk 'NR>1' > $TempReports/$snv.forrsIDs
	len=`cat $TempReports/$snv.forrsIDs | wc -l`
	if [ $len -gt 1 ]
	then
		file=`basename $dbsnp_rsids_snv`
		base=`basename $snv`
		cat $dbsnp_rsids_snv | grep -w chr$chr | grep -v 'cDNA' > $TempReports/$file.chr$chr.$snv
		$script_path/add.rsids.pl -i $TempReports/$snv.forrsIDs -s $TempReports/$file.chr$chr.$snv -o $TempReports/$snv.forrsIDs.added
		rm  $TempReports/$file.chr$chr.$snv 
		## add column to add flag for disease variant
		$script_path/add.dbsnp.disease.snv.pl -i $TempReports/$snv.forrsIDs.added -b 1 -s $dbsnp_rsids_disease -c 1 -p 2 -o $TempReports/$snv.forrsIDs.added.disease -r $chr
    else
		value=`echo $dbsnp_rsids_snv | perl -wlne 'print $1 if /.+dbSNP(\d+)/'`
		echo -e "dbsnp${value}\tdbsnp${value}Alleles" > $TempReports/$snv.forrsIDs.added
		cat $TempReports/$snv.forrsIDs | sed 's/[ \t]*$//' > $TempReports/$snv.forrsIDs.tmp
		mv $TempReports/$snv.forrsIDs.tmp $TempReports/$snv.forrsIDs
		paste $TempReports/$snv.forrsIDs $TempReports/$snv.forrsIDs.added > $TempReports/$snv.forrsIDs.added.tmp
		mv $TempReports/$snv.forrsIDs.added.tmp $TempReports/$snv.forrsIDs.added
		echo "DiseaseVariant" > $TempReports/$snv.forrsIDs.added.disease
		paste $TempReports/$snv.forrsIDs.added $TempReports/$snv.forrsIDs.added.disease > $TempReports/$snv.forrsIDs.added.disease.tmp
		mv $TempReports/$snv.forrsIDs.added.disease.tmp $TempReports/$snv.forrsIDs.added.disease 
	fi
	$script_path/extract.rsids.pl -i $TempReports/$snv -r $TempReports/$snv.forrsIDs.added.disease -o $TempReports/$snv.rsIDs -v SNV
    num_a=`cat $TempReports/$snv.rsIDs |wc -l `
    if [ $num == $num_a ]
    then
        rm $TempReports/$snv
        rm $TempReports/$snv.forrsIDs.added
        rm $TempReports/$snv.forrsIDs
        rm $TempReports/$snv.forrsIDs.added.disease
    else
		exit 1;
	fi
    echo `date`
fi	
	
	
