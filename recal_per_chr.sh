#!/bin/sh
## this scripts work per chr and accepts an array job paramter to extract the chr information
## creat a folder name temp in the output folder befor euisng this script
## GATK version using GenomeAnalysisTK-1.2-4-gd9ea764
if [ $# != 8 ]
then
    echo -e "Usage:\nIf user wants to do recalibration fist \n<input dir ':' sep><input bam ':' sep><outputdir><run_info><1 or 0 if bam is per chr><1 for recalibrate first ><sample ':' sep>\nelse\n<input dir><input bam><output dir><run_info> <1 or 0 if bam is per chr> < 0 for recal second><sample (a dummy sampel name i would say just type multi as sample>  ";
else	
    set -x
    echo `date`
    input=$1    
    bam=$2
    output=$3
    run_info=$4
    chopped=$5
    recal=$6
    samples=$7
    chr=$8

    tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
    samtools=$( cat $tool_info | grep -w '^SAMTOOLS' | cut -d '=' -f2)	
    ref=$( cat $tool_info | grep -w '^REF_GENOME' | cut -d '=' -f2)
    gatk=$( cat $tool_info | grep -w '^GATK' | cut -d '=' -f2)
    dbSNP=$( cat $tool_info | grep -w '^dbSNP_REF' | cut -d '=' -f2)
    Kgenome=$( cat $tool_info | grep -w '^KGENOME_REF' | cut -d '=' -f2)
    java=$( cat $tool_info | grep -w '^JAVA' | cut -d '=' -f2)
    picard=$( cat $tool_info | grep -w '^PICARD' | cut -d '=' -f2 ) 
    script_path=$( cat $tool_info | grep -w '^WHOLEGENOME_PATH' | cut -d '=' -f2 )
    out=$( cat $run_info | grep -w '^BASE_OUTPUT_DIR' | cut -d '=' -f2)
    PI=$( cat $run_info | grep -w '^PI' | cut -d '=' -f2)
    tool=$( cat $run_info | grep -w '^TYPE' | cut -d '=' -f2 | tr "[A-Z]" "[a-z]" )
    run_num=$( cat $run_info | grep -w '^OUTPUT_FOLDER' | cut -d '=' -f2)
    
    
    if [ $recal == 1 ]
    then
        inputDirs=$( echo $input | tr ":" "\n" )
        bamNames=$( echo $bam | tr ":" "\n" )
        sampleNames=$( echo $samples | tr ":" "\n" )
        i=1
        for inp in $inputDirs
        do
            inputArray[$i]=$inp
            let i=i+1
        done
        i=1
        
        i=1
        for sa in $sampleNames
        do
            sampleArray[$i]=$sa
            let i=i+1
        done
        if [ ${#inputArray[@]} != ${#bamArray[@]} -o ${#inputArray[@]} != ${#sampleArray[@]} ]
        then
            echo "ERROR : ':' sep parameters are not matching check the $run_info file";
            exit 1;
        else    
            for i in $(seq 1 ${#sampleArray[@]})
            do
                sample=${sampleArray[$i]}
                input=${inputArray[$i]}
                bam=${bamArray[$i]}
                ##extracting and checking the BAM for specific chromosome

                if [ ! -s $input/$bam ]
                then
                    echo "ERROR : recal_per_chr. File $input/$bam does not exist" 
                    exit 1
                fi
                $script_path/samplecheckBAM.sh $input $bam $output $run_info $sample $chopped $chr
            done
        fi
        input_bam=""
        for i in $(seq 1 ${#sampleArray[@]})
        do
            input_bam="${input_bam} -I $output/${sampleArray[$i]}.chr${chr}-sorted.bam"
        done
    else
        if [ ! -s $input/$bam ]
        then
            echo "ERROR : recal_per_chr. File $input/$bam does not exist"
            exit 1
        fi
        $script_path/samplecheckBAM.sh $input $bam $output $run_info $samples $chopped $chr
        input_bam="-I $output/$samples.chr${chr}-sorted.bam"
    fi	
            
    ## Recal metrics file creation
    $java/java -Xmx6g -Xms512m -jar $gatk/GenomeAnalysisTK.jar \
    -R $ref \
    -et NO_ET \
    --knownSites $dbSNP \
    --knownSites $Kgenome \
    $input_bam \
    -L chr${chr} \
    -T CountCovariates \
    -cov ReadGroupCovariate \
    -cov QualityScoreCovariate \
    -cov CycleCovariate \
    -cov DinucCovariate \
    -recalFile $output/chr${chr}.recal_data.csv 

    if [ ! -s $output/chr${chr}.recal_data.csv ]
    then
        echo "ERROR : recal_per_chr. File $output/chr${chr}.recal_data.csv not created"
        exit 1
    fi
    
    ## recailbartion
    echo `date`
    $java/java -Xmx6g -Xms512m -jar $gatk/GenomeAnalysisTK.jar \
    -R $ref \
    -et NO_ET \
    -L chr${chr} \
    $input_bam \
    -T TableRecalibration \
    --out $output/chr${chr}.recalibrated.bam \
    -recalFile $output/chr${chr}.recal_data.csv 

    if [ -s $output/chr${chr}.recalibrated.bam ]
    then
        mv $output/chr${chr}.recalibrated.bai $output/chr${chr}.recalibrated.bam.bai
        rm $input/$bam $input/$bam.bai
		if [ $recal == 0 ]
		then
			mv $output/chr${chr}.recalibrated.bam $output/chr${chr}.cleaned.bam
			mv $output/chr${chr}.recalibrated.bam.bai $output/chr${chr}.cleaned.bam.bai
			$samtools/samtools flagstat $output/chr${chr}.cleaned.bam > $output/chr$chr.flagstat
		fi		
    else
        echo "ERROR : recal_per_chr. File $output/chr${chr}.recalibrated.bam not created" 
        exit 1
    fi
    
    ## deleting internediate files
    if [ $recal == 1 ]
    then
        for i in $(seq 1 ${#sampleArray[@]})
        do
            rm $output/${bamArray[$i]}.$chr.bam
            rm $output/${bamArray[$i]}.$chr.bam.bai
            rm $output/${sampleArray[$i]}.chr${chr}.bam
            rm $output/${sampleArray[$i]}.chr${chr}.bam.bai
            rm $output/${sampleArray[$i]}.chr${chr}-sorted.bam
            rm $output/${sampleArray[$i]}.chr${chr}-sorted.bam.bai
            rm $output/${sampleArray[$i]}.chr${chr}-sorted.bam.bai
        done
    else
        rm $output/$bam.$chr.bam
        rm $output/$bam.$chr.bam.bai
        rm $output/$samples.chr${chr}.bam
        rm $output/$samples.chr${chr}.bam.bai
        rm $output/$samples.chr${chr}-sorted.bam
        rm $output/$samples.chr${chr}-sorted.bam.bai
        rm $output/$samples.chr${chr}-sorted.bam.bai
    fi
    rm $output/chr${chr}.recal_data.csv 		
    echo `date`	
fi
