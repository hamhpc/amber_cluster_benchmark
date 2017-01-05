  #!/bin/bash
    #
    # create results file
    #
    for MDINFO in `ls -1 mdinfo.*`
    do
      NPROC=`echo $MDINFO|awk -F. '{print$2}'`
      NS_PER_DAY=`cat $MDINFO | grep ns/day | tail -1 | awk '{print $4}'`
      echo "$NPROC,$NS_PER_DAY" >> results.csv
    done
