#!/bin/bash
#
# Script to submit amber jobs and record the results in ns/day.
#

PBS_QSUB_CMD=`qsub`
PBS_QSTAT_CMD=`qstat`
NUMBER_NODES=40
PROCS_PER_NODE=8



