#include <functions/inputoutput.hpp>
#include <functions/softdongle.hpp>
#include <types/cml_consts.hpp>
#include <types/mpi_profile.hpp>
#include "modules/smooth_muscle_bench.hpp"
#include "modules/show_param_logs.hpp"

#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <mpi.h>

int main(int argc, char **argv)
{
  // enable real-time output in stdout
  setvbuf( stdout, NULL, _IONBF, 0 );
  
  // initialize MPI
  MPI_Init( &argc, &argv );
  MPI_Comm_size( MPI_COMM_WORLD, &MPI_Profile::size );
  MPI_Comm_rank( MPI_COMM_WORLD, &MPI_Profile::rank );
  MPI_Get_processor_name( MPI_Profile::host_name, &MPI_Profile::host_name_len );

  if( MPI_Profile::size > 1 ){
    printf("Make sure the CPU number is only 1!!\n");
    MPI_Abort(MPI_COMM_WORLD, 1);
  }

  // input parameter object
  Parameter *p_param;
  p_param = new Parameter();
  p_param->init();
  assign_params(&argc,argv,p_param);
  show_param_logs(p_param);

  int err_code = 0;
  double start_time = MPI_Wtime();
  smooth_muscle_bench(p_param);
  if(err_code != 0) MPI_Abort(MPI_COMM_WORLD, err_code);
  double end_time = MPI_Wtime();

  printf("Simulation finished at: %lf minutes.\n", (end_time-start_time)*cml::math::SECONDS_TO_MINUTES);

  delete p_param;

  MPI_Finalize();
  if(err_code != 0){
    fprintf(stderr, "Something failed with the application!!\n");
  }

  return 0;
}
