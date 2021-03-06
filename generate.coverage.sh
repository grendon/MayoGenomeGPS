#!/bin/bash

if [ $# != 3 ]
then
	echo -e "Usage: to plot coverage plot \n <input directory><output dir><run info >"
else
	set -x
	echo `date`
	input=$1
	output=$2
	run_info=$3
	tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
	sample_info=$( cat $run_info | grep -w '^SAMPLE_INFO' | cut -d '=' -f2)
	script_path=$( cat $tool_info | grep -w '^WORKFLOW_PATH' | cut -d '=' -f2)
	tool=$( cat $run_info | grep -w '^TYPE' | cut -d '=' -f2 | tr "[A-Z]" "[a-z]")
	CaptureKit=$( cat $tool_info | grep -w '^CAPTUREKIT' | cut -d '=' -f2 )
	samples=$( cat $run_info | grep -w '^SAMPLENAMES' | cut -d '=' -f2 | tr ":" " " )
	groups=$( cat $run_info | grep -w '^GROUPNAMES' | cut -d '=' -f2 | tr ":" " " )
	multi=$( cat $run_info | grep -w '^MULTISAMPLE' | cut -d '=' -f2| tr "[a-z]" "[A-Z]")
    r_soft=$( cat $tool_info | grep -w '^R_SOFT' | cut -d '=' -f2)
	gene_body=$( cat $tool_info | grep -w '^MATER_GENE_BODY' | cut -d '=' -f2 )
	 
	if [ $tool == "whole_genome" ]
    then
        kit=$gene_body
    else
        kit=$CaptureKit
    fi    
	
	cd $input
	region=`awk '{sum+=$3-$2+1; print sum}' $kit | tail -1`
	
	if [ $multi == "YES" ]
	then
		samples=""
		for group in $groups
		do
			for sam in `cat $sample_info | grep -w "^$group" | cut -f2 -d '=' | tr "\t" " "`
			do
				samples=$samples"$group.$sam "
			done
		done
	fi	
	$r_soft/Rscript $script_path/coverage_plot.r $region $samples
	mv $input/coverage.jpeg $output/Coverage.JPG 
	if [ ! -s $output/Coverage.JPG ]
	then
		$script_path/errorlog.sh $output/Coverage.JPG generate.coverage.sh ERROR "not found"
		exit 1;
	fi	
	echo `date`
fi	
