#!/bin/sh
##	INFO
##	merge all the steps for merge report
if [ $# != 5 ]
then
	echo "Usage:<sift> <sseq> <TempReports> <run info> <output ontarget>";
else
	set -x
	echo `date`	
	sift=$1 
	sseq=$2 
	TempReports=$3 
	run_info=$4
	output_OnTarget=$5
	line_number=$SGE_TASK_ID
        #line_number=1
	tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
	script_path=$( cat $tool_info | grep -w '^WHOLEGENOME_PATH' | cut -d '=' -f2 )
	chrs=$( cat $run_info | grep -w '^CHRINDEX' | cut -d '=' -f2)
	chrIndexes=$( echo $chrs | tr ":" "\n" )
	i=1
	for chr in $chrIndexes
	do
		chrArray[$i]=$chr
		let i=i+1
	done
	which_chr=${chrArray[$line_number]}
	##merge anntation
	$script_path/merge.annotations.sh $sift $sseq $which_chr $run_info
	##merge variants
	$script_path/merge.variants.sh $output_OnTarget $TempReports $which_chr $run_info
	snv_var=list.chr${which_chr}.snvs
	indel_var=list.chr${which_chr}.indels
	##add rsids
	$script_path/add.rsids.sh $TempReports $snv_var $indel_var $which_chr $run_info
	##add frequencies
	$script_path/add.frequencies.sh $TempReports $snv_var $which_chr $run_info
	# merge snv file
	$script_path/snp.final.sh $TempReports $sift $sseq $which_chr $snv_var $run_info
	#merge indel file
	$script_path/indel.final.sh $TempReports $sseq $which_chr $indel_var $run_info
	
	echo `date`
fi	