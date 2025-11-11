% Version 24.6.2025
clear 
close all

%Open siteviewer and load 3D map of Oulu city center, data exported from
%openstreetmap.org

viewer = siteviewer("Buildings", "oulu.osm", "Basemap", "topographic");

%%
%Set location and parameters of transmitter antenna

transmitter = txsite("Latitude", 65.012090, ...
    "Longitude", 25.465188, ...
    "Antennaheight", 10, ...
    "TransmitterPower", 10, ...
    "TransmitterFrequency", 5e9);
show(transmitter)

%%
%Set parameters for ray tracer, 0 reflections for line of sight

raytracer = propagationModel("raytracing", ...
    "Method", "sbr", ...
    "MaxNumReflections", 0, ...
    "BuildingsMaterial","concrete", ...
    "TerrainMaterial","concrete");

%Calculate line of sight coverage for the transmitter antenna restricted to
%200 meters for calculation speed

coverage(transmitter,raytracer, ...
    "SignalStrengths",-120:-30, ...
    "MaxRange",200, ...
    "Resolution",3, ...
    "Transparency",0.6)
%%
%Set location and parameters of receiver antenna outside line of sight

receiver = rxsite("Latitude", 65.011658, ...
    "Longitude", 25.466113, ...
    "Antennaheight", 2);
show(receiver)
%%
%Use ray tracer to calculate reflection path and received power of signal

raytracer.MaxNumReflections = 3;
raytrace(transmitter, receiver, raytracer);
raytrace(transmitter, receiver, raytracer);
pr = sigstrength(receiver, transmitter, raytracer);
disp("Non-LOS received power: " + pr + " dBm")
%%
%Set new receiver in line of sight

clearMap(viewer)

show(transmitter)
receiver = rxsite("Latitude", 65.011800, ...
    "Longitude", 25.466226, ...
    "Antennaheight", 2);
show(receiver)
%%
%Raytrace and calculate received power

clearMap(viewer)

raytracer.MaxNumReflections = 0;
raytrace(transmitter, receiver, raytracer)

pr = sigstrength(receiver, transmitter, raytracer);
disp("LOS received power: " + pr + " dBm")
%%
%Set maximum number of reflections from 1 to 5 in a loop, raytrace and 
%calculate received power again

maxReflections = 5;

for numReflections = 1:maxReflections
    clearMap(viewer)
    show(transmitter)
    show(receiver)
    raytracer.MaxNumReflections = numReflections;
    raytrace(transmitter, receiver, raytracer)
    pr = sigstrength(receiver, transmitter, raytracer);
    disp("Max " + numReflections + " refl. received power: " + pr + " dBm")
end