#!/bin/bash
## script to get statistical numbers for each sample or pair

if [ $# != 4 ]
then
    echo -e "script to get statistical numbers for a sample/group\nUsage: </path/to/input dir> <sample> </path/to/run info></path/to/number folder>"
else 
    set -x
    echo `date`
    input_dir=$1
    sample=$2
    run_info=$3
    numbers=$4
    group=$sample
##############################################################		
    tool_info=$( cat $run_info | grep -w '^TOOL_INFO' | cut -d '=' -f2)
    sample_info=$( cat $run_info | grep -w '^SAMPLE_INFO' | cut -d '=' -f2)
    aligner=$( cat $run_info | grep -w '^ALIGNER' | cut -d '=' -f2)
    variant_type=$( cat $run_info | grep -w '^VARIANT_TYPE' | cut -d '=' -f2)
    markdup=$( cat $tool_info | grep -w '^MARKDUP' | cut -d '=' -f2| tr "[A-Z]" "[a-z]")
    chrs=$( cat $run_info | grep -w '^CHRINDEX' | cut -d '=' -f2 | tr ":" " ")
    caller=$( cat $run_info | grep -w '^SNV_CALLER' | cut -d '=' -f2)
    multi_sample=$( cat $run_info | grep -w '^MULTISAMPLE' | cut -d '=' -f2)  
    script_path=$( cat $tool_info | grep -w '^WORKFLOW_PATH' | cut -d '=' -f2 )
    tool=$( cat $run_info | grep -w '^TYPE' | cut -d '=' -f2| tr "[A-Z]" "[a-z]")
    analysis=$( cat $run_info | grep -w '^ANALYSIS' | cut -d '=' -f2| tr "[A-Z]" "[a-z]")
	somatic_calling=$( cat $tool_info | grep -w '^SOMATIC_CALLING' | cut -d '=' -f2 )
	genome=$( cat $run_info | grep -w '^GENOMEBUILD' | cut -d '=' -f2)
##############################################################		
##############################################################		
    if [ $multi_sample != "YES" ]
    then
        echo "Single sample"
		$script_path/dashboard.sh $sample $run_info Statistics started
		### get the alignment statistics
		if [[ $analysis != "annotation"  && $analysis != "variant"  && $analysis != "ontarget" ]] 
		then
			alignment=$input_dir/alignment/$sample	
			cd $alignment
			total_reads=0
			mapped_reads=0
			file=`find . -name '*.flagstat' | sed -e '/\.\//s///g' `
			for i in $file
			do
				re=`cat $i | grep -w 'total'| cut -d ' ' -f1`
				total_reads=`expr $re "+" $total_reads`
			done    
			echo -e "Total Reads" > $numbers/$sample.out
			echo $total_reads >> $numbers/$sample.out
			for i in $file
			do
				ma=` cat $i | grep -w 'mapped' | grep '%)$' | cut -d ' ' -f1`
				mapped_reads=`expr $ma "+" $mapped_reads`
			done    
			echo -e "Mapped Reads (${aligner}) " >> $numbers/$sample.out
			echo $mapped_reads >> $numbers/$sample.out
			percent_dup=0
			echo -e "Percent duplication" >> $numbers/$sample.out
			if [ $markdup == "yes" ]
			then
				## assuming the remove duplicate is done using PICARD
				percent_dup=`cat $sample.dup.metrics | awk '$0 !~ /#/' | grep -w "$genome" | cut -f8 | tail -1`
				echo $percent_dup >> $numbers/$sample.out
			else
				echo $percent_dup >> $numbers/$sample.out		
			fi
		fi
##############################################################		
	    ## statistics after realignment
        if [[ $analysis != "alignment" && $analysis != "annotation"  && $analysis != "ontarget" ]]
		then
            realign=$input_dir/realign/$sample
			cd $realign
            if [[ $analysis == "variant" ]]
			then
                total_reads=`cat $realign/*.flagstat | grep -w 'total' | cut -f1 | awk '{sum+=$1; print sum}' |tail -1`
                echo -e "Total Reads  " >> $numbers/$sample.out
                echo $total_reads >> $numbers/$sample.out
            fi	
			mapped_reads_realign=0
            mapped_reads_realign=`cat $realign/*.flagstat | grep -w 'mapped' | grep '%)$' | awk '{sum+=$1; print sum}' |tail -1`
            echo -e "Realigned Reads (GATK) " >> $numbers/$sample.out
            echo $mapped_reads_realign >> $numbers/$sample.out
			
            ### on target reads
            on_reads=0
            for chr in $chrs
            do
                    on=`cat $input_dir/OnTarget/$sample.chr$chr.bam.i.out | head -1`
                    on_reads=`expr $on_reads "+" $on`
            done
            echo -e "OnTarget Reads" >> $numbers/$sample.out
            echo $on_reads >> $numbers/$sample.out	
        fi
        if [[ $analysis != "alignment" ]]
		then
            variants=$input_dir/Reports_per_Sample
            ontarget=$input_dir/OnTarget
            ## get the column for the particular sample
            
            if [ $analysis != "annotation" ] 
			then
                ## RAW indels and SNVs
                raw_snvs=0
                raw_indels=0
                col=`cat $variants/$sample.variants.vcf | awk '$0 ~ /#/' | tail -1 | awk -v s=$sample -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == s) {print i} } }'`
                a=`cat $variants/$sample.variants.vcf | awk '$0 !~ /#/' | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^\./' | awk 'length($4) == 1 && length($5) == 1' | wc -l`
                b=`cat $variants/$sample.variants.vcf | awk '$0 !~ /#/' | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^\./' | awk 'length($4) > 1 || length($5) > 1' | wc -l`
                raw_indels=`expr $raw_indels "+" $b`
                raw_snvs=`expr $raw_snvs "+" $a`
					
                ## Filtered indels and SNVs
                filtered_snvs=0
                filtered_indels=0
                col=`cat $variants/$sample.variants.final.vcf | awk '$0 ~ /#/' | tail -1 | awk -v s=$sample -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == s) {print i} } }'`
                a=`cat $variants/$sample.variants.final.vcf | awk '$0 !~ /#/' | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^\./' | awk 'length($4) == 1 && length($5) == 1' | grep -c PASS`
                b=`cat $variants/$sample.variants.final.vcf | awk '$0 !~ /#/' | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^\./' | awk 'length($4) > 1 || length($5) > 1' | grep -c PASS`
                filtered_indels=`expr $filtered_indels "+" $b`
                filtered_snvs=`expr $filtered_snvs "+" $a`
			fi
            
			## Genomic indels and SNVs
			#### SNV in target region anf capture kit
			genomic_snvs=0
			capture_snvs=0
			genomic_indels=0
			capture_indels=0
			for chr in $chrs
			do
				if [ $variant_type == "BOTH" -o $variant_type == "SNV" ]
				then
					s=`cat $ontarget/$sample.variants.chr${chr}.SNV.final.i.c.vcf | awk '$0 !~ /^#/' |  awk '$10 !~ /^\.\/\./ && $10 !~ /^\./' |wc -l`
					genomic_snvs=`expr $genomic_snvs "+" $s`
					s_c=`cat $ontarget/$sample.variants.chr${chr}.SNV.final.i.c.vcf | awk '$0 !~ /^#/'  | awk '$10 !~ /^\.\/\./ && $10 !~ /^\./ '|grep -c 'CAPTURE=1'`
					capture_snvs=`expr $capture_snvs "+" $s_c`
				fi
				if [ $variant_type == "BOTH" -o $variant_type == "INDEL" ]
				then
					i=`cat $ontarget/$sample.variants.chr${chr}.INDEL.final.i.c.vcf | awk '$0 !~ /^#/' |  awk '$10 !~ /^\.\/\./ && $10 !~ /^\./ '|wc -l`
					i_c=`cat $ontarget/$sample.variants.chr${chr}.INDEL.final.i.c.vcf | awk '$0 !~ /^#/'  | awk '$10 !~ /^\.\/\./ && $10 !~ /^\./'|grep -c 'CAPTURE=1'`
					capture_indels=`expr $capture_indels "+" $i_c`
					genomic_indels=`expr $genomic_indels "+" $i`
				fi
			done
            
			if [ $variant_type == "BOTH" -o $variant_type == "SNV" ]
			then
				if [ $analysis != "annotation" ] 
				then
					echo "RAW snvs ($caller)" >> $numbers/$sample.out
					echo $raw_snvs >> $numbers/$sample.out
					echo "FILTERED snvs ($caller)" >> $numbers/$sample.out
					echo $filtered_snvs >> $numbers/$sample.out
				fi
				echo "CODING snvs ($caller)" >> $numbers/$sample.out
				echo $genomic_snvs >> $numbers/$sample.out
			
				if [ $analysis != "annotation" ]
				then
					if [ $tool == "exome" ]
					then	
						echo "CaptureKit snvs ($caller)" >> $numbers/$sample.out
						echo $capture_snvs >> $numbers/$sample.out	
					fi
				fi
				# KNOWN variants (look at the reports for each sample, filtered report from GATK and SNPEFF combinations
				file=$variants/$sample.SNV.final.xls
				dbsnp=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i ~ /dbSNP/) {print i} } }'| head -1`
				ref=`cat $file | head -2 | tail -1 |awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == "Ref") {print i} } }'`
				alt=`cat $file | head -2 | tail -1 |awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == "Alt") {print i} } }'`
				class=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == "Effect") {print i} } }'`
				
				echo -e "Total Known SNVs" >> $numbers/$sample.out
				cat $file | awk 'NR>2' | awk -v num=$dbsnp '$num ~ /^rs/' | wc -l >> $numbers/$sample.out
				echo -e "KNOWN Transition To Transversion Ratio" >> $numbers/$sample.out
				cat $file | awk 'NR>2' | awk -v num=$dbsnp '$num ~ /^rs/' > $file.known
				tt=`perl $script_path/transition.transversion.persample.pl $file.known $ref $alt`
				if [ ${#tt} -gt 0 ]
				then
					echo $tt >> $numbers/$sample.out
				else
					tt=0
					echo $tt >> $numbers/$sample.out
				fi    
				for snv in SPLICE_SITE_ACCEPTOR SPLICE_SITE_DONOR START_LOST STOP_GAINED STOP_LOST RARE_AMINO_ACID NON_SYNONYMOUS_CODING SYNONYMOUS_START NON_SYNONYMOUS_START START_GAINED SYNONYMOUS_CODING SYNONYMOUS_STOP NON_SYNONYMOUS_STOP UTR_5_PRIME UTR_3_PRIME
				do
					echo -e "KNOWN $snv" >> $numbers/$sample.out 
					cat $file.known | awk -F'\t' -v comp=$snv -v num=$class '$num == comp' | wc -l >> $numbers/$sample.out  
				done	
				rm $file.known
				
				echo -e "Total Novel SNVs" >> $numbers/$sample.out
				cat $file | awk 'NR>2' | awk -v num=$dbsnp '$num !~ /^rs/' | wc -l >> $numbers/$sample.out
				echo -e "NOVEL Transition To Transversion Ratio" >> $numbers/$sample.out
				cat $file | awk 'NR>2' | awk -v num=$dbsnp '$num !~ /^rs/' > $file.novel
				tt=`perl $script_path/transition.transversion.persample.pl $file.novel $ref $alt`
				if [ ${#tt} -gt 0 ]
				then
					echo $tt >> $numbers/$sample.out
				else
					tt=0
					echo $tt >> $numbers/$sample.out
				fi 
				
				for snv in SPLICE_SITE_ACCEPTOR SPLICE_SITE_DONOR START_LOST STOP_GAINED STOP_LOST RARE_AMINO_ACID NON_SYNONYMOUS_CODING SYNONYMOUS_START NON_SYNONYMOUS_START START_GAINED SYNONYMOUS_CODING SYNONYMOUS_STOP NON_SYNONYMOUS_STOP UTR_5_PRIME UTR_3_PRIME
				do
					echo -e "NOVEL $snv" >> $numbers/$sample.out 
					cat $file.novel | awk -F'\t' -v comp=$snv -v num=$class '$num == comp' | wc -l >> $numbers/$sample.out  
				done
				rm $file.novel
			fi
			
			if [ $variant_type == "BOTH" -o $variant_type == "INDEL" ]
			then
				if [ $analysis != "annotation" ] 
				then
					echo "TOTAL indels ($caller)" >> $numbers/$sample.out
					echo $raw_indels >> $numbers/$sample.out
					echo "FILTERED indels ($caller)" >> $numbers/$sample.out
					echo $filtered_indels >> $numbers/$sample.out
				fi
				echo "CODING indels ($caller)" >> $numbers/$sample.out
				echo $genomic_indels >> $numbers/$sample.out
				if [ $analysis != "annotation" ]
				then
					if [ $tool == "exome" ]
					then
						echo "Capture indels ($caller)" >> $numbers/$sample.out
						echo $capture_indels >> $numbers/$sample.out
					fi
				fi
				## Annotated INDELs
				file=$variants/$sample.INDEL.final.xls
				class=`cat $file | awk 'NR==2' | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i ~ /Effect/) {print i} } }'`
				for indel in EXON_DELETED FRAME_SHIFT CODON_CHANGE UTR_5_DELETED UTR_3_DELETED CODON_INSERTION CODON_CHANGE_PLUS_CODON_INSERTION CODON_DELETION CODON_CHANGE_PLUS_CODON_DELETION SPLICE_SITE_ACCEPTOR SPLICE_SITE_DONOR UTR_5_PRIME UTR_3_PRIME		
				do
					echo -e "$indel" >> $numbers/$sample.out 
					cat $file | awk -F'\t' -v comp=$indel -v num=$class '$num == comp' | wc -l >> $numbers/$sample.out 
				done	
			fi
          
			##############################################################		
			if [[ $tool == "whole_genome" && $analysis != "annotation" ]]
			then
				## cnvs
				raw_cnvs=0
				raw_del=0
				raw_dup=0
				genomic_cnvs=0
				genomic_deletions=0
				genomic_duplications=0
				cnv=$input_dir/Reports_per_Sample/SV
				raw_del=`cat $cnv/$sample.cnv.vcf | awk '$0 !~ /#/' | grep -c DEL`
				raw_dup=`cat $cnv/$sample.cnv.vcf | awk '$0 !~ /#/' | grep -c DUP`
				raw_cnvs=`expr $raw_del "+" $raw_dup`
				genomic_deletions=`cat $cnv/$sample.cnv.final.vcf | awk '$0 !~ /#/' | grep -c DEL`
				genomic_duplications=`cat $cnv/$sample.cnv.final.vcf | awk '$0 !~ /#/' | grep -c DUP`
				genomic_cnvs=`expr $genomic_deletions "+" $genomic_duplications`
				echo "RAW cnvs" >> $numbers/$sample.out
				echo $raw_cnvs >> $numbers/$sample.out
				echo "CODING cnvs" >> $numbers/$sample.out
				echo $genomic_cnvs >> $numbers/$sample.out
				echo "CODING deletions" >> $numbers/$sample.out
				echo $genomic_deletions >> $numbers/$sample.out
				echo "CODING duplications" >> $numbers/$sample.out
				echo $genomic_duplications >> $numbers/$sample.out
            
##############################################################		
				## structural variants 
				struct=$input_dir/Reports_per_Sample/ANNOT
				break=$input_dir/Reports_per_Sample/ANNOT
				
				num_break=0;
				num_crest=0;
				num_sv=0;
				genomic_sv=0;
				ITX=0;
				INV=0;
				DEL=0;
				INS=0;
				CTX=0;
				num_break=`cat $input_dir/Reports_per_Sample/SV/$sample.break.vcf | awk '$0 !~ /#/' | wc -l`
				num_crest=`cat $input_dir/Reports_per_Sample/SV/$sample.final.crest.vcf | awk '$0 !~ /#/'|wc -l`
				num_sv=`expr $num_break "+" $num_crest`     
				genomic_sv=`cat $struct/$sample.SV.annotated.txt | wc -l`
				if [ $genomic_sv -gt 0 ]
				then
					genomic_sv=`expr $genomic_sv "-" 1`
				fi
				ITX=`cat $struct/$sample.SV.annotated.txt | grep ITX | wc -l`
				INV=`cat $struct/$sample.SV.annotated.txt | grep INV | wc -l`
				DEL=`cat $struct/$sample.SV.annotated.txt | grep DEL | wc -l`
				INS=`cat $struct/$sample.SV.annotated.txt | grep INS | wc -l`
				CTX=`cat $struct/$sample.SV.annotated.txt | grep CTX | wc -l`
				
				echo "TOTAL SVs" >> $numbers/$sample.out
				echo $num_sv >> $numbers/$sample.out
				echo "GENOMIC SVs" >> $numbers/$sample.out
				echo $genomic_sv >> $numbers/$sample.out
				echo "ITX" >> $numbers/$sample.out
				echo $ITX >> $numbers/$sample.out
				echo "INV" >> $numbers/$sample.out
				echo $INV >> $numbers/$sample.out
				echo "DEL" >> $numbers/$sample.out
				echo $DEL >> $numbers/$sample.out
				echo "INS" >> $numbers/$sample.out
				echo $INS >> $numbers/$sample.out
				echo "CTX" >> $numbers/$sample.out
				echo $CTX >> $numbers/$sample.out
			fi	
		fi
		$script_path/dashboard.sh $sample $run_info Statistics complete
	else
	    echo "Multi sample"
        for sample in `cat $sample_info | grep -w "^$group" | cut -d '=' -f2`
        do
            $script_path/dashboard.sh $sample $run_info Statistics started
			#### alignment stats
            if [ $analysis != "variant" ]
            then
            alignment=$input_dir/alignment/$sample	
            cd $alignment
            total_reads=0
            mapped_reads=0
            file=`find . -name '*.flagstat' | sed -e '/\.\//s///g' `
            for i in $file
            do
                re=`cat $i | grep -w 'total'| cut -d ' ' -f1`
                total_reads=`expr $re "+" $total_reads`
            done    
            echo -e "Total Reads" > $numbers/$group.$sample.out
            echo $total_reads >> $numbers/$group.$sample.out
            for i in $file
            do
                ma=` cat $i | grep -w 'mapped' | grep '%)$' | cut -d ' ' -f1`
                mapped_reads=`expr $ma "+" $mapped_reads`
            done    
            echo -e "Mapped Reads (${aligner}) " >> $numbers/$group.$sample.out
            echo $mapped_reads >> $numbers/$group.$sample.out
            percent_dup=0
            echo -e "Percent duplication" >> $numbers/$group.$sample.out
            if [ $markdup == "yes" ]
            then
                ## assuming the remove duplicate is done using PICARD
                file=`find . -name '*.dup.metrics' | sed -e '/\.\//s///g' `
                for i in $file
                do
                    cat $i | awk '$0 !~ /#/' | grep -w "$genome" | cut -f8 | tail -1 >> $numbers/$group.$sample.dup.out
                done
                percent_dup=`cat $numbers/$group.$sample.dup.out | awk '{sum+=$1; print sum}' | tail -1` 
                rm $numbers/$group.$sample.dup.out 
                echo $percent_dup >> $numbers/$group.$sample.out
            else
                echo $percent_dup >> $numbers/$group.$sample.out	
            fi
            fi
            ### on target reads
            on_reads=0
            for chr in $chrs
            do
				on=`cat $input_dir/OnTarget/$group.$sample.chr$chr.bam.i.out | head -1`
				on_reads=`expr $on_reads "+" $on`
            done
            echo -e "OnTarget Reads" >> $numbers/$group.$sample.out
            echo $on_reads >> $numbers/$group.$sample.out
	     		
			##### variants
            variants=$input_dir/Reports_per_Sample
            ontarget=$input_dir/OnTarget

            ## RAW indels and SNVs
            raw_snvs=0
            raw_indels=0
            col=`cat $variants/$group.variants.vcf | awk '$0 ~ /^#/' | tail -1 | awk -v s=$sample -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == s) {print i} } }'`
            a=`cat $variants/$group.variants.vcf | awk '$0 !~ /^#/' | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^0\/0/ && $num !~ /^\./' | awk 'length($4) == 1 && length($5) == 1' | wc -l`
            b=`cat $variants/$group.variants.vcf | awk '$0 !~ /^#/' | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^0\/0/ && $num !~ /^\./' | awk 'length($4) > 1 || length($5) > 1' | wc -l`
            raw_indels=`expr $raw_indels "+" $b`
            raw_snvs=`expr $raw_snvs "+" $a`


            ## Filtered indels and SNVs
            filtered_snvs=0
            filtered_indels=0
            col=`cat $variants/$group.variants.final.vcf | awk '$0 ~ /^#/' | tail -1 | awk -v s=$sample -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == s) {print i} } }'`
            a=`cat $variants/$group.variants.final.vcf | awk '$0 !~ /^#/' | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^0\/0/' && $num !~ /^\./' | awk 'length($4) == 1 && length($5) == 1' | grep -c PASS`
            b=`cat $variants/$group.variants.final.vcf | awk '$0 !~ /^#/' | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^0\/0/' && $num !~ /^\./' | awk 'length($4) > 1 || length($5) > 1' | grep -c PASS`
            filtered_indels=`expr $filtered_indels "+" $b`
            filtered_snvs=`expr $filtered_snvs "+" $a`


            ## Genomic indels and SNVs
            #### SNV in target region anf capture kit
            genomic_snvs=0
            genomic_indels=0
			capture_indels=0
			capture_snvs=0
            
            for chr in $chrs
            do
				col=`cat $ontarget/$group.variants.chr${chr}.SNV.final.i.c.vcf  | awk '$0 ~ /^#/' | tail -1 | awk -v s=$sample -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == s) {print i} } }'`
                s=`cat $ontarget/$group.variants.chr${chr}.SNV.final.i.c.vcf | awk '$0 !~ /^#/' | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^0\/0/ && $num !~ /^\./' | wc -l`
				genomic_snvs=`expr $genomic_snvs "+" $s`
				s_c=`cat $ontarget/$group.variants.chr${chr}.SNV.final.i.c.vcf | awk '$0 !~ /^#/'  | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^0\/0/ && $num !~ /^\./'| grep -c 'CAPTURE=1'`
				capture_snvs=`expr $capture_snvs "+" $s_c`
                col=`cat $ontarget/$group.variants.chr${chr}.INDEL.final.i.c.vcf  | awk '$0 ~ /^#/' | tail -1 | awk -v s=$sample -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == s) {print i} } }'`
				i=`cat $ontarget/$group.variants.chr${chr}.INDEL.final.i.c.vcf | awk '$0 !~ /^#/' |  awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^0\/0/ && $num !~ /^\./' | wc -l`
				i_c=`cat $ontarget/$group.variants.chr${chr}.INDEL.final.i.c.vcf | awk '$0 !~ /^#/'  | awk -v num=$col '$num !~ /^\.\/\./ && $num !~ /^0\/0/ && $num !~ /^\./' | grep -c 'CAPTURE=1'`
				capture_indels=`expr $capture_indels "+" $i_c`
				genomic_indels=`expr $genomic_indels "+" $i`
            done

            echo "RAW snvs ($caller)" >> $numbers/$group.$sample.out
            echo $raw_snvs >> $numbers/$group.$sample.out
            echo "FILTERED snvs ($caller)" >> $numbers/$group.$sample.out
            echo $filtered_snvs >>$numbers/$group.$sample.out
            echo "CODING snvs ($caller)" >> $numbers/$group.$sample.out
            echo $genomic_snvs >> $numbers/$group.$sample.out
            if [ $tool == "exome" ]
			then	
				echo "CaptureKit snvs ($caller)" >> $numbers/$group.$sample.out
				echo $capture_snvs >> $numbers/$group.$sample.out
			fi
				
            ### annotation 
            file=$variants/$group.SNV.final.xls
			dbsnp=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i ~ /dbSNP/) {print i} } }'| head -1`
			ref=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == "Ref") {print i} } }'`
			alt=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == "Alt") {print i} } }'`
			class=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == "Effect") {print i} } }'`
			col=`cat $file | head -1 | awk -v num=$sample -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == num) {print i} } }'`
			echo -e "Total Known SNVs" >> $numbers/$group.$sample.out
			cat $file | awk 'NR>2' | awk -v num=$dbsnp -v col=$col -v ref=$ref '$col !~ /n\/a/ && $num ~ /^rs/ && $col !~ $ref$ref' | wc -l >> $numbers/$group.$sample.out
			echo -e "KNOWN Transition To Transversion Ratio" >> $numbers/$group.$sample.out
			cat $file | awk 'NR>2' | awk -v num=$dbsnp -v col=$col -v ref=$ref '$col !~ /n\/a/ && $num ~ /^rs/ && $col !~ $ref$ref' > $file.known
			tt=`perl $script_path/transition.transversion.persample.pl $file.known $ref $alt`
			if [ ${#tt} -gt 0 ]
			then
				echo $tt >> $numbers/$group.$sample.out
			else
				tt=0
				echo $tt >> $numbers/$group.$sample.out
			fi 
			for snv in SPLICE_SITE_ACCEPTOR SPLICE_SITE_DONOR START_LOST STOP_GAINED STOP_LOST RARE_AMINO_ACID NON_SYNONYMOUS_CODING SYNONYMOUS_START NON_SYNONYMOUS_START START_GAINED SYNONYMOUS_CODING SYNONYMOUS_STOP NON_SYNONYMOUS_STOP UTR_5_PRIME UTR_3_PRIME
			do
				echo -e "KNOWN $snv" >> $numbers/$group.$sample.out
				cat $file.known | awk -F'\t' -v comp=$snv -v col=$col -v ref=$ref -v num=$class '$num == comp && $col !~ $ref$ref '  | wc -l >> $numbers/$group.$sample.out
			done	
			rm $file.known
			
			echo -e "Total Novel SNVs" >> $numbers/$group.$sample.out
			cat $file | awk 'NR>2' | awk -v num=$dbsnp -v col=$col -v ref=$ref '$col !~ /n\/a/ && $num !~ /^rs/ && $col !~ $ref$ref' | wc -l >> $numbers/$group.$sample.out
			echo -e "NOVEL Transition To Transversion Ratio" >> $numbers/$group.$sample.out
			cat $file | awk 'NR>2' | awk -v num=$dbsnp -v col=$col -v ref=$ref '$col !~ /n\/a/ && $num !~ /^rs/ && $col !~ $ref$ref' > $file.novel
			tt=`perl $script_path/transition.transversion.persample.pl $file.novel $ref $alt`
			if [ ${#tt} -gt 0 ]
			then
				echo $tt >> $numbers/$group.$sample.out
			else
				tt=0
				echo $tt >> $numbers/$group.$sample.out
			fi 
			for snv in SPLICE_SITE_ACCEPTOR SPLICE_SITE_DONOR START_LOST STOP_GAINED STOP_LOST RARE_AMINO_ACID NON_SYNONYMOUS_CODING SYNONYMOUS_START NON_SYNONYMOUS_START START_GAINED SYNONYMOUS_CODING SYNONYMOUS_STOP NON_SYNONYMOUS_STOP UTR_5_PRIME UTR_3_PRIME
			do
				echo -e "NOVEL $snv" >> $numbers/$group.$sample.out
				cat $file.novel | awk -F'\t' -v ref=$ref -v col=$col -v comp=$snv -v num=$class '$num == comp && $col !~ $ref$ref' | wc -l >> $numbers/$group.$sample.out  
			done
			rm $file.novel
			## INDELs
			echo "TOTAL indels ($caller)" >> $numbers/$group.$sample.out
			echo $raw_indels >> $numbers/$group.$sample.out
			echo "FILTERED indels ($caller)" >> $numbers/$group.$sample.out
			echo $filtered_indels >> $numbers/$group.$sample.out
			echo "CODING indels ($caller)" >> $numbers/$group.$sample.out
			echo $genomic_indels >> $numbers/$group.$sample.out
			if [ $tool == "exome" ]
			then
				echo "Capture indels ($caller)" >> $numbers/$group.$sample.out
				echo $capture_indels >> $numbers/$group.$sample.out
			fi
			## Annotated INDELs
			file=$variants/$group.INDEL.final.xls
			class=`cat $file | head -2 | tail -1  | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i ~ /Effect/) {print i} } }'`
			col=`cat $file | head -1 | awk -v num=$sample -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == num) {print i} } }'`
            for indel in EXON_DELETED FRAME_SHIFT CODON_CHANGE UTR_5_DELETED UTR_3_DELETED CODON_INSERTION CODON_CHANGE_PLUS_CODON_INSERTION CODON_DELETION CODON_CHANGE_PLUS_CODON_DELETION SPLICE_SITE_ACCEPTOR SPLICE_SITE_DONOR UTR_5_PRIME UTR_3_PRIME		
			do
				echo -e "$indel" >> $numbers/$group.$sample.out 
				cat $file | awk -F'\t' -v comp=$indel -v num=$class -v ref=$ref -v col=$col '$col !~ /n\/a/ && $num == comp && $col !~ $ref$ref'  | wc -l >> $numbers/$group.$sample.out 
			done	
			$script_path/dashboard.sh $sample $run_info Statistics complete
		done
		if [ $somatic_calling == "YES" ]
		then
			### somatic calls
			sample_info=$( cat $run_info | grep -w '^SAMPLE_INFO' | cut -d '=' -f2)
			samples=$( cat $sample_info | grep -w "^$group" | cut -d '=' -f2 )
			let num_tumor=`echo $samples|tr " " "\n"|wc -l`-1
			tumor_list=`echo $samples | tr " " "\n" | tail -$num_tumor`
			for tumor in $tumor_list    
			do
				realignment=$input_dir/realign/$group	
				total_reads=0
				mapped_reads=0
				for chr in $chrs
				do
					re=`cat $realignment/chr$chr.flagstat | grep -w 'total'| cut -d ' ' -f1`
					total_reads=`expr $re "+" $total_reads`
				done    
				echo -e "Combined Total Reads After alignment" > $numbers/TUMOR.$group.$tumor.out
				echo $total_reads >> $numbers/TUMOR.$group.$tumor.out
				for chr in $chrs
				do
					ma=` cat $realignment/chr$chr.flagstat | grep -w 'mapped' | grep '%)$' | cut -d ' ' -f1`
					mapped_reads=`expr $ma "+" $mapped_reads`
				done    
				echo -e "Mapped Reads (GATK) " >> $numbers/TUMOR.$group.$tumor.out
				echo $mapped_reads >> $numbers/TUMOR.$group.$tumor.out
				##### variants
				variants=$input_dir/Reports_per_Sample
				ontarget=$input_dir/OnTarget

				## RAW indels and SNVs
				raw_snvs=0
				raw_indels=0
				col=`cat $variants/$group.somatic.variants.vcf | awk '$0 ~ /^#/' | tail -1 | awk -v s=$tumor -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == s) {print i} } }'`
				a=`cat $variants/$group.somatic.variants.vcf | awk '$0 !~ /^#/' | awk -v num=$col '$num !~ /^0\/0/ && $num !~ /^\.\/\./ && $num !~ /^\./' | awk 'length($4) == 1 && length($5) == 1' | wc -l `
				b=`cat $variants/$group.somatic.variants.vcf | awk '$0 !~ /^#/' | awk -v num=$col '$num !~ /^0\/0/ && $num !~ /^\.\/\./ && $num !~ /^\./' | awk 'length($4) > 1 || length($5) > 1' | wc -l`
				raw_indels=`expr $raw_indels "+" $b`
				raw_snvs=`expr $raw_snvs "+" $a`


				## Filtered indels and SNVs
				filtered_snvs=0
				filtered_indels=0
				col=`cat $variants/$group.somatic.variants.final.vcf | awk '$0 ~ /^#/' | tail -1 | awk -v s=$tumor -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == s) {print i} } }'`
				a=`cat $variants/$group.somatic.variants.final.vcf | awk '$0 !~ /^#/' | awk -v num=$col '$num !~ /^0\/0/ && $num !~ /^\.\/\./ && $num !~ /^\./' | awk 'length($4) == 1 && length($5) == 1' | grep -c PASS`
				b=`cat $variants/$group.somatic.variants.final.vcf | awk '$0 !~ /^#/' | awk -v num=$col '$num !~ /^0\/0/ && $num !~ /^\.\/\./ && $num !~ /^\./' | awk 'length($4) > 1 || length($5) > 1' | grep -c PASS `
				filtered_indels=`expr $filtered_indels "+" $b`
				filtered_snvs=`expr $filtered_snvs "+" $a`


				## Genomic indels and SNVs
				#### SNV in target region anf capture kit
				genomic_snvs=0
				capture_snvs=0
				genomic_indels=0
				capture_indels=0
				for chr in $chrs
				do
					col=`cat $ontarget/TUMOR.$group.variants.chr${chr}.SNV.final.i.c.vcf| awk '$0 ~ /^#/' | tail -1 | awk -v s=$tumor -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == s) {print i} } }'`
					s=`cat $ontarget/TUMOR.$group.variants.chr${chr}.SNV.final.i.c.vcf | awk '$0 !~ /^#/' |  awk -v num=$col '$num !~ /^0\/0/ && $num !~ /^\.\/\./ && $num !~ /^\./' | wc -l`
					genomic_snvs=`expr $genomic_snvs "+" $s`
					s_c=`cat $ontarget/TUMOR.$group.variants.chr${chr}.SNV.final.i.c.vcf | awk '$0 !~ /^#/'  | awk -v num=$col '$num !~ /^0\/0/ && $num !~ /^\.\/\./ && $num !~ /^\./' |  grep -c 'CAPTURE=1'`
					capture_snvs=`expr $capture_snvs "+" $s_c`
					col=`cat $ontarget/TUMOR.$group.variants.chr${chr}.INDEL.final.i.c.vcf| awk '$0 ~ /^#/' | tail -1 | awk -v s=$tumor -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == s) {print i} } }'`
					i=`cat $ontarget/TUMOR.$group.variants.chr${chr}.INDEL.final.i.c.vcf | awk '$0 !~ /^#/' |  awk -v num=$col '$num !~ /^0\/0/ && $num !~ /^\.\/\./ && $num !~ /^\./ ' | wc -l`
					i_c=`cat $ontarget/TUMOR.$group.variants.chr${chr}.INDEL.final.i.c.vcf | awk '$0 !~ /^#/'  | awk -v num=$col '$num !~ /^0\/0/ && $num !~ /^\.\/\./ && $num !~ /^\./ ' |  grep -c 'CAPTURE=1'`
					capture_indels=`expr $capture_indels "+" $i_c`
					genomic_indels=`expr $genomic_indels "+" $i`
				done

				echo "RAW snvs ($caller)" >> $numbers/TUMOR.$group.$tumor.out
				echo $raw_snvs >> $numbers/TUMOR.$group.$tumor.out
				echo "FILTERED snvs ($caller)" >> $numbers/TUMOR.$group.$tumor.out
				echo $filtered_snvs >> $numbers/TUMOR.$group.$tumor.out
				echo "CODING snvs ($caller)" >> $numbers/TUMOR.$group.$tumor.out
				echo $genomic_snvs >> $numbers/TUMOR.$group.$tumor.out
				if [ $tool == "exome" ]
				then	
					echo "CaptureKit snvs ($caller)" >> $numbers/TUMOR.$group.$tumor.out
					echo $capture_snvs >> $numbers/TUMOR.$group.$tumor.out
				fi
				
				
				file=$variants/TUMOR.$group.SNV.final.xls
				dbsnp=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i ~ /dbSNP/) {print i} } }'| head -1`
				ref=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == "Ref") {print i} } }'`
				alt=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == "Alt") {print i} } }'`
				class=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == "Effect") {print i} } }'`
				col=`cat $file | head -1 | awk -v num=$tumor -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == num) {print i} } }'`
				echo -e "Total Known SNVs" >> $numbers/TUMOR.$group.$tumor.out
				cat $file | awk 'NR>2' | awk -v num=$dbsnp -v col=$col -v ref=$ref '$col !~ /n\/a/ && $num ~ /^rs/ && $col !~ $ref$ref' | wc -l >> $numbers/TUMOR.$group.$tumor.out
				echo -e "KNOWN Transition To Transversion Ratio" >> $numbers/TUMOR.$group.$tumor.out
				cat $file | awk -v num=$dbsnp -v col=$col -v ref=$ref '$col !~ /n\/a/ && $num ~ /^rs/ && $col !~ $ref$ref' > $file.known
				tt=`perl $script_path/transition.transversion.persample.pl $file.known $ref $alt`
				if [ ${#tt} -gt 0 ]
				then
					echo $tt >> $numbers/TUMOR.$group.$tumor.out
				else
					tt=0
					echo $tt >> $numbers/TUMOR.$group.$tumor.out
				fi 
				for snv in SPLICE_SITE_ACCEPTOR SPLICE_SITE_DONOR START_LOST STOP_GAINED STOP_LOST RARE_AMINO_ACID NON_SYNONYMOUS_CODING SYNONYMOUS_START NON_SYNONYMOUS_START START_GAINED SYNONYMOUS_CODING SYNONYMOUS_STOP NON_SYNONYMOUS_STOP UTR_5_PRIME UTR_3_PRIME
				do
					echo -e "KNOWN $snv" >> $numbers/TUMOR.$group.$tumor.out
					cat $file.known | awk -F'\t' -v col=$col -v comp=$snv -v ref=$ref -v num=$class '$num == comp && $col !~ $ref$ref'  | wc -l >> $numbers/TUMOR.$group.$tumor.out
				done	
				rm $file.known
				
				echo -e "Total Novel SNVs" >> $numbers/TUMOR.$group.$tumor.out
				cat $file | awk 'NR>2' | awk -v num=$dbsnp -v ref=$ref -v col=$col '$col !~ /n\/a/ && $num !~ /^rs/ && $col !~ $ref$ref' | wc -l >> $numbers/TUMOR.$group.$tumor.out
				echo -e "NOVEL Transition To Transversion Ratio" >> $numbers/TUMOR.$group.$tumor.out
				cat $file | awk 'NR>2' | awk -v num=$dbsnp -v ref=$ref -v col=$col '$col !~ /n\/a/ && $num !~ /^rs/ && $col !~ $ref$ref' > $file.novel
				tt=`perl $script_path/transition.transversion.persample.pl $file.novel $ref $alt`
				if [ ${#tt} -gt 0 ]
				then
					echo $tt >> $numbers/TUMOR.$group.$tumor.out
				else
					tt=0
					echo $tt >> $numbers/TUMOR.$group.$tumor.out
				fi 
				for snv in SPLICE_SITE_ACCEPTOR SPLICE_SITE_DONOR START_LOST STOP_GAINED STOP_LOST RARE_AMINO_ACID NON_SYNONYMOUS_CODING SYNONYMOUS_START NON_SYNONYMOUS_START START_GAINED SYNONYMOUS_CODING SYNONYMOUS_STOP NON_SYNONYMOUS_STOP UTR_5_PRIME UTR_3_PRIME
				do
					echo -e "NOVEL $snv" >> $numbers/TUMOR.$group.$tumor.out
					cat $file.novel | awk -F'\t' -v col=$col -v ref=$ref -v comp=$snv -v num=$class '$num == comp && $col !~ $ref$ref' | wc -l >> $numbers/TUMOR.$group.$tumor.out 
				done
				rm $file.novel
				## INDELs
				echo "TOTAL indels ($caller)" >> $numbers/TUMOR.$group.$tumor.out
				echo $raw_indels >> $numbers/TUMOR.$group.$tumor.out
				echo "FILTERED indels ($caller)" >> $numbers/TUMOR.$group.$tumor.out
				echo $filtered_indels >> $numbers/TUMOR.$group.$tumor.out
				echo "CODING indels ($caller)" >> $numbers/TUMOR.$group.$tumor.out
				echo $genomic_indels >> $numbers/TUMOR.$group.$tumor.out
				if [ $tool == "exome" ]
				then
					echo "Capture indels ($caller)" >> $numbers/TUMOR.$group.$tumor.out
					echo $capture_indels >> $numbers/TUMOR.$group.$tumor.out
				fi
				## Annotated INDELs
				file=$variants/TUMOR.$group.INDEL.final.xls
				col=`cat $file | head -1 | awk -v num=$tumor -F '\t' '{ for(i=1;i<=NF;i++){ if ($i == num) {print i} } }'`
				class=`cat $file | head -2 | tail -1 | awk -F '\t' '{ for(i=1;i<=NF;i++){ if ($i ~ /Effect/) {print i} } }'`
				for indel in EXON_DELETED FRAME_SHIFT CODON_CHANGE UTR_5_DELETED UTR_3_DELETED CODON_INSERTION CODON_CHANGE_PLUS_CODON_INSERTION CODON_DELETION CODON_CHANGE_PLUS_CODON_DELETION SPLICE_SITE_ACCEPTOR SPLICE_SITE_DONOR UTR_5_PRIME UTR_3_PRIME	
				do
					echo -e "$indel" >> $numbers/TUMOR.$group.$tumor.out
					cat $file | awk -F'\t' -v comp=$indel -v ref=$ref -v num=$class -v col=$col '$col !~ /n\/a/ && $num == comp && $col !~ $ref$ref'  | wc -l >> $numbers/TUMOR.$group.$tumor.out
				done	
				if [ $tool == "whole_genome" ]
				then
					raw_cnvs=0
					raw_del=0
					raw_dup=0
					genomic_cnvs=0
					genomic_deletions=0
					genomic_duplications=0
					cnv=$input_dir/Reports_per_Sample/SV
					raw_del=`cat $cnv/$group.$tumor.cnv.vcf | awk '$0 !~ /#/' | grep -c DEL`
					raw_dup=`cat $cnv/$group.$tumor.cnv.vcf | awk '$0 !~ /#/' | grep -c DUP`
					raw_cnvs=`expr $raw_del "+" $raw_dup`
					genomic_deletions=`cat $cnv/$group.$tumor.cnv.final.vcf | awk '$0 !~ /#/' | grep -c DEL`
					genomic_duplications=`cat $cnv/$group.$tumor.cnv.final.vcf | awk '$0 !~ /#/' | grep -c DUP`
					genomic_cnvs=`expr $genomic_deletions "+" $genomic_duplications`
					echo "RAW cnvs" >> $numbers/TUMOR.$group.$tumor.out
					echo $raw_cnvs >> $numbers/TUMOR.$group.$tumor.out
					echo "CODING cnvs" >>$numbers/TUMOR.$group.$tumor.out
					echo $genomic_cnvs >> $numbers/TUMOR.$group.$tumor.out
					echo "CODING deletions" >> $numbers/TUMOR.$group.$tumor.out
					echo $genomic_deletions >> $numbers/TUMOR.$group.$tumor.out
					echo "CODING duplications" >> $numbers/TUMOR.$group.$tumor.out
					echo $genomic_duplications >> $numbers/TUMOR.$group.$tumor.out
					#### SV by crest and break dancer
					struct=$input_dir/Reports_per_Sample/ANNOT
					break=$input_dir/Reports_per_Sample/ANNOT
						
					num_break=0;
					num_crest=0;
					num_sv=0;
					genomic_sv=0;
					ITX=0;
					INV=0;
					DEL=0;
					INS=0;
					CTX=0;
					num_break=`cat $input_dir/Reports_per_Sample/SV/$group.$tumor.somatic.break.vcf | awk '$0 !~ /#/' | wc -l`
					num_crest=`cat $input_dir/Reports_per_Sample/SV/$group.$tumor.somatic.final.crest.vcf | awk '$0 !~ /#/'|wc -l`
					num_sv=`expr $num_break "+" $num_crest`
					genomic_sv=`cat $struct/$group.$tumor.SV.annotated.txt | wc -l`
					if [ $genomic_sv -gt 0 ]
					then
						genomic_sv=`expr $genomic_sv "-" 1`
					fi
					ITX=`cat $struct/$group.$tumor.SV.annotated.txt | grep ITX | wc -l`
					INV=`cat $struct/$group.$tumor.SV.annotated.txt | grep INV | wc -l`
					DEL=`cat $struct/$group.$tumor.SV.annotated.txt | grep DEL | wc -l`
					INS=`cat $struct/$group.$tumor.SV.annotated.txt | grep INS | wc -l`
					CTX=`cat $struct/$group.$tumor.SV.annotated.txt | grep CTX | wc -l`
					
					echo "TOTAL SVs" >> $numbers/TUMOR.$group.$tumor.out
					echo $num_sv >> $numbers/TUMOR.$group.$tumor.out
					echo "GENOMIC SVs" >> $numbers/TUMOR.$group.$tumor.out
					echo $genomic_sv >> $numbers/TUMOR.$group.$tumor.out
					echo "ITX" >> $numbers/TUMOR.$group.$tumor.out
					echo $ITX >> $numbers/TUMOR.$group.$tumor.out
					echo "INV" >> $numbers/TUMOR.$group.$tumor.out
					echo $INV >> $numbers/TUMOR.$group.$tumor.out
					echo "DEL" >> $numbers/TUMOR.$group.$tumor.out
					echo $DEL >> $numbers/TUMOR.$group.$tumor.out
					echo "INS" >> $numbers/TUMOR.$group.$tumor.out
					echo $INS >> $numbers/TUMOR.$group.$tumor.out
					echo "CTX" >> $numbers/TUMOR.$group.$tumor.out
					echo $CTX >> $numbers/TUMOR.$group.$tumor.out
				fi	
			done
		fi
	fi 
    echo `date`
fi   
