% Version 23.6.2025
clear
close 

%Simulation parameters
ht = 31.6;  % height of transmitting antenna
hr = 3;     % height of receiving antenna
f = 650e6;  % frequency
c = 3e8;    % approximate value of the speed of light
wl = c/f;   % wavelength
Pt = 1; d = 1:1e5; Gl = 1; Gr = 1; R = -1;

Pr_los = zeros(1, length(d));
dphi = zeros(1, length(d));
Pr = zeros(1, length(d)); %Format vectors for faster loop processing

for i = 1:length(d)
    
    %Calculate the received power per unit of distance using the narrowband
    %transmission equation, Goldsmith (2.12)   
    
    l = sqrt((ht - hr)^2 + d(i)^2);
    r = sqrt((ht + hr)^2 + d(i)^2);
    dphi(i) = (2 * pi * (r-l)) / wl;
    coeff = Pt * (wl / (4 * pi))^2;
    LOS = sqrt(Gl) / l;
    reflected = (R * sqrt(Gr) * exp(-1j * dphi(i))) / r;
    Pr(i) = coeff * (abs(LOS + reflected))^2;
   

end

%Plotting spaghetti

hold on
plot(log10(d), 10*log10(Pr) - 10*log10(Pr(1)))
hold on 
xline(log10(ht), '--green')
xline(log10(4*ht*hr/wl), '--magenta')
legend('Two-ray model', 'Sections 1 and 2', 'Sections 2 and 3')
grid on
grid minor
ylabel('Received power 10log(Pr)')
xlabel('Log-distance log(d)')
set(gcf, "Theme", "light", "Position", [700, 300, 620, 400]);