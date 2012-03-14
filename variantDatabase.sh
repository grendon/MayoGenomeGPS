#!/bin/sh

##INFO
## rquired format fiels for variant database
if [ $# != 3 ]
then
    echo "Usage: <TempReports folder> <output> <run info>";
else	
    set -x
    echo `date`
    TempReports=$1 
    output=$2
    run_info=$3
    variant_type=$( cat $run_info | grep -w '^VARIANT_TYPE' | cut -d '=' -f2)
    run_num=$( cat $run_info | grep -w '^OUTPUT_FOLDER' | cut -d '=' -f2)
    # get job array ID
    line_number=$SGE_TASK_ID
    samples=$( cat $run_info | grep -w '^SAMPLENAMES' | cut -d '=' -f2)
    sampleNames=$( echo $samples | tr ":" "\n" )
    i=1
    for sample in $sampleNames
    do
            sampleArray[$i]=$sample
            let i=i+1
    done
    sample=${sampleArray[$line_number]}
    chrs=$( cat $run_info | grep -w '^CHRINDEX' | cut -d '=' -f2)
    chrIndexes=$( echo $chrs | tr ":" "\n" )
    variant_type=`echo "$variant_type" | tr "[a-z]" "[A-Z]"`
    i=1
    for chr in $chrIndexes
    do
            chrArray[$i]=$chr
            let i=i+1
    done
    if [ $variant_type == "BOTH" -o $variant_type == "SNV" ]
    then
            touch $output/${sample}.${run_num}.SNV.txt
            cat $TempReports/$sample.chr${chrArray[1]}.snv >> $output/${sample}.${run_num}.SNV.txt
            sed -i '1d' $output/${sample}.${run_num}.SNV.txt
            for i in $(seq 2 ${#chrArray[@]})
            do
                    sed -i '1d;2d' $TempReports/$sample.chr${chrArray[$i]}.snv
                    cat $TempReports/$sample.chr${chrArray[$i]}.snv >> $output/${sample}.${run_num}.SNV.txt
            done
    fi
    if [ $variant_type == "BOTH" -o $variant_type == "INDEL" ]
    then
            touch $output/${sample}.${run_num}.INDEL.txt
            cat $TempReports/$sample.chr${chrArray[1]}.indel >> $output/${sample}.${run_num}.INDEL.txt
            sed -i '1d' $output/${sample}.${run_num}.INDEL.txt
            for i in $(seq 2 ${#chrArray[@]})
            do
                    sed -i '1d;2d' $TempReports/$sample.chr${chrArray[$i]}.indel
                    cat $TempReports/$sample.chr${chrArray[$i]}.indel >> $output/${sample}.${run_num}.INDEL.txt
            done
    fi	
    echo `date`
fi	