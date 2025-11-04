# Set output terminal and filename for the plot
set terminal pngcairo size 800,600
set output 'results/Vm_Smooth_Muscle.png'

# Set plot title and axis labels
set title 'Vm Tong et al. Smooth Muscle Model'
set xlabel 'Time (ms)'
set ylabel 'Vm (millivolt)'
set datafile separator ","

# Set line style
set style line 1 linecolor rgb "red" linewidth 4
set style line 2 linecolor rgb "blue" lt 0 linewidth 4

# Plot data from the first file
# 'file1.dat' is the filename
# using 1:2 means use column 1 for x and column 2 for y
# with linespoints plots lines connecting points
# title 'Dataset 1' sets the legend entry for this plot
plot 'results/time_series_Tong.csv' using 1:2 with lines linestyle 1 title 'Vm'
