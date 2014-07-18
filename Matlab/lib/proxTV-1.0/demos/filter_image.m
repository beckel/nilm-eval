%%% Example script showing how to perform a 2D Total-Variation filtering with proxTV

clear all
close all

% Load image
X = rgb2gray(imread('QRsample.png'));

% Introduce noise
noiseLevel = 0.2;
N = double(imnoise(X,'gaussian',0,noiseLevel));

% Filter using 2D TV-L1
lambda=50;
disp('Filtering image...');
tic;
F = prox_TVLp(N,lambda,1);
toc;

% Plot results
figure();
subplot(1,3,1);
imshow(X);
title('Original');
subplot(1,3,2);
imshow(N,[]);
title('Noisy');
subplot(1,3,3);
imshow(F,[]);
title('Filtered');



