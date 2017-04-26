#!/bin/bash -i
#
# Script to submit amber jobs and record the results in ns/day.
#

#
# Amber VARIABLES
#
APPLICATION=pmemd.MPI
AMBER_IN=~/amber_cluster_benchmark/etc/amber.in
AMBER_OUT=amber.out
PRMTOP=~/amber_cluster_benchmark/etc/2e98-hid43-init-ions-wat.prmtop
RESTART_IN=~/amber_cluster_benchmark/etc/amber.rst 
RESTART_OUT=amber.rst 
COORD=amber.mdcrd
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
	RESULTS_FILE=results-ib
else
	RESULTS_FILE=results-eth
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
echo "module load amber/14" >> $RUNS_DIR/load_modules
source $RUNS_DIR/load_modules

cd $RUNS_DIR
#
# create results file header
#
echo "NS_PER_DAY,NPROC" > $RESULTS_FILE.csv
#
# now loop through the amount of CPU's and run jobs for each one
#
# this sequence is the number of processors. You might want to adjust for your cluster
#
# Assuming 8 cores per node pick numbers from the following chart.
#
# NODES: 1 | 2  | 4  | 6  | 8  | 12 | 14  | 16  | 18  | 20  | 22  | 24  | 28  | 32  | 36  | 40  | 42  | 44  | 48  | 52
# NPROC: 8 | 16 | 32 | 48 | 64 | 96 | 112 | 128 | 144 | 160 | 176 | 192 | 224 | 256 | 288 | 320 | 336 | 352 | 384 | 416
#
# Note: NPROC 2,4 and 8 all work on one node. 
#
  for NPROC in 2 4 8 16 32 48 64 96 112 128 144 160 176 192 224 256 288 320 336
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
    echo "/usr/bin/time mpiexec -np $NPROC $INTERFACE $APPLICATION -O -i $AMBER_IN -o $AMBER_OUT -p $PRMTOP -c $RESTART_IN -r $RESTART_OUT -x $COORD" >> proc-$NPROC/job-$NPROC.run
    echo "NS_PER_DAY=\`cat mdinfo | grep ns/day | tail -1 | awk '{print \$4}'\`" >> proc-$NPROC/job-$NPROC.run
    echo "NPROC=\`pwd | awk -F/ '{print \$6}'|awk -F- '{print \$2}'\`" >> proc-$NPROC/job-$NPROC.run
    echo 'echo "$NS_PER_DAY,$NPROC" >> ../RESULTS_FILE.csv' >> proc-$NPROC/job-$NPROC.run
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
stuff<-read.csv("$RESULTS_FILE.csv",header=TRUE)
attach(stuff)
library(car)
png("$RESULTS_FILE.png",bg="transparent",width=750,height=350)
scatterplot(NS_PER_DAY~NPROC,ylim=c(0,20),)
# Create a title with a red, bold/italic font
title(main="Amber MPI Scaling (IB)", col.main="red", font.main=4)
# Label the x and y axes with dark green text
#title(xlab="Processors", col.lab=rgb(0,0.5,0))
#title(ylab="NS/Day", col.lab=rgb(0,0.5,0))
dev.off() # file will be saved in working directory (no screen display)

EOF

chmod 755 $RUNS_DIR/make_graph.R

#
# create the script to make the webpage
#
touch $RUNS_DIR/make_web.sh
tee $RUNS_DIR/make_web.sh <<EOF 
#!/bin/bash
sort --field-separator=',' -n -k2 -k1 $RESULTS_FILE.csv >> results.csv
rm -f $RESULTS_FILE.csv
mv results.csv $RESULTS_FILE.csv
./make_graph.R
cp $RESULTS_FILE.png ~/public_html/amber_cluster_benchmark/img/


EOF

chmod 755 $RUNS_DIR/make_web.sh

#
# make the index page
#
mkdir -p ~/public_html/amber_cluster_benchmark/img
touch ~/public_html/amber_cluster_benchmark/index.html
tee ~/public_html/amber_cluster_benchmark/index.html <<EOF 

<html>
<h2>HPC Benchmark for Amber</h2>
<body>

<strong>Amber Results in NS/Day (Infiniband)</strong>
<br/>
<img src="img/$RESULTS_FILE.png" alt="Graph of Results" height="350" width="750">
<br/>

</body>
</html>

EOF

chmod -R 755 ~/public_html

