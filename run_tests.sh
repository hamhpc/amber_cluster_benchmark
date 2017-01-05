#!/bin/bash -i
#
# Script to submit amber jobs and record the results in ns/day.
#

#
# Declare some variables
#
QUEUE_NAME="una"
SEND_JOB_EMAIL="Y"
DEBUGGING="Y"
JOB_EMAIL="-m abe -M user@domain.com"
PBS_QSTAT_CMD=`qstat`
NUMBER_NODES=40
PROCS_PER_NODE=8
RUNS_DIR="~/amber_cluster_benchmark/runs-`date "+%h-%d-%Y-%R"`
INTERFACE="-iface ib0"   # use IB make sure to pick mvapich below. 
#INTERFACE=""            # blank for just ethernet make sure to use mpich below. 
#
# Note: pick one of the following. Corresponds to the INTERFACE. 
# If it's IB then use mvapich if ETH then mpich
# only use one or the other or the jobs will fail
#
MPI_MODULE="mpi/mvapich2-x86_64"
#MPI_MODULE="mpi/mpich-x86_64"

# Send mail when jobs start/stop and abort if enabled
if [ $SEND_JOB_EMAIL = "Y" ]; then 
  PBS_QSUB_CMD="/usr/local/bin/qsub -j oe -l walltime=1:00:00 -q $QUEUE_NAME $JOB_EMAIL"
else
  PBS_QSUB_CMD="/usr/local/bin/qsub -j oe -l walltime=1:00:00 -q $QUEUE_NAME"
fi
# turn on verbose MPI logging
if [ $DEBUGGING = "Y" ]; then 
  PBS_QSUB_CMD="$PBS_QSUB_CMD -verbose"
fi

echo "module load $MPI_MODULE" > load_modules
echo "module load apps/amber14" >> load_modules
source load_modules

mkdir -p $RUNS_DIR
cd $RUNS_DIR
  for NPROC in 001 002 004 008 016 032 064 128 192 256
  do
    mkdir $NPROC
    NODES=$(($NPROC/$PROCS_PER_NODE))
    if [ "$NODES" -le "1" ];  then 
        NODES=1
	      PPN=$NPROC
    else 
	      PPN=$PROCS_PER_NODE
    fi
    # 
    # Run the example code for the amount of processors
    #
    echo "#!/bin/bash -i" > $NPROC/job-$NPROC.run
    echo 'cd $PBS_O_WORKDIR' >> $NPROC/job-$NPROC.run
    echo 'export PATH=$PBS_O_PATH' >> $NPROC/job-$NPROC.run
    echo "source load_modules" >> $NPROC/job-$NPROC.run
    echo "mpiexec -np $NPROC $INTERFACE pmemd.MPI -O -i ~/amber_cluster_benchmark/etc/amber.in -o amber-$NPROC.out -p ~/amber_cluster_benchmark/etc/2e98-hid43-init-ions-wat.prmtop -c ~/amber_cluster_benchmark/etc/amber.rst -r amber-$NPROC.rst -x amber-$NPROC.mdcrd" >> $NPROC/job-$NPROC.run
    #echo "mv mdinfo mdinfo.$NPROC" >> $NPROC/job-$NPROC.run
    #echo "mv logfile logfile.$NPROC" >> $NPROC/job-$NPROC.run
    #
    # now submit the job
    #
    cd $RUNS_DIR/$NPROC
    $PBS_QSUB_CMD -N $NPROC -l nodes=$NODES:ppn=$PPN job-$NPROC.run
    
  done
   
   


