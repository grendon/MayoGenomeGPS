#!/bin/bash

if [ $# != 5 ]
then
    echo -e "script to run unified genotyper and backfill the positions\nUsage: ./unifiedgenotyper.sh <bams><vcf output><type of varint> <output mode><run info file>"
else
    set -x
    echo `date`
    bam=$1
    vcf=$2
    type=$3
    mode=$4
    run_info=$5

    tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
    ped=$( cat $tool_info | grep -w '^PEDIGREE' | cut -d '=' -f2)
    java=$( cat $tool_info | grep -w '^JAVA' | cut -d '=' -f2)
    gatk=$( cat $tool_info | grep -w '^GATK' | cut -d '=' -f2)
    ref=$( cat $tool_info | grep -w '^REF_GENOME' | cut -d '=' -f2)
    dbSNP=$( cat $tool_info | grep -w '^dbSNP_REF' | cut -d '=' -f2)
    threads=$( cat $tool_info | grep -w '^THREADS' | cut -d '=' -f2)
    script_path=$( cat $tool_info | grep -w '^WORKFLOW_PATH' | cut -d '=' -f2 )
    qual=$( cat $tool_info | grep -w '^BASE_QUALITY' | cut -d '=' -f2 )
    command_line_params=$( cat $tool_info | grep -w '^UnifiedGenotyper_params' | cut -d '=' -f2 )
    memory_info=$( cat $run_info | grep -w '^MEMORY_INFO' | cut -d '=' -f2)
    mem=$( cat $memory_info | grep -w '^UnifiedGenotyper_JVM' | cut -d '=' -f2)
	 
    let check=0
    out=`dirname $vcf`
    
    if [ ! -d $out/temp ]
	then
		mkdir -p $out/temp
	fi
	let count=0
	while [[ $check -eq 0 && $count -le 10 ]]
    do
		$java/java $mem -Djava.io.tmpdir=$out/temp/ -jar $gatk/GenomeAnalysisTK.jar \
		-R $ref \
		-et NO_ET \
		-K $gatk/Hossain.Asif_mayo.edu.key \
		-T UnifiedGenotyper \
		--output_mode $mode \
		--genotyping_mode GENOTYPE_GIVEN_ALLELES \
		--alleles $vcf \
		-glm $type \
		-L $vcf \
		$bam \
		--out $vcf.tmp.vcf $command_line_params
		sleep 5
        check=`[ -s $vcf.tmp.vcf.idx ] && echo "1" || echo "0"`
        if [ $check -eq 0 ]
        then
			if [[  `find . -name '*.log'` ]]
			then
				if [ `grep -l $vcf.tmp.vcf *.log` ]
				then
					rm `grep -l $vcf.tmp.vcf *.log`
					rm core.*
				fi
			fi
		fi 
		let count=count+1	
    done 
    	
	### add AD,DP,DP4 to the original vcf file
	$script_path/revertvcf_formatfields.pl -o $vcf -i $vcf.tmp.vcf -v $vcf.correct.vcf
	rm $vcf.tmp.vcf $vcf.tmp.vcf.idx
	mv $vcf.correct.vcf $vcf	
	rm $vcf.idx	
    echo `date`
fi