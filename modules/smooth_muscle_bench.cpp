#include "smooth_muscle_bench.hpp"

#include <types/cellmodels/Tong_Choi_Kharche_Holden_Zhang_Taggart_2011.hpp>

#include <types/solvers/forwardeulersolver.hpp>

#include <functions/inputoutput.hpp>
#include <functions/helper_cvode.hpp>
#include <functions/helper_math.hpp>
#include <types/cml_consts.hpp>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>

#include <cvode/cvode.h>



int smooth_muscle_bench(const Parameter *p_param)
{
  // simulation parameters.
  // Assigned to the constant variables for
  // the sake of simplicity.
  const double cycle_length = p_param->cycle_length;
  const short number_pacing = p_param->number_pacing;
  short number_pacing_write = p_param->number_pacing_write;
  const char *user_name = p_param->user_name;
  const double time_step_min = p_param->time_step_min;
  const double time_step_max = p_param->time_step_max;
  const double writing_step = p_param->writing_step;
  const char *solver_type = p_param->solver_type;
  const double stimulus_duration = p_param->stimulus_duration;
  const double stimulus_amplitude_scale = p_param->stimulus_amplitude_scale;
  const double gna_scale = p_param->gna_scale;

  if(time_step_min > writing_step){
    mpi_printf(cml::commons::MASTER_NODE,"%s\n%s\n",
    "WARNING!!! The writing_step values is smaller than the timestep!",
    "Simulation still run, but the time series will use time_step_min as writing step.");
  }
  else if(number_pacing_write >= number_pacing){
    number_pacing_write = number_pacing;
    mpi_printf(cml::commons::MASTER_NODE,"%s\n%s\n",
    "WARNING!!! The number_pacing_write is larger than the number_pacing",
    "All period will be printed");
  }

  // this is the cellmodel initialization part
  Cellmodel *p_cell;
  short cell_type;
  const char *cell_model = p_param->cell_model;
  if( strstr(cell_model,"endo") != NULL ) cell_type = 0;
  else if( strstr(cell_model,"epi") != NULL ) cell_type = 1;
  else if( strstr(cell_model,"myo") != NULL ) cell_type = 2;
  mpi_printf(cml::commons::MASTER_NODE,"Using %s cell model\n", cell_model);

  p_cell = new Tong_Choi_Kharche_Holden_Zhang_Taggart_2011();
  p_cell->initConsts();
  
  p_cell->CONSTANTS[gna] *= gna_scale;

  // variables for I/O
  char buffer[255];
  FILE* fp_time_series;
  FILE* fp_last_states;
  FILE* fp_qnet;
  snprintf(buffer, sizeof(buffer), "%s/time_series_%s.csv", cml::commons::RESULT_FOLDER, cell_model);
  fp_time_series = fopen( buffer, "w" );
  if(fp_time_series == NULL ){
    mpi_fprintf(cml::commons::MASTER_NODE, stderr,"Cannot create file %s. Make sure the directory is existed!!!\n",buffer);
    return 1;
  }
  snprintf(buffer, sizeof(buffer), "%s/last_states_%hdpaces_%s.dat", cml::commons::RESULT_FOLDER, number_pacing, cell_model);
  fp_last_states = fopen( buffer, "w" );
  if(fp_last_states == NULL ){
    mpi_fprintf(cml::commons::MASTER_NODE, stderr,"Cannot create file %s. Make sure the directory is existed!!!\n",buffer);
    return 1;
  }
  
  fprintf(fp_time_series,"%s,%s,%s,%s\n",
      "Time(ms)","v(mV)","dv/dt(mV/ms)","Ist(mV)");

  double time_step = time_step_min;
  double tcurr = 0.;
  double tmax = number_pacing*cycle_length;
  double time_point = 25.0;
  short pace_count = 0;
  short last_print_pace = number_pacing - number_pacing_write;
  double start_time = cycle_length * last_print_pace;
  double next_output_time = start_time;
  double tprint = 0.;

  // CVode solver.
  CVodeSolverData *p_cvode;
  int cvode_retval;
  if(strncasecmp(solver_type, "Euler", sizeof(solver_type)) == 0){
    mpi_printf(0, "Using Euler Solver.\n");
  }
  else if( strncasecmp(solver_type, "CVode", sizeof(solver_type)) == 0){
    mpi_printf(0, "Using CVode Solver.\n");
    p_cvode = new CVodeSolverData();  
    init_cvode(p_cvode, p_cell, tcurr);
    set_dt_cvode(p_cvode, tcurr, time_point, cycle_length,
    time_step_min, time_step_max, &time_step);
  }
  else{
    mpi_fprintf(0, stderr, "Solver type %s is undefined! Please choose the available solver types from the manual!\n", solver_type);
    return 1;
  }

  while(tcurr < tmax){ // begin of computation loop
    // compute and solving part
    // and execute the function
    // when reaching end of the cycle.
    //
    // Different solver_type has different
    // method of calling computeRates().
    if(strncasecmp(solver_type, "Euler", sizeof(solver_type)) == 0){
      p_cell->computeRates(tcurr,
          p_cell->CONSTANTS,
          p_cell->RATES,
          p_cell->STATES,
          p_cell->ALGEBRAIC);
      solveEuler(time_step_min, p_cell);
      // increase the time based on the time_step.
      tcurr += time_step_min;
    }
    else if(strncasecmp(solver_type, "CVode", sizeof(solver_type)) == 0){
      cvode_retval = solve_cvode(p_cvode, p_cell, tcurr+time_step, &tcurr);
      if( cvode_retval != 0 ){
        return 1;
      }
      set_dt_cvode(p_cvode, tcurr, time_point, cycle_length,
      time_step_min, time_step_max, &time_step);
    }

    if(floor(tcurr/cycle_length) != pace_count){
      end_of_cycle_funct(&pace_count);
      //mpi_printf(0,"Entering pace %hd at %lf msec.\n", pace_count, tcurr);
    }


    // output part.
    if( tcurr >= next_output_time - cml::math::EPSILON ){
      // relative time since writing began
      tprint = next_output_time - start_time;
      snprintf(buffer, sizeof(buffer),
          "%.4lf,%.4lf,%.4lf\n",
          p_cell->STATES[v],p_cell->RATES[v],p_cell->ALGEBRAIC[Ist]);
      fprintf(fp_time_series, "%.4lf,%s", tprint, buffer);
      // schedule next output
      next_output_time += writing_step;
    }
   
  } // end of computation loop
 
  // writing last states to be used for
  // initial condition to the drug simulation.
  short idx;
  for(idx = 0; idx < p_cell->states_size; idx++){
    fprintf(fp_last_states, "%.16lf\n", p_cell->STATES[idx]);
  }
 
  // cleaning, cleaning....
  if( strncasecmp(solver_type, "CVode", sizeof(solver_type)) == 0 ){
    clean_cvode(p_cvode);
    delete p_cvode;
  }
  fclose(fp_last_states);
  fclose(fp_time_series);
  delete p_cell;
  
  return 0;
}

void end_of_cycle_funct(short *pace_count)
{
  *pace_count += 1;
}
