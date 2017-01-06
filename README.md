# amber_cluster_benchmark

A process to submit an amber job to a cluster for a range of Processors.  
The metrics are gathered to record the results in ns/day to see the scaling metrics. 

<strong>Requirements:</strong>  
   *   R software = R is needed to generate the png graph of the results. Obtained from https://www.r-project.org/ 
   
   *   Amber software = Amber is purchased from http://ambermd.org
   
   *   A web server that has User_dir enabled for Apache. 
       This allows users to have a website at http://web-server/~username that is located at /home/username/public_html. 
       
   *   Torque PBS queue server is assumed for job creation. 

Intro:



Usage: 

  Step 1:  execute the run_tests.sh script. Be sure to update the script variables for your environment. 
  
     This will submit a bunch of jobs to the queue. It's a sequence of NPROC's from 2 up to the max. You can specify the NCPUS in the run_test.sh script. The jobs will take some time. The large ones will complete fisrt and the last to complete is the 2 CPU. It usually finishes in under 1.5 hours which is what the walltime is set for the job runs. 
     
 Step 2:  compile the results. 
 
    After all the jobs are run and off the queue you'll need to gaterh the results and create the web page and graph. 
    
    % cd ~/amber_cluster_bechmark/results_Jan-06-2017-15:27            (note it'll have the date of when you ran these tests)   
    % ./make_web.sh
    
    This will run the R script to generate the graph called make_graph.R. It'll also build this results in your home directory. 
    
    From the head node webserver access: 
    
    http://<head_node_server>/~<YOUR USERNAME>/amber_cluster_benchmark/index.html
    
    
  
