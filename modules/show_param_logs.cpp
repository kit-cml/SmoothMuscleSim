#include "show_param_logs.hpp"

#include <functions/inputoutput.hpp>

void show_param_logs(const Parameter *p_param)
{
  mpi_printf( 0, "%s -- %s\n", "user_name", p_param->user_name);
  mpi_printf( 0, "%s -- %s\n", "cell_model", p_param->cell_model);
  mpi_printf( 0, "%s -- %s\n", "solver_type", p_param->solver_type);
  mpi_printf( 0, "%s -- %lf\n", "cycle_length", p_param->cycle_length);
  mpi_printf( 0, "%s -- %hd\n", "number_pacing", p_param->number_pacing);
  mpi_printf( 0, "%s -- %hd\n", "number_pacing_write", p_param->number_pacing_write);
  mpi_printf( 0, "%s -- %lf\n", "time_step_min", p_param->time_step_min);
  mpi_printf( 0, "%s -- %lf\n", "time_step_max", p_param->time_step_max);
  mpi_printf( 0, "%s -- %lf\n", "writing_step", p_param->writing_step);
  mpi_printf( 0, "%s -- %lf\n", "stimulus_duration", p_param->stimulus_duration);
  mpi_printf( 0, "%s -- %lf\n", "stimulus_amplitude_scale", p_param->stimulus_amplitude_scale);
  mpi_printf( 0, "%s -- %lf\n", "gna_scale", p_param->gna_scale);
}
