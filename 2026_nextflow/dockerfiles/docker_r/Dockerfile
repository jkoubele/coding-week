FROM bioconductor/bioconductor_docker:RELEASE_3_21-R-4.5.1

RUN apt-get update && apt-get install -y pigz curl unzip make g++

RUN R -e "install.packages(c('tidyverse', 'rjson', 'argparse', 'arrow', 'ashr'))"
RUN R -e  "BiocManager::install(c('rtracklayer','DESeq2', 'txdbmaker', 'GenomicFeatures', 'tximport'))"