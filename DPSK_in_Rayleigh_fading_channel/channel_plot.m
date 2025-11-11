% Version 27.6.2025

clear
close all  

%Insert the doppler shift value that you have calculated into the
%appropriate variable

smplrte = 10000;
dpplrshft = 80;
% This matlab code plot power of faded signal, versus sample number.

% If you like, you can take lines from plot_help to decorate plots.

chanray = comm.RayleighChannel ...
        ('SampleRate', smplrte, ...
         'MaximumDopplerShift', dpplrshft, ...
         'DopplerSpectrum', doppler('Jakes'));


sig = ones(4000,1); % Signal
y = step(chanray,sig); % Pass signal through channel.

% Plot power of faded signal, versus sample number.
plot(20*log10(abs(y)))
set(gcf, "Theme", "light", "Position", [700, 300, 620, 400]);
grid on