#!/bin/bash
#SBATCH --job-name=Ag1SO2
#SBATCH --output=out
#SBATCH --error=err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --partition=a100
#SBATCH --time=23:59:00

module load matplotlib/3.4.3-foss-2021b
module load numba/0.54.1-foss-2021b
#### Variables
SCRIPT_PATH=$(realpath "$0")
script_dir=$(dirname "$SCRIPT_PATH")
script_dir="$SLURM_SUBMIT_DIR"
cd "$script_dir"  # Ensure we are in the correct directory
main_set_of_files_path="../main_scripts"  # Assuming Python scripts are in the same directory as this script

mkdir -p lammps_working
cp "${main_set_of_files_path}/lammps_sample_run.sh" "${script_dir}/lammps_working"
cp "${main_set_of_files_path}/sample_run.lmscr" "${script_dir}/lammps_working"

inff="$script_dir/Ag1SO2.in"
bsize=200
Niters=25
iexist=16
contin=16
sigma=0.02
Ttarget=500
charge_map="S:0.4702,O:-0.2351,Ag:0"
mass_map="S:32.065,O:15.999,Ag:107.8682"
sampling_method="md"
kB=0.00198720375145233
beta_sampling=$(awk "BEGIN {print 1/($kB * $Ttarget)}")
#hardcoded
datapath="$script_dir/data"
results_path="$script_dir/Results"

mkdir -p $eval_dir

for ((num=$contin; num<=$Niters; num++)); do
   
   if [ "$num" -eq 0 ]; then
	   sampling_method="perturbation"
      echo "Sampling method is set to perturbation"
   elif [ "$num" -le 9 ]; then
      sampling_method="mc"
   else
      echo "Sampling method is set to md"
      sampling_method="md"
   fi

   # Run Python scripts from the same directory as this Bash script
   python "$main_set_of_files_path/active_learning_scheme.py" \
          -n $num -dp $datapath -f $inff -b $bsize -s $sigma -exd $iexist \
          -m $sampling_method -cm "$charge_map" -mm "$mass_map" -t $Ttarget  -bs $beta_sampling

   if [ $? -ne 0 ]; then
       echo "Error: Fitting algorithm did not execute successfully."
       exit 1
   fi

   nextnum=$((num + 1))

   if (( nextnum > iexist )); then
       bash "$main_set_of_files_path/make_rundirs.sh" $nextnum $datapath
       rundir="${datapath}/R${nextnum}"
       cd "$rundir" || exit
       echo "Working in directory: $(pwd)"
       out=$(sbatch run.sh)
       jobid=${out##* }
       cd - || exit

       while true; do
           squeue -u $(whoami) --job $jobid > report_of_run
           line_count=$(wc -l < "report_of_run")
           if [[ $line_count -le 1 ]]; then
               break
           fi
           sleep 10
       done

       bash "$main_set_of_files_path/extract_logfiles.sh" $nextnum $datapath
       rm report_of_run
   else
       echo "Iteration $nextnum not performing DFT since data already exist"
   fi

       bash "$main_set_of_files_path/extract_logfiles.sh" $nextnum $datapath
   
   inff_eval="$results_path/$num/runned.in"
   
   python "$main_set_of_files_path/evaluate_predictions.py" \
          -n $nextnum -f $inff_eval -dp $datapath

   if [ $? -ne 0 ]; then
       echo "Error: Evaluating algorithm did not execute successfully."
       exit 1
   fi

   inff="$results_path/$num/runned.in"
   beta_sampling=$(head -n 1 beta_sampling_value)
done

