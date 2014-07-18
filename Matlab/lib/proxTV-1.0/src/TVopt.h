#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <limits.h>
#include "mex.h"
#include "lapack.h"

#ifndef _TVOPT_H
#define _TVOPT_H

/*** Definitions ***/

/* Comparison tolerance */
#define EPSILON 1e-10
#define IS_ZERO(x) (x < EPSILON & x > -EPSILON) 

/* Indexes of info structure */
#define N_INFO 3
#define INFO_ITERS 0
#define INFO_GAP 1
#define INFO_RC 2

/* Return Codes */
#define RC_OK 0 // Solution found at the specified error level
#define RC_ITERS 1 // Maximum number of iterations reaches, result might be suboptimal
#define RC_STUCK 2 // Algorithm stuck, impossible to improve the objetive function further, result might be suboptimal
#define RC_ERROR 3 // Fatal error during the algorithm, value of the solution is undefined.

/* TV-L1 solver */

/* Stopping tolerance */
#define STOP_PN 1e-5 //1e-5
/* Minimum decrease */
#define SIGMA 0.0500
/* Maximum number of iterations */
#define MAX_ITERS_PN 100

/* TV-L2 solver */

/* Stopping tolerances */
#define STOP_MS 1e-5 //1e-5 // Duality gap
#define STOP_MSSUB 1e-6 // Distance to boundary (prerequisite for termination)
/* Maximum number of iterations */
#define MAX_ITERS_MS 100

/* General TV solver */

/* Stopping tolerance */
#define STOP_PD 1e-1 //1e-1 // Mean absolute change in solution
/* Maximum number of iterations */
#define MAX_ITERS_PD 100
/* Maximum number of iterations for inner solvers */
#define MAX_ITERS_PD_INNER 0 //0

/*** Structures ***/

/* Workspace for warm restarts and memory management */
typedef struct{
    /* Generic memory which can be used by 1D algorithms */
    double **d;
    int **i;
    /* Memory for inputs and outputs */
    double *in,*out;
    /* Warm restart variables */
    short warm;
    double *warmDual;
    double warmLambda;
    /* Iterations limiter */
    int maxIters;
} Workspace;

/* Workspace defines */
#define WS_DOUBLES 6
#define WS_INTS 1

/*** Function headers ***/

/* TV-L1 solvers */
int PN_TV1(double *y,double lambda,double *x,double *info,int n,double sigma,Workspace *ws);
/* TV-L2 solvers */
int more_TV2(double *y,double lambda,double *x,double *info,int n);
int morePG_TV2(double *y,double lambda,double *x,double *info,int n,Workspace *ws);
int PG_TV2(double *y,double lambda,double *x,double *info,int n);
/* General TV solvers */
int PD_TV(double *y,double *lambdas,double *norms,double *dims,double *x,double *info,int *ns,int nds,int npen,int ncores,int maxIters);
int PD2_TV(double *y,double *lambdas,double *norms,double *dims,double *x,double *info,int *ns,int nds,int npen,int ncores,int maxIters);
/* Auxiliary functions */
Workspace* newWorkspace(int n);
void freeWorkspace(Workspace *ws);
Workspace** newWorkspaces(int n,int p);
void freeWorkspaces(Workspace **wa,int p);

#endif
