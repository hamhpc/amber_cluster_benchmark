NPROC=`pwd | awk -F/ '{print $6}'|awk -F- '{print $2}'`
NS_PER_DAY=`cat mdinfo | grep ns/day | tail -1 | awk '{print $4}'`
echo "$NPROC,$NS_PER_DAY" >> ../../results.csv

