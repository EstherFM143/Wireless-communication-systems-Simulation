%Version 3.7.2025

clear
close all

codingexample %Open Simulink model
EbN0 = 2; %Set value of SNR (Value chosen to facilitate the task)

%Set coding parameters
cdlength = 7; %Set the length of the codeword
msglength = 4; %Assign length of message
parity_bits = cdlength - msglength; %Calculate the number of parity bits