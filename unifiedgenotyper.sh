#!/bin/sh

if [ $# != 6 ]
then
    echo -e "Usage: script to run unified genotyper \n <bams><vcf output><type of varint> <range of positions> <output mode><run info file>"
else
    set -x
    echo `date`
    bam=$1
    vcf=$2
    type=$3
    range=$4
    mode=$5
    run_info=$6

    tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
	ped=$( cat $tool_info | grep -w '^PEDIGREE' | cut -d '=' -f2)
    java=$( cat $tool_info | grep -w '^JAVA' | cut -d '=' -f2)
    gatk=$( cat $tool_info | grep -w '^GATK' | cut -d '=' -f2)
    ref=$( cat $tool_info | grep -w '^REF_GENOME' | cut -d '=' -f2)
    dbSNP=$( cat $tool_info | grep -w '^dbSNP_REF' | cut -d '=' -f2)
    threads=$( cat $tool_info | grep -w '^THREADS' | cut -d '=' -f2)
	alt_alleles=$( cat $tool_info | grep -w '^MAX_ALT_ALLELES' | cut -d '=' -f2)
	script_path=$( cat $tool_info | grep -w '^WHOLEGENOME_PATH' | cut -d '=' -f2 )

    check=`[ -s $vcf.idx ] && echo "1" || echo "0"`
    while [ $check -eq 0 ]
    do
		if [ $ped != "NA" ]
		then
			$java/java -Xmx3g -Xms512m -jar $gatk/GenomeAnalysisTK.jar \
			-R $ref \
			-et NO_ET \
			-K $gatk/Hossain.Asif_mayo.edu.key \
			-T UnifiedGenotyper \
			--output_mode $mode \
			-nt $threads \
			--max_alternate_alleles $alt_alleles \
			-glm $type \
			$range \
			$bam \
			--ped $ped \
			--out $vcf
		else
			$java/java -Xmx3g -Xms512m -jar $gatk/GenomeAnalysisTK.jar \
			-R $ref \
			-et NO_ET \
			-K $gatk/Hossain.Asif_mayo.edu.key \
			-T UnifiedGenotyper \
			--output_mode $mode \
			-nt $threads \
			--max_alternate_alleles $alt_alleles \
			-glm $type \
			$range \
			$bam \
			--out $vcf
		fi
        check=`[ -s $vcf.idx ] && echo "1" || echo "0"`
    done

    if [ ! -s $vcf ]
    then
        $script_path/errorlog.sh $vcf unifiedgenotyper.sh ERROR empty
        exit 1;
    fi
    echo `date`
fi