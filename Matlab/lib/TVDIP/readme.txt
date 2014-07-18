This ZIP file contains software for Matlab for performing discrete-time Total
Variation Denoising (TVD) described in [1] as the Fused Lasso Signal Approximator,
using a modified version of an interior-point primal-dual algorithm as originally
described by Kim et al. in 2009 [2]. It minimizes the following discrete convex
functional:

  E=(1/2)||y-x||_2^2+lambda*||Dx||_1,

over the variable x, given the input signal y, according to the regularization
parameter lambda > 0. D is the first difference matrix. This means that the
denoised solution consists of piecewise smooth regions with discontinuities that
separate them. The implementation uses hot-restarts from each value of lambda to
speed up convergence for subsequent values. The algorithm stopping tolerance and
maximum number of iterations can be set by the user to control the precision-
computation trade-off. Also included is a utility for calculating the maximum value
of lambda_max where, if lambda > lambda_max, the output x is just the mean of y.

(c) Max Little, 2010. If you use this code for your research, please cite [1].

References:

[1] M.A. Little, Nick S. Jones (2010) "Sparse Bayesian Step-Filtering for High-
Throughput Analysis of Molecular Machine Dynamics", in 2010 IEEE International
Conference on Acoustics, Speech and Signal Processing, 2010, ICASSP 2010
Proceedings.

[2] S.J. Kim, K. Koh, S. Boyd and D. Gorinevsky (2009), "L1 Trend Filtering", SIAM
Review, vol 51, no 2, pp. 339-360.

ZIP file contents:

tvdipdemo.m
 - An illustrative example of how to use the TVD solver.

tvdip.m
 - TVD interior-point solver. Typing 'help tvdip' gives instructions on how to 
   call this function.

tvdiplmax.m
 - Code to calculate the maximum useful value of lambda. Type 'help tvdiplmax'
   for more details.

This program is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later version.
Permission to use, copy, modify, and distribute this software for any purpose
without fee is hereby granted, provided that this entire notice is included in all
copies of any software which is or includes a copy or modification of this software
and in all copies of the supporting documentation for such software. This program
is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.
