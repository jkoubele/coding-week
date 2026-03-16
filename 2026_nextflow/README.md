# Nextflow workshop
Introduction to Nextflow.

## Setup
* Install [Nextflow](https://www.nextflow.io/) and [Docker](https://www.docker.com/) on your system.
* Get data: 
    * FASTA files from ```/cellfile/datapublic/jkoubele/nextflow_workshop/data/FASTQ.zip``` or [google drive](https://drive.google.com/file/d/1y_unIoJ7WhvUfHRvt5qh00RtYrbWQq_5/view?usp=sharing), extract them to ```data/FASTQ``` folder.
    * Transcriptome annotation: download [Caenorhabditis_elegans.WBcel235.cdna.all.fa.gz](https://ftp.ensembl.org/pub/release-115/fasta/caenorhabditis_elegans/cdna/Caenorhabditis_elegans.WBcel235.cdna.all.fa.gz) and 
[Caenorhabditis_elegans.WBcel235.115.gtf.gz](https://ftp.ensembl.org/pub/release-115/gtf/caenorhabditis_elegans/Caenorhabditis_elegans.WBcel235.115.gtf.gz) from Ensembl,
extrac them to ```data/transcriptome```.
* You can optionally build the R docker image by ```docker build -t nextflow_workshop_r ./dockerfiles/docker_r/```. (The Nextflow pipelines uses the builded image ```jkoubele/nextflow_workshop_r``` hosted on DockerHub).
* You can also push your built image to DockerHub:
    * Register on [DockerHub](https://hub.docker.com/).
    * Tag the image by ```docker tag nextflow_workshop_r YOUR_USERNAME/nextflow_workshop_r:latest``` (replace YOUR_USERNAME by your username on the DockerHub).
    * Login by ```docker login```, fill in your DockerHub credentials.
    * Push the image by ```docker push YOUR_USERNAME/nextflow_workshop_r:latest```.


## Running the pipeline
The example pipeline can be then executed by ```nextflow run main.nf```. Use ```-resume``` argument to re-use cached results.

To execute it on a cluster via SLURM, simply log in the management server and run
```nextflow run main.nf -process.executor slurm```.