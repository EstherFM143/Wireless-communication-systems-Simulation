
Eb_No=[0 1 2 3 4 5 6 7];

BER=[0.0746 0.0545 0.0366 0.0226 0.0124 0.0060 0.0024 0.0008];
% Simulated BER values

bertool_result=[0.07865 0.056282 0.037506 0.022878 0.012501 0.0059539 0.0023883 0.00077267];
%Theoretical BER values

figure(1) 
semilogy(Eb_No,BER,'--sr', Eb_No, bertool_result,'-ob','LineWidth',2)
title('Simulated vs Theoretical BER') 
xlabel('Eb/No [dB]') 
ylabel('BER') 
grid on 
legend('Simulated BER','Theoretical BER') 
set(gcf, "Theme", "light") % sets theme to light mode

