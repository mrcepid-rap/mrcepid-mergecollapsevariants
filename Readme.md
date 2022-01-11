# CollapseVariants (DNAnexus Platform App)

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://documentation.dnanexus.com/.

### Table of Contents

- [Introduction](#introduction)
    * [Background](#background)
    * [Dependencies](#dependencies)
        + [Docker](#docker)
        + [Resource Files](#resource-files)
- [Methodology](#methodology)
- [Running on DNANexus](#running-on-dnanexus)
    * [Inputs](#inputs)
    * [Outputs](#outputs)
    * [Command line example](#command-line-example)
        + [Batch Running](#batch-running)

## Introduction

This applet generates raw data necessary to perform rare variant burden testing using [bcftools](https://samtools.github.io/bcftools/bcftools.html),
[plink](https://www.cog-genomics.org/plink2), or [plink2](https://www.cog-genomics.org/plink/2.0/). Please see these tool's 
respective documentation for more information on how individual commands used in this applet work.

This README makes use of DNANexus file and project naming conventions. Where applicable, an object available on the DNANexus
platform has a hash ID like:

* file – `file-1234567890ABCDEFGHIJKLMN`
* project – `project-1234567890ABCDEFGHIJKLMN`

Information about files and projects can be queried using the `dx describe` tool native to the DNANexus SDK:

```commandline
dx describe file-1234567890ABCDEFGHIJKLMN
```

**Note:** This README pertains to data included as part of the DNANexus project "MRC - Variant Filtering" (project-G2XK5zjJXk83yZ598Z7BpGPk)

### Background

Downstream of this applet, we have implemented four tools / methods for rare variant burden testing:

* [BOLT](https://alkesgroup.broadinstitute.org/BOLT-LMM/BOLT-LMM_manual.html)
* [SAIGE-GENE](https://github.com/weizhouUMICH/SAIGE/wiki/Genetic-association-tests-using-SAIGE)
* [STAAR](https://github.com/xihaoli/STAAR)
* GLMs – vanilla linear/logistic models implemented with python's [statsmodels module](https://www.statsmodels.org/stable/index.html)

These four tools / methods require very different input files to run. The purpose of this applet is to generate inputs
that are compatible with each of these tools input requirements. This tool is part (2) of a two-step process (in bold):

1. Generate initial files from each VCF filtered/annotated by [mrcepid-filterbcf](https://github.com/mrcepid-rap/mrcepid-filterbcf)
   and [mrcepid-annotatecadd](https://github.com/mrcepid-rap/mrcepid-annotatecadd)
2. **Merge these resulting files into a single set of inputs for the four tools that we have implemented**

For more information on the format of these files, please see the [mrcepid-runassociationtesting](https://github.com/mrcepid-rap/mrcepid-runassociationtesting)
documentation.

### Dependencies

#### Docker

This applet uses [Docker](https://www.docker.com/) to supply dependencies to the underlying AWS instance
launched by DNANexus. The Dockerfile used to build dependencies is available as part of the MRCEpid organisation at:

https://github.com/mrcepid-rap/dockerimages/blob/main/filterbcf.Dockerfile

This Docker image is built off of the primary 20.04 Ubuntu distribution available via [dockerhub](https://hub.docker.com/layers/ubuntu/library/ubuntu/20.04/images/sha256-644e9b64bee38964c4d39b8f9f241b894c00d71a932b5a20e1e8ee8e06ca0fbd?context=explore).
This image is very light-weight and only provides basic OS installation. Other basic software (e.g. wget, make, and gcc) need
to be installed manually. For more details on how to build a Docker image for use on the UKBiobank RAP, please see:

https://github.com/mrcepid-rap#docker-images

In brief, the primary **bioinformatics software** dependencies required by this Applet (and provided in the associated Docker image)
are:

* [bcftools](https://samtools.github.io/bcftools/bcftools.html)
* [plink1.9](https://www.cog-genomics.org/plink2)  
* [plink2](https://www.cog-genomics.org/plink/2.0/)
* [R](https://www.r-project.org/) - v4.1.1 – and specifically the modules:
    * [data.table](https://cran.r-project.org/web/packages/data.table/index.html)
    * [Matrix](https://cran.r-project.org/web/packages/Matrix/index.html)

This applet also uses the "exec depends" functionality provided as part of the DNANexus applet building. Please see 
[DNANexus documentation on RunSpec](https://documentation.dnanexus.com/developer/apps/execution-environment#external-utilities)
for more information. This functionality allows one to specify python packages the applet needs via pip/apt. Here we install:

* [pandas](https://pandas.pydata.org/)

See `dxapp.json` for how this is implemented for this applet.

This list is not exhaustive and does not include dependencies of dependencies and software needed
to acquire other resources (e.g. wget). See the referenced Dockerfile for more information.

I have written a custom script for generating a file that we need to run the tool [STAAR](https://github.com/xihaoli/STAAR). 
This custom script is placed into the directory:

`resources/usr/bin`

and in accordance with dependency [instructions](https://documentation.dnanexus.com/developer/apps/dependency-management/asset-build-process)
from DNANexus, all resources stored in this folder are then included with the built app at `/usr/bin/` on the launched AWS instance.

#### Resource Files

This applet does not have any external dependencies.

## Methodology

This applet is step 4 (mrc-mergecollapsevariants) of the rare variant testing pipeline developed by Eugene Gardner for the UKBiobank
RAP at the MRC Epidemiology Unit:

![](https://github.com/mrcepid-rap/.github/blob/main/images/RAPPipeline.png)

This applet has four functions which perform merging to generate files required for final rare variant association testing.
For the purposes of brevity I am not going to go into length detail about these files here and the methodology used to 
create them. Details can be found in the commented source code available at `src/mrcepid-mergecollapsevariants.py` of this repository.
Full descriptions of these files as input to individual association tests can be found as part of the repository for 
mrcepid-runassociationtesting:

https://github.com/mrcepid-rap/mrcepid-runassociationtesting

## Running on DNANexus

### Inputs

|input|description             |
|---- |------------------------|
|input_vcf_list  | A file that contains all .tar.gz files generated by [mrcepid-collapsevariants](https://github.com/mrcepid-rap/mrcepid-collapsevariants) that you wish to merge as part of this applet. |
|file_prefix | descriptive file prefix for output name |
|threads | Number of threads available to this instance **[32]** |

**BIG Note:** The value provided to `file_prefix` **MUST** be identical for all VCF files that you wish to merge and test during
rare variant burden testing.

### Outputs

|output                 | description       |
|-----------------------|-------------------|
|output_tarball         |  Output tarball containing filtered and processed variant counts for ALL input files in `input_vcf_list`  |

output_tarball is named based on `file_prefix` like:

`PTV.tar.gz`

I am not going to go into length detail about the files contained within this .tar.gz here. Full descriptions of these 
files as input to individual association tests can be found as part of the repository for mrcepid-runassociationtesting:

https://github.com/mrcepid-rap/mrcepid-runassociationtesting

### Command line example

If this is your first time running this applet within a project other than "MRC - Variant Filtering", please see our
organisational documentation on how to download and build this app on the DNANexus Research Access Platform:

https://github.com/mrcepid-rap

To run this applet, you will first need to generate a list of files on the DNANexus platform that you want to merge
in DNANexus hash format.

1. Generate a file that contains hashes of files we want to merge:
```commandline
dx ls -l filtered_vcfs/*.PTV.tar.gz | perl -ane 'chomp $_; $F[6] =~ s/\(//; $F[6] =~ s/\)//; print "$F[6]\n"' > PTV.vcf_list.txt
```
You can do this any number of ways, but the key bit is the `dx ls -l filtered_vcfs/*.PTV.tar.gz` bit. This will return the 
list of files WITH their hash-IDs. The perl bit just extracts them and prints to the piped output (`PTV.vcf_list.txt`).

2. Upload the file BACK to DNANexus
```commandline
dx upload PTV.vcf_list.txt

# Output like:
ID                  file-G62Yq3QJXk87x29883YQXVgq
Class               file
Project             project-G2XK5zjJXk83yZ598Z7BpGPk
Folder              /
Name                PTV.vcf_list.txt
State               closing
Visibility          visible
Types               -
Properties          -
Tags                -
Outgoing links      -
Created             Fri Nov  5 14:19:58 2021
Created by          eugene.gardner
Last modified       Fri Nov  5 14:19:58 2021
Media type          
archivalState       "live"
cloudAccount        "cloudaccount-dnanexus"
```
This will upload the file to the root directory of your current project. Note the file ID from the metadata so we can use it below.

3. Run mrcepid.mergecollapsevariants:
```commandline
# Using file hash
dx run mrcepid-mergecollapsevariants --priority low --destination filtered_vcfs/ -iinput_vcf_list=file-G62Yq3QJXk87x29883YQXVgq \
        -ifile_prefix="PTV"
```

Brief I/O information can also be retrieved on the command line:

```commandline
dx run mrcepid-mergecollapsevariants --help
```

I have set a sensible (and tested) default for compute resources on DNANexus that is baked into the json used for building
the app (at `dxapp.json`) so setting an instance type is unnecessary. This current default is for a mem1_ssd1_v2_x32 instance
(36 CPUs, 72 Gb RAM, 900Gb storage). If necessary to adjust compute resources, one can provide a flag like `--instance-type mem1_ssd1_v2_x72`.

#### Batch Running

This applet is not compatible with batch running. Threads are used to parallelize merging by chromosome.

