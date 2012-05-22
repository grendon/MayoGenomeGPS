#!/bin/sh

if [ $# != 7 ]
then
    echo -e "Usage: script to run somtic indel caller \n <normal bam ><tumor bam><chromosome><tumor sample><output dir><output file vcf><run info>"
else
    set -x
    echo `date`
    tumor_bam=$1
    normal_bam=$2
    chr=$3
    tumor_sample=$4
    output=$5
    output_file=$6
    run_info=$7
    
    tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
    java=$( cat $tool_info | grep -w '^JAVA' | cut -d '=' -f2)
    gatk=$( cat $tool_info | grep -w '^GATK' | cut -d '=' -f2)
    ref=$( cat $tool_info | grep -w '^REF_GENOME' | cut -d '=' -f2)
    dbSNP=$( cat $tool_info | grep -w '^dbSNP_REF' | cut -d '=' -f2)
    window=$( cat $tool_info | grep -w '^INDEL_WINDOW_SIZE' | cut -d '=' -f2)
    expression=$( cat $tool_info | grep -w '^SOMATIC_INDEL_FILTER_EXPRESSION'| cut -d '=' -f2)
	## Somatic Indel detector
    if [ $expression == "NA" ]
	then
		### default filter
		filter="T_COV<6||N_COV<4||T_INDEL_F<0.3||T_INDEL_CF<0.7"
	else
		filter="$expression"
	fi	
    indel_v=$tumor_sample.chr$chr.indel.txt
	
    $java/java -Xmx3g -Xms512m -jar $gatk/GenomeAnalysisTK.jar \
    -R $ref \
    -et NO_ET \
    -K $gatk/Hossain.Asif_mayo.edu.key \
    -T SomaticIndelDetector \
	--filter_expressions $filter \
    --window_size $window \
    -o $output/$output_file \
    -verbose $output/$indel_v \
    -I:normal $normal_bam \
    -I:tumor $tumor_bam
	
    if [ ! -s $output/$output_file ]
    then
        echo "ERROR : variants.sh SomaticIndelDetector failed, file $output/$output_file not generated "
        exit 1;
    else
        rm $output/$indel_v
		cat $output/$output_file | awk '$0 ~ /^#/ || $8 ~ /SOMATIC/' > $output/$output_file.tmp
		mv $output/$output_file.tmp $output/$output_file
    fi
    echo `date`
fi	
	