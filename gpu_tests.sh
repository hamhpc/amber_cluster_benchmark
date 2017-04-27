#!/bin/bash -i
#
# Script to submit amber jobs to GPU's and record the results in ns/day.
#

#
# Amber VARIABLES
#
APPLICATION=pmemd.cuda
AMBER_IN=~/amber_cluster_benchmark/etc/amber.in
AMBER_OUT=amber.out
PRMTOP=~/amber_cluster_benchmark/etc/2e98-hid43-init-ions-wat.prmtop
RESTART_IN=~/amber_cluster_benchmark/etc/amber.rst 
RESTART_OUT=amber.rst 
COORD=amber.mdcrd
#
# Declare some variables
#
QUEUE_NAME="gpu"
SEND_JOB_EMAIL="N"
DEBUGGING="N"
JOB_EMAIL="-m abe -M user@domain.com"
PBS_QSTAT_CMD=`qstat`
NUMBER_GPUS=7
PROCS_PER_NODE=1
RUN_DATE=`date "+%h-%d-%Y-%R"`
RUNS_DIR="${HOME}/amber_cluster_benchmark/results_gpu-$RUN_DATE"
INTERFACE=""  # blank for just ethernet
#
# Note: pick one of the following. Corresponds to the INTERFACE. 
# If it's IB then use mvapich if ETH then mpich
# only use one or the other or the jobs will fail
#
MPI_MODULE="mpi/mpich-x86_64"
CUDA_MODULE="cuda/7.5"
RESULTS_FILE=results-gpu


# Send mail when jobs start/stop and abort if enabled
if [ $SEND_JOB_EMAIL = "Y" ]; then 
  PBS_QSUB_CMD="/usr/local/bin/qsub -j oe -l walltime=2:00:00 -q $QUEUE_NAME $JOB_EMAIL"
else
  PBS_QSUB_CMD="/usr/local/bin/qsub -j oe -l walltime=2:00:00 -q $QUEUE_NAME"
fi
# turn on verbose MPI logging
if [ $DEBUGGING = "Y" ]; then 
  PBS_QSUB_CMD="$PBS_QSUB_CMD -verbose"
fi

mkdir -p $RUNS_DIR
echo "module load $MPI_MODULE" > $RUNS_DIR/load_modules
echo "module load $CUDA_MODULE" >> $RUNS_DIR/load_modules
echo "module load amber/14" >> $RUNS_DIR/load_modules
source $RUNS_DIR/load_modules

cd $RUNS_DIR
#
# create results file header
#
echo "NS_PER_DAY,GPU_HOST" > $RESULTS_FILE.csv
#
# now loop through the amount of GPU's and run jobs for each one
#
# this sequence is the number of GPU cards in the cluster. 
#
#
  for NPROC in 1 2 3 4 5 6 7
  do
    mkdir -p gpu-$NPROC
    NODES=1
    PPN=1
    # 
    # create the code for this job to submit to the cluster
    #
    echo "#!/bin/bash -i" > gpu-$NPROC/job-$NPROC.run
    echo 'cd $PBS_O_WORKDIR' >> gpu-$NPROC/job-$NPROC.run
    echo 'export PATH=$PBS_O_PATH' >> gpu-$NPROC/job-$NPROC.run
    echo "source ../load_modules" >> gpu-$NPROC/job-$NPROC.run
    echo "date" >> gpu-$NPROC/job-$NPROC.run
    #echo 'cat $PBS_NODEFILE | awk -F. '{print $1}' > gpu-card-used' >> gpu-$NPROC/job-$NPROC.run
    echo -n 'qstat -f $PBS_JOBID | grep exec_host | awk ' >> gpu-$NPROC/job-$NPROC.run
    echo -n " '{print"  >> gpu-$NPROC/job-$NPROC.run
    echo -n ' $3}' >> gpu-$NPROC/job-$NPROC.run
    echo "' > gpu-card-used" >> gpu-$NPROC/job-$NPROC.run
    echo 'export CUDA_VISIBLE_DEVICES=`cat gpu-card-used | awk -F/ '{print $2}'`' >> gpu-$NPROC/job-$NPROC.run
    echo "/usr/bin/time $APPLICATION -O -i $AMBER_IN -o $AMBER_OUT -p $PRMTOP -c $RESTART_IN -r $RESTART_OUT -x $COORD" >> gpu-$NPROC/job-$NPROC.run
    echo "NS_PER_DAY=\`cat mdinfo | grep ns/day | tail -1 | awk '{print \$4}'\`" >> gpu-$NPROC/job-$NPROC.run
    echo 'NPROC=`cat gpu-card-used`' >> gpu-$NPROC/job-$NPROC.run
    echo 'echo "$NS_PER_DAY,$NPROC" >> ../RESULTS_FILE.csv' >> gpu-$NPROC/job-$NPROC.run
    echo "date" >> gpu-$NPROC/job-$NPROC.run
    #
    # change the script to use the proper results file
    #
    sed -i "s|RESULTS_FILE|${RESULTS_FILE}|g" gpu-$NPROC/job-$NPROC.run
    #
    # now submit the job
    #
    cd $RUNS_DIR/gpu-$NPROC
    $PBS_QSUB_CMD -N GPUTest-$NPROC -l nodes=$NODES:ppn=$PPN job-$NPROC.run
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
scatterplot(NS_PER_DAY~GPU_HOST,ylim=c(0,20),)
# Create a title with a red, bold/italic font
title(main="Amber GPU Test", col.main="red", font.main=4)
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
cp -f $RESULTS_FILE.png ~/public_html/amber_cluster_benchmark/img/results-gpu.png
cp -f $RESULTS_FILE.png ~/public_html/amber_cluster_benchmark/img/results_gpu-$RUN_DATE.png
EOF

chmod 755 $RUNS_DIR/make_web.sh
chmod -R 755 ~/public_html/amber_cluster_benchmark
