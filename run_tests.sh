#!/bin/bash -i
#
# Script to submit amber jobs and record the results in ns/day.
#

#
# Declare some variables
#
QUEUE_NAME="una"
SEND_JOB_EMAIL="N"
DEBUGGING="N"
JOB_EMAIL="-m abe -M user@domain.com"
PBS_QSTAT_CMD=`qstat`
NUMBER_NODES=40
PROCS_PER_NODE=8
RUN_DATE=`date "+%h-%d-%Y-%R"`
RUNS_DIR="${HOME}/amber_cluster_benchmark/results_$RUN_DATE"
INTERFACE="-iface ib0"   # use IB make sure to pick mvapich below. 
#INTERFACE=""            # blank for just ethernet make sure to use mpich below. 
#
# Note: pick one of the following. Corresponds to the INTERFACE. 
# If it's IB then use mvapich if ETH then mpich
# only use one or the other or the jobs will fail
#
MPI_MODULE="mpi/mvapich2-x86_64"
#MPI_MODULE="mpi/mpich-x86_64"

if [ $MPI_MODULE = "mpi/mvapich2-x86_64" ]; then
	RESULTS_FILE=results-ib.csv
else
	RESULTS_FILE=results-eth.csv
fi

# Send mail when jobs start/stop and abort if enabled
if [ $SEND_JOB_EMAIL = "Y" ]; then 
  PBS_QSUB_CMD="/usr/local/bin/qsub -j oe -l walltime=1:30:00 -q $QUEUE_NAME $JOB_EMAIL"
else
  PBS_QSUB_CMD="/usr/local/bin/qsub -j oe -l walltime=1:30:00 -q $QUEUE_NAME"
fi
# turn on verbose MPI logging
if [ $DEBUGGING = "Y" ]; then 
  PBS_QSUB_CMD="$PBS_QSUB_CMD -verbose"
fi

mkdir -p $RUNS_DIR
echo "module load $MPI_MODULE" > $RUNS_DIR/load_modules
echo "module load apps/amber14" >> $RUNS_DIR/load_modules
source $RUNS_DIR/load_modules

cd $RUNS_DIR
#
# create results file header
#
echo "NS_PER_DAY,NPROC" > $RESULTS_FILE
#
# now loop through the amount of CPU's and run jobs for each one
#
  for NPROC in 2 4 8 16 32 64 128 192 256 336
  do
    mkdir -p proc-$NPROC
    NODES=$(($NPROC/$PROCS_PER_NODE))
    if [ "$NODES" -le "1" ];  then 
        NODES=1
	      PPN=$NPROC
    else 
	      PPN=$PROCS_PER_NODE
    fi
    # 
    # create the code for this job to submit to the cluster
    #
    echo "#!/bin/bash -i" > proc-$NPROC/job-$NPROC.run
    echo 'cd $PBS_O_WORKDIR' >> proc-$NPROC/job-$NPROC.run
    echo 'export PATH=$PBS_O_PATH' >> proc-$NPROC/job-$NPROC.run
    echo "source ../load_modules" >> proc-$NPROC/job-$NPROC.run
    echo "date" >> proc-$NPROC/job-$NPROC.run
    echo "mpiexec -np $NPROC $INTERFACE pmemd.MPI -O -i ~/amber_cluster_benchmark/etc/amber.in -o amber-$NPROC.out -p ~/amber_cluster_benchmark/etc/2e98-hid43-init-ions-wat.prmtop -c ~/amber_cluster_benchmark/etc/amber.rst -r amber-$NPROC.rst -x amber-$NPROC.mdcrd" >> proc-$NPROC/job-$NPROC.run
    echo "NS_PER_DAY=\`cat mdinfo | grep ns/day | tail -1 | awk '{print \$4}'\`" >> proc-$NPROC/job-$NPROC.run
    echo "NPROC=\`pwd | awk -F/ '{print \$6}'|awk -F- '{print \$2}'\`" >> proc-$NPROC/job-$NPROC.run
    echo 'echo "$NS_PER_DAY,$NPROC" >> ../RESULTS_FILE' >> proc-$NPROC/job-$NPROC.run
    echo "date" >> proc-$NPROC/job-$NPROC.run
    #
    # change the script to use the proper results file
    #
    sed -i "s|RESULTS_FILE|${RESULTS_FILE}|g" proc-$NPROC/job-$NPROC.run
    #
    # now submit the job
    #
    cd $RUNS_DIR/proc-$NPROC
    $PBS_QSUB_CMD -N MpiTest-$NPROC -l nodes=$NODES:ppn=$PPN job-$NPROC.run
    cd ..
    
  done
   
   #
   # create the script to make the graph
   #
   touch $RUNS_DIR/make_graph.R
   tee $RUNS_DIR/make_graph.R <<EOF 
#!/usr/bin/env Rscript
stuff<-read.csv("$RESULTS_FILE",header=TRUE)
attach(stuff)
library(car)
png("results.png",bg="transparent",width=750,height=350)
# Create a title with a red, bold/italic font
title(main="Amber MPI Scaling (IB)", col.main="red", font.main=4)
# Label the x and y axes with dark green text
title(xlab="Processors", col.lab=rgb(0,0.5,0))
title(ylab="NS/Day", col.lab=rgb(0,0.5,0))
scatterplot(NS_PER_DAY~NPROC)
dev.off() # file will be saved in working directory (no screen display)

EOF

chmod 755 $RUNS_DIR/make_graph.R


