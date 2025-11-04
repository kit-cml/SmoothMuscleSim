#PBS -N epsim_pbs_job
#PBS -l nodes=1:ppn=1
#PBS -l walltime=20000:00:00
#PBS -e stderr.log
#PBS -o stdout.log
#Specific the shell types
#PBS -S /bin/bash
#Specific the queue type
#PBS -q dque

cd $PBS_O_WORKDIR
NPROCS=`wc -l < $PBS_NODEFILE`
echo This job has allocated $NPROCS nodes

# Use this to export the library path
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/prog/sundial/lib64:/usr/local/lib64:/usr/lib64
echo $LD_LIBRARY_PATH
export PATH=$PATH
echo $PATH

# to grab cell_model value from parameter file (thanks, ChatGPT).
# grep "^user_name": looks for the line starting with user_name
# cut -d'=' -f2: gets the right-hand side of =
# sed 's/\/\/.*//': removes any inline comment starting with //
# xargs: trims leading and trailing whitespace
CELL_MODEL=$(grep "^cell_model" param.txt | cut -d'=' -f2 | cut -d'/' -f1 | cut -d'/' -f1 | sed 's/\/\/.*//' | xargs)
USER_NAME=$(grep "^user_name" param.txt | cut -d'=' -f2 | cut -d'/' -f1 | cut -d'/' -f1 | sed 's/\/\/.*//' | xargs)

RESULT_FOLDER="./results"


# choose the binary based on the value of cell_model
if [[ $CELL_MODEL == *"CiPAORdv1.0"* ]]; then
  BINARY_FILE=epsim_CiPAORdv1.0
elif [[ $CELL_MODEL == *"ToR-ORd"* ]]; then
  BINARY_FILE=epsim_ToR-ORd
elif [[ $CELL_MODEL == *"ToR-ORd-dynCl"* ]]; then
  BINARY_FILE=epsim_ToR-ORd-dynCl
elif [[ $CELL_MODEL == *"ORd-static-Brugada-Dongguk"* ]]; then
  BINARY_FILE=epsim_ORd-static-Brugada-Dongguk
elif [[ $CELL_MODEL == *"ORd-static"* ]]; then
  BINARY_FILE=epsim_ORd-static
else
  echo "The cell model ${CELL_MODEL} is not specified to any simulations!!"
  exit 1
fi

rm -rf *.log results logfile
mkdir results
mpiexec -machinefile $PBS_NODEFILE -np $NPROCS ~/marcell/MetaHeart/EPSim/bin/$BINARY_FILE -input_deck param.txt > logfile
