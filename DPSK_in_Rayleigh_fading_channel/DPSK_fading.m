% Version 1.7.2025
clear
close all  
clc

% Create Rayleigh fading channel object.

smplrte = 10000; %Set sample rate for Rayleigh channel, T = 1/smplrte
dpplrshft = 80; %Set Doppler shift value for Rayleigh channel

chan = comm.RayleighChannel ...
        ('SampleRate', smplrte, ...
         'MaximumDopplerShift', dpplrshft, ...
         'DopplerSpectrum', doppler('Gaussian'));


delay = chan.PathDelays;

% Generate data and apply fading channel.
M = 2; % DBPSK modulation order
hMod = comm.DBPSKModulator; % Create a DPSK modulator
hDemod = comm.DBPSKDemodulator; % Create a DPSK demodulator
tx = randi([0 M-1],2000000,1); % Random bit stream
dpskSig = hMod(tx);  % DPSK signal
fadedSig = step(chan,dpskSig); % Effect of channel


% Compute error rate for different values of SNR (Eb/No).
SNR = 0:2:50; % Range of SNR (Eb/No) values, in dB.
numSNR = length(SNR);
BER = zeros(1, numSNR);
for n = 1:numSNR
   rxSig = awgn(fadedSig,SNR(n)); % Add Gaussian noise.
   rx = hDemod(rxSig); % Demodulate.
   tx_trunc = tx(2:end-delay); rx_trunc = rx(delay+2:end); 
   % Truncate to account for channel delay and DPSK 1st bit.
   reset(hDemod);
   % Compute bit error rate, taking delay into account.
   [nErrors, BER(n)] = biterr(tx_trunc,rx_trunc); 
end


% Compute theoretical performance results, for comparison.
BERtheory = berfading(SNR,'dpsk',M,1);


% Plot BER results.
semilogy(SNR,BERtheory,'b-',SNR,BER,'rx');
legend('Theoretical BER','Empirical BER');
xlabel('Eb/No (dB)'); ylabel('BER');
title('Binary DPSK over Rayleigh Fading Channel');
set(gcf, "Theme", "light", "Position", [700, 300, 620, 400]);
grid on;