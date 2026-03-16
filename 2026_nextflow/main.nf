
process FastQC {

    container "quay.io/biocontainers/fastqc:0.12.1--hdfd78af_0"

    input:
    tuple val(sample), path(read1), path(read2)

    tag "$sample"

    output:
    path("*.zip"), emit: fastqc_reports
    path("*.html")

    publishDir "./results/FastQC/${sample}", mode: 'copy'

    script:
    """
    fastqc $read1 $read2 --outdir .
    """
}

process MultiQC {

    container "multiqc/multiqc:v1.30"

    input:
    path zip_files

    output:
    path("*")

    publishDir "./results/MultiQC", mode: 'copy'

    script:
    """
    multiqc . --filename multiqc_report.html
    """
}

process BuildSalmonIndex {

    container "combinelab/salmon"

    cpus 4

    input:
    path transcriptome_fasta

    output:
    path("salmon_index"), emit: salmon_index_dir

    publishDir "./results/Salmon_index", mode: 'copy'

    script:
    """
    mkdir salmon_index
    salmon index \
        -t $transcriptome_fasta \
        -i salmon_index \
        -p ${task.cpus}
    """

}

process SalmonQuantification {

    container "combinelab/salmon"

    input:
        tuple val(sample), path(read1), path(read2), path(salmon_index)

    output:
        tuple val(sample), path("${sample}.quant.sf"), emit: salmon_quant

    publishDir "./results/Salmon_quantification/${sample}", mode: 'copy'

    tag "$sample"

    script:
    """
    salmon quant \
        -i $salmon_index \
        -l A \
        -1 $read1 \
        -2 $read2 \
        -p ${task.cpus} \
        -o .
    mv quant.sf ${sample}.quant.sf
    """
}

process PrepareCountMatrix {

    container "jkoubele/nextflow_workshop_r"

    input:
    tuple val(sample_names), path(quant_files), path(gtf)

    output:
    path("tx2gene.tsv"), emit: tx2gene_file
    path("count_matrix.tsv"), emit: count_matrix

    publishDir "./results/read_counts", mode: 'copy'

    script:
    """
    prepare_count_matrix.R \
    --sample_names ${sample_names.join(' ')} \
    --quant_files ${quant_files.join(' ')} \
    --gtf_file $gtf
    """
}

process DEAnalysis {

    container "jkoubele/nextflow_workshop_r"

    input:
    tuple path(count_matrix), path(samplesheet)

    output:
    path("DE_results.tsv")
    path("PCA_plot.png")
    path("volcano_plot.png")

    publishDir "./results/DE_analysis", mode: 'copy'

    script:
    """
    de_analysis.R --count_matrix $count_matrix --samplesheet $samplesheet
    """
}

workflow{

        samplesheet = './data/samplesheet.csv'
        fastq_dir = './data/FASTQ'

        samplesheet_channnel = Channel.fromPath(samplesheet)
        samples = samplesheet_channnel
                .splitCsv(header: true)
                .map { row ->
                    def sample      = row.sample
                    def fq1         = file("${fastq_dir}/${row.fastq_1}")
                    def fq2         = file("${fastq_dir}/${row.fastq_2}")

                    if (!fq1.exists()) error "FASTQ file not found: ${fq1}"
                    if (!fq2.exists()) error "FASTQ file not found: ${fq2}"

                    tuple(sample, fq1, fq2)
                }


        def fastqc_out = FastQC(samples)
        def fastqc_out_aggregated = fastqc_out.fastqc_reports.collect()
        MultiQC(fastqc_out_aggregated)

        def transcriptome_fasta = Channel.fromPath('./data/transcriptome/Caenorhabditis_elegans.WBcel235.cdna.all.fa')
        def salmon_index =  BuildSalmonIndex(transcriptome_fasta)

        def salmon_quant_out = samples.combine(salmon_index.salmon_index_dir) | SalmonQuantification

        def gtf_channel = Channel.fromPath('./data/transcriptome/Caenorhabditis_elegans.WBcel235.115.gtf')

        def collected_quant = salmon_quant_out.salmon_quant
            .collect(flat: false)
            .map {list_of_tuples ->
                def list_of_tuples_sorted = list_of_tuples.sort { it[0] }
                def sample_names = list_of_tuples_sorted*.getAt(0)
                def quant_files  = list_of_tuples_sorted*.getAt(1)
                tuple(sample_names, quant_files)}

        def count_matrix_input = collected_quant.combine(gtf_channel)

        def count_matrix_channel = PrepareCountMatrix(count_matrix_input)

        def de_analysis_input = count_matrix_channel.count_matrix.combine(samplesheet_channnel)

        de_analysis_input | DEAnalysis

}
