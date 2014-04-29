#!/bin/bash
#
# Author: Mark Gottscho
# mgottscho@ucla.edu

ARGC=$# # Get number of arguments excluding arg0 (the script itself). Check for help message condition.
if [[ "$ARGC" != 2 ]]; then # Bad number of arguments. 
	echo "Author: Mark Gottscho"
	echo "mgottscho@ucla.edu"
	echo ""
	echo "USAGE: ./submit_dpcs_gem5_jobs.sh <CONFIG_ID> <RUN_NUMBER>"
	echo "NOTE: The following files must exist in the current working directory:"
	echo "	run_dpcs_gem5_alpha_benchmark.sh"
	echo "	gem5-config-subscript-<CONFIG_ID>.sh" 
	echo "	gem5params-L1-<CONFIG_ID>.csv"
	echo "	gem5params-L2-<CONFIG_ID>.csv"
	echo ""
	echo "For example:"
	echo "	./submit_dpcs_gem5_jobs.sh foo 1"
	echo "	would run gem5 configuration \"foo\" and attach the run number of 1 to all output files."
	echo "	It would need the following files in the current working directory:"
	echo "		run_dpcs_gem5_alpha_benchmark.sh"
	echo "		gem5-config-subscript-foo.sh"
	echo "		gem5params-L1-foo.csv"
	echo "		gem5params-L2-foo.csv"
	exit
fi

# Get the arguments.
CONFIG_ID=$1		# String identifier for the system configuration, e.g. "foo" sans quotes
RUN_NUMBER=$2		# Run number string, e.g. "3" sans quotes

########################## FEEL FREE TO CHANGE THESE OPTIONS ##################################
BENCHMARKS="perlbench bzip2 gcc bwaves zeusmp gromacs leslie3d namd gobmk povray sjeng GemsFDTD h264ref lbm astar sphinx3"		# String of SPEC CPU2006 benchmark names to run, delimited by spaces.
GEM5_CONFIG=$PWD/gem5-config-subscript-$CONFIG_ID.sh	# Full path to the gem5 config bash subscript
GEM5_L1_CONFIG=$PWD/gem5params-L1-$CONFIG_ID.csv 		# Full path to the L1 cache configuration CSV
GEM5_L2_CONFIG=$PWD/gem5params-L2-$CONFIG_ID.csv 		# Full path to the L2 cache configuration CSV

# qsub options used:
# -V: export environment variables from this calling script to each job
# -N: name the job. I made these so that each job will be uniquely identified by its benchmark running as well as the output file string ID
# -l: resource allocation flags for maximum time requested as well as maximum memory requested.
# -M: cluster username(s) to email with updates on job status
# -m: mailing rules for job status.
MAX_TIME_PER_RUN=08:00:00 	# Maximum time of each script that will be invoked, HH:MM:SS. If this is exceeded, job will be killed.
MAX_MEM_PER_RUN=3072M 		# Maximum memory needed per script that will be invoked. If this is exceeded, job will be killed.
MAILING_LIST=mgottsch 		# List of users to email with status updates, separated by commas
###############################################################################################

# Create strings to identify each run group as a combination of simulation configuration, cache DPCS scenario, and run number.
# For example, one might have the following runs for benchmark perlbench after running this script with CONFIG_ID "foo" and RUN_NUMBER 3:
# foo_baseline_3
# foo_static_3
# foo_dynamic_3
BASELINE_STRING=$CONFIG_ID\_baseline_$RUN_NUMBER
STATIC_STRING=$CONFIG_ID\_static_$RUN_NUMBER
DYNAMIC_STRING=$CONFIG_ID\_dynamic_$RUN_NUMBER

# Submit all the benchmarks!
echo "Submitting dpcs-gem5 jobs..."
ITER=1
for BENCHMARK in $BENCHMARKS; do
	echo "...$BENCHMARK (#$ITER)..."
	qsub -V -N "dpcs-gem5-$BASELINE_STRING-$BENCHMARK" -l h_rt=$MAX_TIME_PER_RUN,h_data=$MAX_MEM_PER_RUN -M $MAILING_LIST -m bea ./run_dpcs_gem5_alpha_benchmark.sh $BENCHMARK ref vanilla vanilla $GEM5_CONFIG $GEM5_L1_CONFIG $GEM5_L2_CONFIG no $BASELINE_STRING
	qsub -V -N "dpcs-gem5-$STATIC_STRING-$BENCHMARK" -l h_rt=$MAX_TIME_PER_RUN,h_data=$MAX_MEM_PER_RUN -M $MAILING_LIST -m bea ./run_dpcs_gem5_alpha_benchmark.sh $BENCHMARK ref static static $GEM5_CONFIG $GEM5_L1_CONFIG $GEM5_L2_CONFIG no $STATIC_STRING
	qsub -V -N "dpcs-gem5-$DYNAMIC_STRING-$BENCHMARK" -l h_rt=$MAX_TIME_PER_RUN,h_data=$MAX_MEM_PER_RUN -M $MAILING_LIST -m bea ./run_dpcs_gem5_alpha_benchmark.sh $BENCHMARK ref dynamic dynamic $GEM5_CONFIG $GEM5_L1_CONFIG $GEM5_L2_CONFIG no $DYNAMIC_STRING
	ITER=$((i+1))
done

echo "Done submitting dpcs-gem5 jobs."
echo "Use qstat to track job status and qdel to kill jobs. Job output can be found in your home directory."
