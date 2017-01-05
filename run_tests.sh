#!/bin/bash
#
# Script to submit amber jobs and record the results in ns/day.
#

#
# Declare some variables
#
QUEUE_NAME="batch"
SEND_JOB_EMAIL="Y"
DEBUGGING="Y"
JOB_EMAIL="-m abe -M user@domain.com"
PBS_QSTAT_CMD=`qstat`
NUMBER_NODES=40
PROCS_PER_NODE=8
INTERFACE="-iface ib0"   # use IB make sure to pick mvapich below. 
#INTERFACE=""            # blank for just ethernet make sure to use mpich below. 
#
# Note: pick one of the following. Corresponds to the INTERFACE. 
# If it's IB then use mvapich if ETH then mpich
# only use one or the other or the jobs will fail
#
MPI_MODULE="mpi/mvpaich2-x86_64"
#MPI_MODULE="mpi/mpich-x86_64"

# Send mail when jobs start/stop and abort if enabled
if [ $SEND_JOB_EMAIL = "Y" ]; then 
  PBS_QSUB_CMD="qsub -l walltime=1:00:00 -q $QUEUE_NAME $JOB_EMAIL"
else
  PBS_QSUB_CMD="qsub -l walltime=1:00:00 -q $QUEUE_NAME"
fi
# turn on verbose MPI logging
if [ $DEBUGGING = "Y" ]; then 
  PBS_QSUB_CMD="$PBS_QSUB_CMD -verbose"
fi

module load $MPI_MODULE
module load apps/amber14 
  
for NODES in {1 1 1 1 2 4 8 16 24 32}
do
  for NPROC in {1 2 4 8 16 32 64 128 192 256}
  do
    # 
    # Run the example code for the amount of processors
    #
    $PBS_QSUB_CMD -N $NPROC -l nodes=$NODES:ppn=$NPROC \
    mpiexec -np $NPROC $INTERFACE \
    -env module load $MPI_MODULE \
    -env module load apps/amber14 \
    pmemd.MPI -O -i etc/amber.in -o amber-$NPROC.out -p etc/2e98-hid43-init-ions-wat.prmtop -c etc/amber.rst -r amber-$NPROC.rst -x amber-$NPROC.mdcrd
    #
    # clean up for next run
    #
    mv mdinfo mdinfo.$NPROC
    mv logfile logfile.$NPROC
  done   
done
   
   


