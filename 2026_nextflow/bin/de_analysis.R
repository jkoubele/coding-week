#!/usr/bin/env Rscript

library(argparse)
library(tidyverse)
library(DESeq2)

if (interactive()) {
  args <- list(
    # Hard-coding paths on your system can be useful for development/testing:
    count_matrix = "/home/jakub/Desktop/nextflow_workshop/results/read_counts/count_matrix.tsv",
    samplesheet  = "/home/jakub/Desktop/nextflow_workshop/data/samplesheet.csv"
  )
} else {
  parser <- ArgumentParser()
  parser$add_argument("--count_matrix", required = TRUE)
  parser$add_argument("--samplesheet", required = TRUE)
  args <- parser$parse_args()
}

# ---------------------------
# Load inputs
# ---------------------------
count_matrix <- read_tsv(args$count_matrix, show_col_types = FALSE)
samplesheet  <- read_csv(args$samplesheet, show_col_types = FALSE)

# ---------------------------
# Prepare count matrix
# ---------------------------
colnames(count_matrix) <- gsub("[\\[\\],]", "", colnames(count_matrix))
colnames(count_matrix) <- trimws(colnames(count_matrix))

gene_ids <- count_matrix$gene_id

counts <- count_matrix |>
  select(-gene_id) |>
  as.matrix() |>
  round()

rownames(counts) <- gene_ids

# remove genes with all-zero counts
counts <- counts[rowSums(counts) > 0, , drop = FALSE]

# ---------------------------
# Prepare metadata
# ---------------------------
samplesheet <- samplesheet |>
  mutate(
    sample = trimws(sample),
    age = factor(age)
  ) |>
  select(sample, age)

count_samples <- tibble(sample = trimws(colnames(counts)))

samplesheet_df <- count_samples |>
  left_join(samplesheet, by = "sample")

print(samplesheet_df)

if (any(is.na(samplesheet_df$age))) {
  stop("Some count-matrix columns could not be matched to samplesheet.")
}

samplesheet_df <- as.data.frame(samplesheet_df)
rownames(samplesheet_df) <- samplesheet_df$sample
samplesheet_df$sample <- NULL

stopifnot(identical(colnames(counts), rownames(samplesheet_df)))

# ---------------------------
# DESeq2 analysis
# ---------------------------
dds <- DESeqDataSetFromMatrix(
  countData = counts,
  colData   = samplesheet_df,
  design    = ~ age
)

dds <- DESeq(dds)

res <- results(dds, contrast = c("age", "old", "young"))

res_df <- as.data.frame(res) |>
  rownames_to_column("gene")

write_tsv(res_df, "DE_results.tsv")

# ---------------------------
# Volcano plot
# ---------------------------
volcano <- res_df |>
  mutate(sig = !is.na(padj) & padj < 0.05)

p_volcano <- ggplot(volcano, aes(log2FoldChange, -log10(padj))) +
  geom_point(aes(color = sig), alpha = 0.6) +
  scale_color_manual(values = c("grey70", "red")) +
  theme_bw() +
  labs(
    title = "Volcano plot: old vs young",
    x = "log2 fold change",
    y = "-log10 adjusted p-value"
  )

ggsave(
  "volcano_plot.png",
  p_volcano,
  width = 6,
  height = 5,
  dpi = 300
)

# ---------------------------
# PCA plot
# ---------------------------
vsd <- vst(dds)

pca <- plotPCA(vsd, intgroup = "age", returnData = TRUE)
percentVar <- round(100 * attr(pca, "percentVar"))

p_pca <- ggplot(pca, aes(PC1, PC2, color = age)) +
  geom_point(size = 4) +
  theme_bw() +
  labs(
    x = paste0("PC1: ", percentVar[1], "%"),
    y = paste0("PC2: ", percentVar[2], "%"),
    title = "PCA"
  )

ggsave(
  "PCA_plot.png",
  p_pca,
  width = 6,
  height = 5,
  dpi = 300
)