# Amber Cluster Benchmark

A process to submit an amber job to a cluster for a range of Processors.  
The metrics are gathered to record the results in ns/day to see the scaling metrics. 

<strong>Requirements:</strong>  
   *   R software = R is needed to generate the png graph of the results. Obtained from https://www.r-project.org/ 
   
   *   Amber software = Amber is purchased from http://ambermd.org
   
   *   A web server that has User_dir enabled for Apache. 
       This allows users to have a website at http://web-server/~username that is located at /home/username/public_html. 
       
   *   Torque PBS queue server is assumed for job creation. 

<br/>
<strong> Step 1:  clone the repository with git. </strong>

    % git clone https://github.com/hamhpc/amber_cluster_benchmark.git
    % cd amber_cluster_benchmark
    
<br/>
<strong> Step 2:  edit the configuration. </strong>

    Edit the run_tests.sh script to make sure that it will operate in your environment. 
    % vi run_tests.sh
    
<br/>
  <strong>Step 3:  run the tests.</strong>
  
    % cd amber_cluster_benchmark
    % ./run_tests.sh                
  
     This will submit a bunch of jobs to the queue. It's a sequence of NPROC's from 2 up to the max. 
     You can specify the NCPUS in the run_test.sh script. The jobs will take some time. 
     The large ones will complete first and the last to complete is the 2 CPU. 
     It usually finishes in under 1.5 hours which is what the walltime is set for the job runs. 

<br/>
<strong> Step 4:  compile the results. </strong>
 
    After all the jobs are run and off the queue you'll need to gather the results and create the web page and graph. 
    
    % cd ~/amber_cluster_bechmark/results_Jan-06-2017-15:27    (note it'll have the date of when you ran these tests)   
    % ./make_web.sh
    
    This will run the R script to generate the graph called make_graph.R. 
    It'll also build the results in your public_html directory. 
    
    From the head node webserver access: 
    
    http://<head_node_server>/~<YOUR USERNAME>/amber_cluster_benchmark/index.html

<br/>
<strong> Step 5 (optional):  Get GPU results. </strong>
    
    After building the cluster page and graph now it's time to run the gpu tests and have that image added to the index.html. 
    
    % cd ~/amber_cluster_benchmark/
    % ./gpu_tests.sh
    
    This will run the gpu tests. Make sure to edit the gpu_tests.sh script to suit your environment. 
    
<br/>
<strong> Step 6 (optional):  compile the GPU results. </strong>
 
    After all the jobs are run and off the queue you'll need to gather the results and create the GPU graph. 
  
    % cd ~/amber_cluster_bechmark/results_gpu-Jan-06-2017-15:27    (note it'll have the date of when you ran these tests) 
    
    Before making the graph, edit the results file (results-gpu.csv) and change the hosts to reflect the short_hostname:#.
    This is so the graph will look and fit better in the image. 
    Change gpunode.domain.edu/1 to gpunode:1 to represent the second card on that host. 
    
    Now build the graph image by running: 
    
    % ./make_web.sh
    
    This will run the R script to generate the graph called make_graph.R. 
    It'll also build the results in your public_html directory. 
    
    From the head node webserver access: 
    
    http://<head_node_server>/~<YOUR USERNAME>/amber_cluster_benchmark/index.html
    
    You should now see the GPU graph on the page in addition to the previous cluster test. 
    
