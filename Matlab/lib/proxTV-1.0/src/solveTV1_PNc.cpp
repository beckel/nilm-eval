#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <limits.h>
#include "mex.h"
#include "TVopt.h"

/* solveTV1_PNc.cpp

   Solves the TV-L1 proximity problem by applying a Projected Newton algorithm.

   Parameters:
     - 0: reference signal y.
     - 1: lambda penalty.
     - [2]: sigma parameter for sufficient descent. A default value is used if not provided.
     
   Outputs:
     - 0: primal solution x.
     - 1: array with optimizer information:
        + [0]: number of iterations run.
        + [1]: dual gap.
        + [2]: mean number of stepsize rescalings per iteration.
*/
void mexFunction(int nlhs, mxArray *plhs[ ],int nrhs, const mxArray *prhs[ ]) {
    double *x,*y,*info=NULL;
    double lambda,sigma;
    int M,N,nn,i;

    /* Create output arrays */
    M = mxGetM(prhs[0]);
    N = mxGetN(prhs[0]);
    nn = (M > N) ? M : N;
    if(nlhs >= 1){
        plhs[0] = mxCreateDoubleMatrix(nn,1,mxREAL);
        x = mxGetPr(plhs[0]);
    }
    else x = (double*)malloc(sizeof(double)*nn);
    if(nlhs >= 2){
        plhs[1] = mxCreateDoubleMatrix(N_INFO,1,mxREAL);
        info = mxGetPr(plhs[1]);
    }

    /* Retrieve input data */
    y = mxGetPr(prhs[0]);
    lambda = mxGetScalar(prhs[1]);
    if(nrhs >= 3) sigma = mxGetScalar(prhs[2]);
    else sigma = SIGMA;
    
    /* Run Projected Newton */
    PN_TV1(y,lambda,x,info,nn,sigma,NULL);
    
    /* Free resources */
    if(!nlhs) free(x);
    
    return;
}


