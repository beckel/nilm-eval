%%% Example script showing how to perform a Total-Variation filtering with proxTV

clear all
close all

%%% TV-L1 filtering

% Generate impulse (blocky) signal
N = 1000;
s = zeros(N,1);
s(N/4:N/2) = 1;
s(N/2:3*N/4) = -1;
s(3*N/4:end-N/8) = 2;

% Introduce noise
n = s + 0.5*randn(size(s));

% Filter using TV-L1
lambda=20;
disp('Filtering signal...');
tic;
f = prox_TVLp(n,lambda,1);
toc;

% Plot results
figure();
subplot(3,1,1);
plot(s);
title('Original');
grid();
subplot(3,1,2);
plot(n);
title('Noisy');
grid();
subplot(3,1,3);
plot(f);
title('Filtered');
grid();

%%% TV-L2 filtering

% Generate sinusoidal signal
N = 1000;
s = sin((1:N)./10) + sin((1:N)./100);

% Introduce noise
n = s + 0.5*randn(size(s));

% Filter using TV-L2
lambda=10;
disp('Filtering signal...');
tic;
f = prox_TVLp(n,lambda,2);
toc;

% Plot results
figure();
subplot(3,1,1);
plot(s);
title('Original');
grid();
subplot(3,1,2);
plot(n);
title('Noisy');
grid();
subplot(3,1,3);
plot(f);
title('Filtered');
grid();


