#!/bin/bash

#
# Create the results of the benchmark. 
#

# call a script to massage permission so the webpage will work. 
# chmod home directory o+rx and make ${HOME}/public_html with 755 permissions
#/usr/local/global/bin/enable_web.sh

# make the webpage in the users home directory. 

mkdir -p ~/public_html/amber_cluster_benchmark/img
touch ~/public_html/amber_cluster_benchmark/index.html

# 

# make the png graph
cd ~/amber_cluster_benchmark/results_*
make_graph.R
cp results.png ~/public_html/amber_cluster_benchmark/img/

#
# set permissions
#
chmod -R 755 ~/public_html/amber_cluster_benchmark
