% (modified to add 1x4 MRC curve for direct comparison with 1x4 EGC)
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
BER14_MRC = BER11;   % NEW: store BER for 1x4 MRC to compare with 1x4 EGC

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

    %  Compute both EGC and MRC for M = 4 so we can directly compare EGC vs MRC 
    % with the same number of receive antennas.
    BER14_EGC(idx) = egc1m(4, frmLen, numPackets, EbNo(idx));
    BER14_MRC(idx) = mrc1m(4, frmLen, numPackets, EbNo(idx)); % NEW

    % Plot results
    semilogy(EbNo(1:idx), BER11(1:idx), 'mo', ...
             EbNo(1:idx), BER21(1:idx), 'gx', ...
             EbNo(1:idx), BERthy2(1:idx), '-ro', ...
             EbNo(1:idx), BER12(1:idx), 'bs', ...
             EbNo(1:idx), BER14_EGC(1:idx), '-.w', ...
             EbNo(1:idx), BER14_MRC(1:idx), 'c--d'); % NEW curve
    drawnow;
end  % end of for loop for EbNo


% safe fitting & replot, Encountered some errors, used AI to resolve it and
% develop the function below
% Helper: fit BER safely when zeros are present
function fitVec = safeBerfit(EbNoVec, BERvec)
    % Keep only positive (non-zero) BER entries for berfit
    nz = BERvec > 0;
    if sum(nz) < 2
        % Not enough points to fit; just return the original (or tiny eps)
        fitVec = max(BERvec, eps);
        return;
    end
    % Call berfit on the non-zero subset
    EbNo_nz = EbNoVec(nz);
    BER_nz = BERvec(nz);
    fit_nz = berfit(EbNo_nz, BER_nz);      % returns fit values at EbNo_nz
    % Interpolate the fit onto the full EbNoVec grid
    % Use log-domain interpolation to keep exponential behaviour
    fitLog = interp1(EbNo_nz, log10(fit_nz), EbNoVec, 'pchip', 'extrap');
    fitVec = 10.^fitLog;
end

% Compute fitted curves safely
fitBER11 = safeBerfit(EbNo, BER11);
fitBER21 = safeBerfit(EbNo, BER21);
fitBER12 = safeBerfit(EbNo, BER12);
fitBER14_EGC = safeBerfit(EbNo, BER14_EGC);
fitBER14_MRC = safeBerfit(EbNo, BER14_MRC);

% Replot fitted curves (all vectors now same length as EbNo)
semilogy(EbNo, fitBER11, 'mo', EbNo, fitBER21, 'gx', EbNo, fitBER12, 'bs', ...
         EbNo, fitBER14_EGC, '-.w', EbNo, fitBER14_MRC, 'c--d');
legend('No Diversity (1Tx, 1Rx)', 'Alamouti (2Tx, 1Rx)',...
       'Theoretical 2nd-Order Diversity',...
       'Maximal-Ratio Combining (1Tx, 2Rx)',...
       'Equal Gain Combining (1Tx, 4Rx)',...
       'Maximal-Ratio Combining (1Tx, 4Rx)');
