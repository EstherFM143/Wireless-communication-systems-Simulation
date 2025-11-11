% Version 25.6.2025
clear
MPSK_in_AWGN %Open the Simulink model

%Simulation parameters
M=8; %for 8PSK
SNR = (0:7); %Set the range of SNR values

%Format vectors BER and SER for faster processing in loop
BER = zeros(1, length(SNR)); 
SER = zeros(1, length(SNR)); 

%Simulation loop
for i = 1:length(SNR)
    
    EbN0 = SNR(i);
    sim MPSK_in_AWGN %Run the simulation
    BER(i) = BERsim.Data(length(BERsim.Data));
    SER(i) = SERsim.Data(length(SERsim.Data)); %Extract BER and SER values from simulation results
    
end

clear  BERsim SERsim  %Clear unneeded variables from workspace

%Results are in the workspace variables BER and SER