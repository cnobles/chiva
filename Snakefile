# Targeted Sequencing Analyis of HIV Integration Sites
#
# Author : Christopher Nobles, Ph.D.

import os
import sys
import re
import yaml
import configparser
from pathlib import Path
from chivalib import import_sample_info, choose_sequence_data

if not config:
    raise SystemExit("No config file specified.")

# Import sampleInfo
if ".csv" in config["Sample_Info"]:
    delim = ","
elif ".tsv" in config["Sample_Info"]:
    delim = "\t"
else:
    raise SystemExit("Sample Info file contain extention '.csv' or '.tsv'.")

## Sample information
sampleInfo = import_sample_info(
    config["Sample_Info"], config["Sample_Name_Column"], delim)

SAMPLES=sampleInfo[config["Sample_Name_Column"]]
TYPES=config["Read_Types"]
READS=config["Genomic_Reads"]

# Trimming data references
R1_LEAD = choose_sequence_data(config["R1_Leading_Trim"], sampleInfo)
R1_OVER = choose_sequence_data(config["R1_Overreading_Trim"], sampleInfo)
R2_LEAD_PRIMER = choose_sequence_data(config["R2_Primer_Seq"], sampleInfo)
R2_LTR = choose_sequence_data(config["R2_LTRBit_Seq"], sampleInfo)
TERM_CA = config["Require_TermCA"]
R2_OVER = config["R2_Overreading_Trim"]

# Default params if not included in config
if not "maxNcount" in config:
    config["maxNcount"] = 1

if not "demultiCores" in config: 
    demulti_cores = snakemake.utils.available_cpu_count()
else:
    demulti_cores = min(
        config["demultiCores"], snakemake.utils.available_cpu_count()
    )


# Working paths
ROOT_DIR = ""
try:
    ROOT_DIR = os.environ["CHIVA_DIR"]
except KeyError:
    raise SystemExit(
        "CHIVA_DIR environment variable not defined. Are you sure you "
        "activated the chiva conda environment?")

if not Path(ROOT_DIR).exists():
    raise SystemExit(
        "Cannot identify Install Directory for cHIVa. Check CHIVA_DIR variable"
        "and make sure you've activated the 'chiva' conda environment."
    )

RUN = config["Run_Name"]

CODE_DIR = Path(ROOT_DIR) / "tools/rscripts"
if not CODE_DIR.exists():
    raise SystemExit(
        "Cannot identify code directory for cHIVa. Check CHIVA_DIR variable "
        "and make sure you've activated the 'chiva' conda environment. "
        "Additionally, make sure your install of cHIVa is up-to-date."
    )

if "Processing_Path" in config:
    PROC_DIR = Path(config["Processing_Path"]) / RUN
    if not PROC_DIR.exists():
        abs_PROC_DIR = Path(ROOT_DIR) / str(PROC_DIR)
        if not abs_PROC_DIR.exists():
            raise SystemExit(
                "Cannot locate processing directory: {}"
            )
        else:
            PROC_DIR = abs_PROC_DIR
else:
    PROC_DIR = Path(ROOT_DIR) / "analysis" / RUN

if not PROC_DIR.exists():
    raise SystemExit(
        "Cannot identify processing directory for cHIVa run {}. Make sure "
        "you've set up your processing directory before trying to 'run' cHIVa. "
        "Also double check your config file.".format(
            config["Run_Name"]
        )
    )
    
# Change to strings
ROOT_DIR = str(ROOT_DIR)
CODE_DIR = str(CODE_DIR)
PROC_DIR = str(PROC_DIR) 

# Check for input files
R1_SEQ_INPUT = Path(config["R1"])
if not R1_SEQ_INPUT.exists():
    proc_R1_SEQ_INPUT = Path(PROC_DIR) / config["R1"]
    if not proc_R1_SEQ_INPUT.exists():
        skmk_R1_SEQ_INPUT = Path(ROOT_DIR) / config["R1"]
        if not skmk_R1_SEQ_INPUT:
            raise SystemExit(
                "Cannot find sequencing files: {}".format(config["R1"])
            )
        else:
            R1_SEQ_INPUT = skmk_R1_SEQ_INPUT
            R2_SEQ_INPUT = Path(ROOT_DIR) / config["R2"]
            I1_SEQ_INPUT = Path(ROOT_DIR) / config["I1"]
    else:
        R1_SEQ_INPUT = proc_R1_SEQ_INPUT
        R2_SEQ_INPUT = Path(PROC_DIR) / config["R2"]
        I1_SEQ_INPUT = Path(PROC_DIR) / config["I1"]
else:
    R2_SEQ_INPUT = Path(config["R2"])
    I1_SEQ_INPUT = Path(config["I1"])

R1_SEQ_INPUT = str(R1_SEQ_INPUT)
R2_SEQ_INPUT = str(R2_SEQ_INPUT)
I1_SEQ_INPUT = str(I1_SEQ_INPUT)


# Target Rules
rule all:
    input: 
        stdSites=PROC_DIR + "/output_data/standardized_uniq_sites.rds",
        condSites=PROC_DIR + "/output_data/condensed_sites.csv",
        xofilSites=PROC_DIR + "/output_data/xofil_condensed_sites.csv",
        readMat=PROC_DIR + "/output_data/read_site_matrix.csv",
        fragMat=PROC_DIR + "/output_data/fragment_site_matrix.csv",
        sumTbl=PROC_DIR + "/output_data/summary_table.csv",
        report=PROC_DIR + "/output_data/report." + RUN + "." + config["reportFormat"]

# Processing Rules
include: "rules/demulti.rules"
include: "rules/trim.rules"
include: "rules/filter.rules"
include: "rules/consol.rules"
include: "rules/align.blat.rules"
include: "rules/process.rules"