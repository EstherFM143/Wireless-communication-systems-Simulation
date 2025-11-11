Eb_No=[0 1 2 3 4 5 6 7];

BER=[0.1229	0.1014	0.0835	0.0642	0.0478	0.0333	0.0208	0.0124];
% BER values

SER=[0.3465	0.2936	0.2455	0.1904	0.1429	0.0997	0.0622	0.0373];
% SER values

figure(1) 
semilogy(Eb_No,BER,'--sr', Eb_No, SER,'-ob','LineWidth',2)
title('BER vs SER for 8PSK') 
xlabel('Eb/No [dB]') 
ylabel('BER or SER') 
grid on 
legend('BER','SER') 
set(gcf, "Theme", "light") % sets theme to light mode

