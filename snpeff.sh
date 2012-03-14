#!/bin/sh

##	INFO
##	script used to annotate both SNVs and INDELs by submitting Auto Web submission using a JAVA script
## chekc for the file and submit the script again 08/29/2011
###############################
#	$1		=		sseq output directory	
#	$2		=		sample name
#	$5		=		directory for input file
#	$6		=		Email
#	$7		=		run_innfo
################################# 

if [ $# != 5 ];
then
    echo "Usage:<sseq dir> <samplename><input dir><email><run_info> ";
else
    set -x
    echo `date`
    sseq=$1
    input=$2
    email=$3
	sample=$4
    run_info=$5
    #SGE_TASK_ID=1
	tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
    script_path=$( cat $tool_info | grep -w '^WHOLEGENOME_PATH' | cut -d '=' -f2 )
    java=$( cat $tool_info | grep -w '^JAVA' | cut -d '=' -f2)
    snpeff=$( cat $tool_info | grep -w '^SNPEFF' | cut -d '=' -f2)
    genome_version=$(cat $run_info | grep -w '^GENOMEBUILD' | cut -d '=' -f2)
    analysis=$( cat $run_info | grep -w '^ANALYSIS' | cut -d '=' -f2| tr "[A-Z]" "[a-z]")
    variant_type=$( cat $run_info | grep -w '^VARIANT_TYPE' | cut -d '=' -f2| tr "[a-z]" "[A-Z]")
	chr=$(cat $run_info | grep -w '^CHRINDEX' | cut -d '=' -f2 | tr ":" "\n" | head -n $SGE_TASK_ID | tail -n 1)
	
	if [ $variant_type == "BOTH" -o $variant_type == "SNV" ]
	then
		snv_file=$sample.chr${chr}.raw.snvs.bed.i.ToMerge
		cat $input/$snv_file | cut -f 1,2,3,4 > $sseq/$snv_file.sseq
        
		num_snvs=`cat $sseq/$snv_file.sseq | wc -l`
        if [ $num_snvs -le 1 ]
        then
            touch $sseq/$sample.chr${chr}.snv.sseq
            echo -e "# inDBSNPOrNot\tchromosome\tposition\treferenceBase\tsampleGenotype\taccession\tfunctionGVS\tfunctionDBSNP\trsID\taminoAcids\tproteinPosition\tpolyPhen\tnickLab\tgeneList\tdbSNPValidation\tclinicalAssociation" > $sseq/$sample.chr${chr}.snv.sseq
        else	
            sleep $wait
            check=`[ -f $sseq/$sample.chr${chr}.snv.sseq ] && echo "1" || echo "0"`
            while [ $check -eq 0 ]
            do
                $java/java -Xmx2g -Xms512m -jar $script_path/sseq_submit.jar $sseq/$snv_file.sseq $sseq/$sample.chr${chr}.snv.sseq snp $genome_version $email
                sleep $wait
                check=`[ -f $sseq/$sample.chr${chr}.snv.sseq ] && echo "1" || echo "0"`
            done
        fi
        rm $sseq/$snv_file.sseq
	fi

	if [ $variant_type == "BOTH" -o $variant_type == "INDEL" ]	
	then
		indel_file=$sample.chr${chr}.raw.indels.bed.i.ToMerge
		perl $script_path/convert.indel.pl $input/$indel_file > $sseq/$sample.chr${chr}.indels.temp
        echo "#autoFile $indel_file" > $sseq/$sample.chr${chr}.indels.temp_file
        cat $sseq/$sample.chr${chr}.indels.temp >> $sseq/$sample.chr${chr}.indels.temp_file
        mv $sseq/$sample.chr${chr}.indels.temp_file $sseq/$indel_file
        rm $sseq/$sample.chr${chr}.indels.temp
		num_indels=`cat $sseq/$indel_file | wc -l`
        
        if [ $num_indels -le 1 ]
        then
            touch $sseq/$sample.chr${chr}.indels.sseq
            echo -e "# inDBSNPOrNot\tchromosome\tposition\treferenceBase\tsampleGenotype\taccession\tfunctionGVS\tfunctionDBSNP\trsID\taminoAcids\tproteinPosition\tpolyPhen\tnickLab\tgeneList\tdbSNPValidation\tclinicalAssociation" > $sseq/$sample.chr${chr}.indels.sseq
        else	
            sleep $wait
            check=`[ -f $sseq/$sample.chr${chr}.indels.sseq ] && echo "1" || echo "0"`
            while [ $check -eq 0 ]
            do
                $java/java -Xmx2g -Xms512m -jar $script_path/sseq_submit.jar $sseq/$indel_file $sseq/$sample.chr${chr}.indels.sseq indel $genome_version $email
                sleep $wait
                check=`[ -f $sseq/$sample.chr${chr}.indels.sseq ] && echo "1" || echo "0"`
            done 
        fi
        rm $sseq/$indel_file
	fi
	echo `date`
fi	
		
    
