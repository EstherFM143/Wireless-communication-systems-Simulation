% Version 1.7.2025
clear
close all  
clc

frmLen = 120;       % frame length
numPackets = 10000; % number of packets, 
                    % if simulation time is too long => 1000
EbNo = 2:2:22;      % Eb/No varying to 22 dB
N = 2;              % maximum number of Tx antennas
M = 2;              % maximum number of Rx antennas
P = 2;				% modulation order

% Create a local random stream to be used by random number generators for
% repeatability.
hStr = RandStream('mt19937ar', 'Seed', 687122);


% Pre-allocate variables for speed
tx2 = zeros(frmLen, N); H  = zeros(frmLen, N, M);
r21 = zeros(frmLen, 1); r12  = zeros(frmLen, 2);
z21 = zeros(frmLen, 1); z21_1 = zeros(frmLen/N, 1); z21_2 = z21_1;
z12 = zeros(frmLen, M);
error11 = zeros(1, numPackets); BER11 = zeros(1, length(EbNo));
error21 = error11; BER21 = BER11; 
error12 = error11; BER12 = BER11; BERthy2 = BER11; BER14_EGC = BER11;
% Set up a figure for visualizing BER results
h = gcf; grid on; hold on;
set(gca, 'yscale', 'log', 'xlim', [EbNo(1), EbNo(end)], 'ylim', [1e-6 1]);
xlabel('Eb/No (dB)'); ylabel('BER'); set(h,'NumberTitle','off');
set(h, 'renderer', 'zbuffer'); set(h,'Name','Transmit vs. Receive Diversity');
title('Transmit vs. Receive Diversity');

% Loop over several EbNo points
for idx = 1:length(EbNo)
    % Loop over the number of packets
    for packetIdx = 1:numPackets
        data = randi(hStr, [0 P-1], frmLen, 1);   % data vector per user
                                                  % per channel
        tx = pskmod(data, P);                     % BPSK modulation

        % Alamouti Space-Time Block Encoder, G2, full rate
        %   G2 = [s1 s2; -s2* s1*]
        s1 = tx(1:N:end); s2 = tx(2:N:end);
        tx2(1:N:end, :) = [s1 s2];
        tx2(2:N:end, :) = [-conj(s2) conj(s1)];

        % Create the Rayleigh distributed channel response matrix
        %   for two transmit and two receive antennas
        H(1:N:end, :, :) = (randn(hStr, frmLen/2, N, M) + ...
                                1i*randn(hStr, frmLen/2, N, M))/sqrt(2);
        %   assume held constant for 2 symbol periods
        H(2:N:end, :, :) = H(1:N:end, :, :);

        % Received signals
        %   for uncoded 1x1 system
        r11 = awgn(H(:, 1, 1).*tx, EbNo(idx), 0, hStr);

        %   for G2-coded 2x1 system - with normalized Tx power, i.e., the
        %	total transmitted power is assumed constant
        r21 = awgn(sum(H(:, :, 1).*tx2, 2)/sqrt(N), EbNo(idx), 0, hStr);

        %   for Maximal-ratio combined 1x2 system
        for i = 1:M
            r12(:, i) = awgn(H(:, 1, i).*tx, EbNo(idx), 0, hStr);
        end

        % Front-end Combiners - assume channel response known at Rx
        %   for G2-coded 2x1 system
        hidx = 1:N:length(H);
        z21_1 = r21(1:N:end).* conj(H(hidx, 1, 1)) + ...
                conj(r21(2:N:end)).* H(hidx, 2, 1);

        z21_2 = r21(1:N:end).* conj(H(hidx, 2, 1)) - ...
                conj(r21(2:N:end)).* H(hidx, 1, 1);
        z21(1:N:end) = z21_1; z21(2:N:end) = z21_2;

        %   for Maximal-ratio combined 1x2 system
        for i = 1:M
            z12(:, i) = r12(:, i).* conj(H(:, 1, i));
        end

       
        % ML Detector (minimum Euclidean distance)
        demod11 = pskdemod(r11.*conj(H(:, 1, 1)), P);
        demod21 = pskdemod(z21, P);
        demod12 = pskdemod(sum(z12, 2), P);

        % Determine errors
        error11(packetIdx) = biterr(demod11, data);
        error21(packetIdx) = biterr(demod21, data);
        error12(packetIdx) = biterr(demod12, data);
    end % end of FOR loop for numPackets

    % Calculate BER for current idx
    %   for uncoded 1x1 system
    BER11(idx) = sum(error11)/(numPackets*frmLen);

    %   for G2 coded 2x1 system
    BER21(idx) = sum(error21)/(numPackets*frmLen);

    %   for Equal Gain combined 1x2 system
    BER12(idx) = sum(error12)/(numPackets*frmLen);

    %   for theoretical performance of second-order diversity
    BERthy2(idx) = berfading(EbNo(idx), 'psk', 2, 2);
    
    %   Combining techniques for 1xM antenna configurations
    %   functions mrc1m(M, frLen, numPackets, EbNo) and
    %             egc1m(M, frLen, numPackets, EbNo) are used (2025)
    BER14_EGC(idx)=egc1m(4,120,10000,EbNo(idx));

    % Plot results
    semilogy(EbNo(1:idx), BER11(1:idx), 'mo', ...
             EbNo(1:idx), BER21(1:idx), 'gx', ...
             EbNo(1:idx), BERthy2(1:idx), '-ro', ...
             EbNo(1:idx), BER12(1:idx), 'bs', ...
             EbNo(1:idx), BER14_EGC(1:idx), '-.kx');
    drawnow;
end  % end of for loop for EbNo


% Perform curve fitting and replot the results
fitBER11 = berfit(EbNo, BER11);
fitBER21 = berfit(EbNo, BER21);
fitBER12 = berfit(EbNo, BER12);

semilogy(EbNo, fitBER11, 'm', EbNo, fitBER21, 'g', EbNo, fitBER12, 'b');
legend('No Diversity (1Tx, 1Rx)', 'Alamouti (2Tx, 1Rx)',...
           'Theoretical 2nd-Order Diversity',...
           'Maximal-Ratio Combining (1Tx, 2Rx)',...
           'Equal Gain Combining (1Tx, 4Rx)');
set(gcf, "Theme", "light", "Position", [700, 300, 620, 400]);
hold off;