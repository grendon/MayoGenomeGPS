#!/bin/bash

if [ $# -le 4 ];
then
	echo -e "script to merge the per chr report\nUsage: ./sample_report.sh </path/to/output_dir> </path/to/TempReports> <sample name> </path/to/run_info><somatic/germline><SGE_TASK_ID(optional)> ";
else
	set -x
	echo `date`
	output_dir=$1
	TempReports=$2
	sample=$3
	run_info=$4
	type=`echo $5 | tr "[A-Z]" "[a-z]"`	
	if [ $type == "somatic" ]
	then
		prefix="TUMOR"
		sam=$prefix.$sample
	else
		sam=$sample
	fi	
	if [ $6 ]
    then
        SGE_TASK_ID=$6
    fi	
	
	tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
	script_path=$( cat $tool_info | grep -w '^WORKFLOW_PATH' | cut -d '=' -f2 )
	chrs=$( cat $run_info | grep -w '^CHRINDEX' | cut -d '=' -f2)
	chrIndexes=$( echo $chrs | tr ":" "\n" )
	variant_type=$( cat $run_info | grep -w '^VARIANT_TYPE' | cut -d '=' -f2| tr "[a-z]" "[A-Z]")
	multi=$( cat $run_info | grep -w '^MULTISAMPLE' | cut -d '=' -f2| tr "[a-z]" "[A-Z]")
	i=1
	for chr in $chrIndexes
	do
		chrArray[$i]=$chr
		let i=i+1
	done
	
	
	if [ $variant_type == "BOTH" -o $variant_type == "SNV" ]
	then
		if [ ! -s $TempReports/$sam.chr${chrArray[1]}.SNV.xls ]
		then
			touch $TempReports/$sam.chr${chrArray[1]}.SNV.xls.fix.log
			$script_path/email.sh $TempReports/$sam.chr${chrArray[1]}.SNV.xls "not exist" reports.sh $run_info
			$script_path/wait.sh $TempReports/$sam.chr${chrArray[1]}.SNV.xls.fix.log
		fi	
		cat $TempReports/$sam.chr${chrArray[1]}.SNV.xls > $output_dir/Reports_per_Sample/$sam.SNV.xls
		cat $TempReports/$sam.chr${chrArray[1]}.final.SNV.xls > $output_dir/Reports_per_Sample/$sam.SNV.final.xls
		if [ ${#chrArray[@]} -gt 1 ]
		then
			for j in $(seq 2 ${#chrArray[@]})
			do
				if [ ! -s $TempReports/$sam.chr${chrArray[$j]}.SNV.xls ]
				then
					touch $TempReports/$sam.chr${chrArray[$j]}.SNV.xls.fix.log
					$script_path/email.sh $TempReports/$sam.chr${chrArray[$j]}.SNV.xls "not exist" reports.sh $run_info
					$script_path/wait.sh $TempReports/$sam.chr${chrArray[$j]}.SNV.xls.fix.log
				fi	
				cat $TempReports/$sam.chr${chrArray[$j]}.SNV.xls | awk 'NR>2' >> $output_dir/Reports_per_Sample/$sam.SNV.xls
				cat $TempReports/$sam.chr${chrArray[$j]}.final.SNV.xls | awk 'NR>2' >> $output_dir/Reports_per_Sample/$sam.SNV.final.xls
			done
		fi
	fi	
	
	if [ $variant_type == "BOTH" -o $variant_type == "INDEL" ]
	then
		if [ ! -s $TempReports/$sam.chr${chrArray[1]}.INDEL.xls ]
		then
			touch $TempReports/$sam.chr${chrArray[1]}.INDEL.xls.fix.log
			$script_path/email.sh $TempReports/$sam.chr${chrArray[1]}.INDEL.xls "not exist" reports.sh $run_info
			$script_path/wait.sh $TempReports/$sam.chr${chrArray[1]}.INDEL.xls.fix.log
		fi	
		cat $TempReports/$sam.chr${chrArray[1]}.INDEL.xls > $output_dir/Reports_per_Sample/$sam.INDEL.xls
		cat $TempReports/$sam.chr${chrArray[1]}.final.INDEL.xls > $output_dir/Reports_per_Sample/$sam.INDEL.final.xls

		if [ ${#chrArray[@]} -gt 1 ]
		then
			for j in $(seq 2 ${#chrArray[@]})
			do
				if [ ! -s $TempReports/$sam.chr${chrArray[$j]}.INDEL.xls ]
				then
					touch $TempReports/$sam.chr${chrArray[$j]}.v.xls.fix.log
					$script_path/email.sh $TempReports/$sam.chr${chrArray[$j]}.INDEL.xls "not exist" reports.sh $run_info
					$script_path/wait.sh $TempReports/$sam.chr${chrArray[$j]}.INDEL.xls.fix.log
				fi
				cat $TempReports/$sam.chr${chrArray[$j]}.INDEL.xls | awk 'NR>2' >> $output_dir/Reports_per_Sample/$sam.INDEL.xls
				cat $TempReports/$sam.chr${chrArray[$j]}.final.INDEL.xls | awk 'NR>2' >> $output_dir/Reports_per_Sample/$sam.INDEL.final.xls
			done
		fi
	fi
	
	### update the dash board
	if [ $multi == "YES" ]
	then
		sample_info=$( cat $run_info | grep -w '^SAMPLE_INFO' | cut -d '=' -f2)
		ss=$( cat $sample_info | grep -w '^$sample' | cut -d '=' -f2 | tr "\t" " ")
		for i in $ss
		do
			$script_path/dashboard.sh $i $run_info Annotation complete
		done
	else
		$script_path/dashboard.sh $sample $run_info Annotation complete
	fi	
	echo `date`
fi	

