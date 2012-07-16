java=$1
snpeff=$2
GenomeBuild=$3
output=$4
ff=$5
gatk=$6
ref=$7
vcftools=$8
script_path=$9
sample=${10}

	$java/java -Xmx2g -Xms512m -jar $snpeff/snpEff.jar eff -onlyCoding true -chr chr -noStats -noLog -c $snpeff/snpEff.config $GenomeBuild $output/$ff.SNV.vcf > $output/$sample.SNV.eff
	$java/java -Xmx2g -Xms512m -jar $snpeff/snpEff.jar eff -onlyCoding true -chr chr -o vcf -noStats -noLog -c $snpeff/snpEff.config $GenomeBuild $output/$ff.SNV.vcf > $output/$ff.SNV.vcf.eff.vcf
	cat $output/$ff.SNV.vcf.eff.vcf | awk '{if ($0 ~ /##SnpEffVersion/) print "##SnpEffVersion=\"2.0.5 (build 2012-01-19), by Pablo Cingolani\""; else print $0;}' > $output/$ff.SNV.vcf.eff.vcf.tmp
	mv $output/$ff.SNV.vcf.eff.vcf.tmp $output/$ff.SNV.vcf.eff.vcf
	perl $script_path/snpeff.pl $output/$sample.SNV.eff > $output/$sample.SNV.eff.fill
	mv $output/$sample.SNV.eff.fill $output/$sample.SNV.eff
	$java/java -Xmx2g -Xms512m -jar $gatk/GenomeAnalysisTK.jar \
	-T VariantAnnotator \
	-et NO_ET \
	-K $gatk/Hossain.Asif_mayo.edu.key \
	-R $ref \
	-A SnpEff \
	--variant $output/$ff.SNV.vcf \
	--snpEffFile $output/$ff.SNV.vcf.eff.vcf \
	-L $output/$ff.SNV.vcf \
	-o $output/$ff.SNV.vcf.annot.vcf > $output/log 2>&1
	
	$vcftools/bin/vcftools --vcf $output/$ff.SNV.vcf.annot.vcf \
	--get-INFO SNPEFF_AMINO_ACID_CHANGE \
	--get-INFO SNPEFF_EFFECT \
	--get-INFO SNPEFF_EXON_ID \
	--get-INFO SNPEFF_FUNCTIONAL_CLASS \
	--get-INFO SNPEFF_GENE_BIOTYPE \
	--get-INFO SNPEFF_GENE_NAME \
	--get-INFO SNPEFF_IMPACT \
	--get-INFO SNPEFF_TRANSCRIPT_ID \
	--out $output/$ff.SNV.vcf.annot > $output/log 2>&1
            
	perl $script_path/parse_snpeffect.pl $output/$ff.SNV.vcf.annot.INFO > $output/$sample.SNV.filtered.eff
	rm $output/$ff.SNV.vcf.annot.INFO $output/$ff.SNV.vcf.annot.log
	rm $output/$ff.SNV.vcf.annot.vcf $output/$ff.SNV.vcf.annot.vcf.idx $output/$ff.SNV.vcf.annot.vcf.vcfidx
	rm  $output/$ff.SNV.vcf.idx $output/$ff.SNV.vcf.eff.vcf $output/$ff.SNV.vcf.eff.vcf.idx 

	echo "Filtering SNPEFF output from multiple transcript to most impacting transcript"
	## INDELs
	$java/java -Xmx2g -Xms512m -jar $snpeff/snpEff.jar eff -onlyCoding true -chr chr -noStats -noLog -c $snpeff/snpEff.config $GenomeBuild $output/$ff.INDEL.vcf > $output/$sample.INDEL.eff
	$java/java -Xmx2g -Xms512m -jar $snpeff/snpEff.jar eff -onlyCoding true -o vcf -chr chr -noStats -noLog -c $snpeff/snpEff.config $GenomeBuild $output/$ff.INDEL.vcf > $output/$ff.INDEL.vcf.eff.vcf
	perl $script_path/snpeff.pl $output/$sample.INDEL.eff > $output/$sample.INDEL.eff.tmp
	mv $output/$sample.INDEL.eff.tmp $output/$sample.INDEL.eff
	cat $output/$ff.INDEL.vcf.eff.vcf | awk '{if ($0 ~ /##SnpEffVersion/) print "##SnpEffVersion=\"2.0.5 (build 2012-01-19), by Pablo Cingolani\""; else print $0;}' > $output/$ff.INDEL.vcf.eff.vcf.tmp
	mv $output/$ff.INDEL.vcf.eff.vcf.tmp $output/$ff.INDEL.vcf.eff.vcf

	### use GATK to filter the multiple transcript
	$java/java -Xmx2g -Xms512m -jar $gatk/GenomeAnalysisTK.jar \
	-T VariantAnnotator \
	-et NO_ET \
	-K $gatk/Hossain.Asif_mayo.edu.key \
	-R $ref \
	-A SnpEff \
	--variant $output/$ff.INDEL.vcf \
	--snpEffFile $output/$ff.INDEL.vcf.eff.vcf \
	-L $output/$ff.INDEL.vcf \
	-o $output/$ff.INDEL.vcf.annot.vcf > $output/log 2>&1

	$vcftools/bin/vcftools --vcf $output/$ff.INDEL.vcf.annot.vcf \
	--get-INFO SNPEFF_AMINO_ACID_CHANGE \
	--get-INFO SNPEFF_EFFECT \
	--get-INFO SNPEFF_EXON_ID \
	--get-INFO SNPEFF_FUNCTIONAL_CLASS \
	--get-INFO SNPEFF_GENE_BIOTYPE \
	--get-INFO SNPEFF_GENE_NAME \
	--get-INFO SNPEFF_IMPACT \
	--get-INFO SNPEFF_TRANSCRIPT_ID \
	--out $output/$ff.INDEL.vcf.annot > $output/log 2>&1

	perl $script_path/parse_snpeffect.pl $output/$ff.INDEL.vcf.annot.INFO > $output/$sample.INDEL.filtered.eff
	rm $output/$ff.INDEL.vcf.annot.INFO $output/$ff.INDEL.vcf.annot.log
	rm $output/$ff.INDEL.vcf.annot.vcf $output/$ff.INDEL.vcf.annot.vcf.idx $output/$ff.INDEL.vcf.annot.vcf.vcfidx
	rm  $output/$ff.INDEL.vcf.idx $output/$ff.INDEL.vcf.eff.vcf $output/$ff.INDEL.vcf.eff.vcf.idx 
	echo "SNPEFF is done"