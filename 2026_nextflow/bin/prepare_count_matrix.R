#!/usr/bin/env Rscript

library(argparse)
library(tximport)
library(GenomicFeatures)
library(AnnotationDbi)
library(tidyverse)


parser <- ArgumentParser()
parser$add_argument("--sample_names", nargs = "+", required = TRUE)
parser$add_argument("--quant_files", nargs = "+", required = TRUE)
parser$add_argument("--gtf_file",
                    required = TRUE,
                    help = "Path to input GTF file.")

args <- parser$parse_args()

txdb <- makeTxDbFromGFF(file.path(args$gtf_file), format = "gtf")
k <- keys(txdb, keytype = "TXNAME")
tx2gene <- AnnotationDbi::select(txdb, keys = k, columns = "GENEID", keytype = "TXNAME")

write_tsv(tx2gene, 'tx2gene.tsv')

txi <- tximport(args$quant_files,
                type = "salmon",
                tx2gene = tx2gene,
                countsFromAbundance = 'no')

colnames(txi$counts) <- args$sample_names

read_counts <- as.data.frame(txi$counts) |>
  rownames_to_column(var = "gene_id") |>
  write_tsv('count_matrix.tsv')