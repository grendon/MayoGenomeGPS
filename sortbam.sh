#!/bin/sh

if [ $# != 7 ]
then
    echo "Usage: <input bam> <outputbam><temp dir><sorting order><# of reads in RAM<run info>"
else
    set -x
    echo `date`
    inbam=$1
    outbam=$2
    tmp_dir=$3
    order=$4
    reads=$5
    index=`echo $6 | tr "[A-Z]" "[a-z]"`
    run_info=$7
    
    tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
    java=$( cat $tool_info | grep -w '^JAVA' | cut -d '=' -f2)
    picard=$( cat $tool_info | grep -w '^PICARD' | cut -d '=' -f2 )
	script_path=$( cat $tool_info | grep -w '^WHOLEGENOME_PATH' | cut -d '=' -f2)
	samtools=$( cat $tool_info | grep -w '^SAMTOOLS' | cut -d '=' -f2 )	
    
    $java/java -Xmx6g -Xms512m \
    -jar $picard/SortSam.jar \
    INPUT=$inbam \
    OUTPUT=$outbam \
    MAX_RECORDS_IN_RAM=$reads \
    SO=$order \
    TMP_DIR=$tmp_dir \
	CREATE_INDEX=$index \
    VALIDATION_STRINGENCY=SILENT	
    file=`echo $outbam | sed -e 's/\(.*\)..../\1/'`
	mv $file.bai $file.bam.bai
    
    if [ ! -s $outbam ]
    then
        $script_path/errorlog.sh sortbam.sh $outbam ERROR empty
        exit 1;
    else
        $samtools/samtools view -H $outbam 1>$outbam.sort.header 2> $outbam.sort.log
		if [ `cat $outbam.sort.log | wc -l` -gt 0 ]
		then
			$script_path/errorlog.sh rmdup.sh $outbam ERROR "truncated or corrupted"
			exit 1;
		else
			rm $outbam.sort.log
		fi	
		rm $inbam $outbam.sort.header
        if [ $index == "true" ]
        then
            echo "index already created"
        else
			rm $file.bam.bai
		fi    
    fi
    echo `date`
fi
	