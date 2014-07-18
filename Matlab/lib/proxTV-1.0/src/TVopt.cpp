#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <limits.h>
#include <wchar.h>
#include "TVopt.h"
#include "mex.h"
/* Includes for parallel computation */
#ifdef _OPENMP
    #include <omp.h>
#else
    #define omp_get_thread_num() 0
    #define omp_get_max_threads() 1
    #define omp_set_num_threads(nThreads) /**/;
#endif

/* Uncomment to show debug messages */
//#define DEBUG

/* General macros */

#define DUAL2PRIMAL(w,x,i) \
    x[0] = y[0]+w[0]; \
    for(i=1;i<nn;i++) \
        x[i] = y[i]-w[i-1]+w[i]; \
    x[nn] = y[nn]-w[nn-1];
    
#define PRIMAL2GRAD(x,g,i) \
    for(i=0;i<nn;i++) \
        g[i] = x[i] - x[i+1];

/*  PN_TV1

    Given a reference signal y and a penalty parameter lambda, solves the proximity operator
    
        min_x 0.5 ||x-y||^2 + lambda sum_i |x_i - x_(i-1)| .
        
    To do so a Projected Newton algorithm is used to solve its dual problem.
    
    Inputs:
        - y: reference signal.
        - lambda: penalty parameter.
        - x: array in which to store the solution.
        - info: array in which to store optimizer information.
        - n: length of array y (and x).
        - sigma: tolerance for sufficient descent.
        - ws: workspace of allocated memory to use. If NULL, any needed memory is locally managed.
*/
int PN_TV1(double *y,double lambda,double *x,double *info,int n,double sigma,Workspace *ws){
    int i,ind,nI,recomp,found,iters,maxIters,nn=n-1;
    double lambdaMax,tmp,fval0,fval1,gRd,delta,grad0,stop,stopPrev,improve,rhs,maxStep,prevDelta;
    double *w=NULL,*g=NULL,*d=NULL,*aux=NULL,*aux2=NULL;
    int *inactive=NULL;
    ptrdiff_t one=1,rc,nnp=nn,nIp;
    
    /* Macros */
            
    #define GRAD2GAP(g,w,gap,i) \
        gap = 0; \
        for(i=0;i<nn;i++) \
            gap += fabs(g[i]) * lambda + w[i] * g[i];
        
    #define PRIMAL2VAL(x,val,i) \
        val = 0; \
        for(i=0;i<n;i++) \
            val += x[i]*x[i]; \
        val *= 0.5;
            
    #define PROJECTION(w) \
        for(i=0;i<nn;i++) \
            if(w[i] > lambda) w[i] = lambda; \
            else if(w[i] < -lambda) w[i] = -lambda;
            
    #define CHECK_INACTIVE(w,g,inactive,nI,i) \
        for(i=nI=0 ; i<nn ; i++) \
            if( (w[i] > -lambda && w[i] < lambda) || (w[i] == -lambda && g[i] < -EPSILON) || (w[i] == lambda && g[i] > EPSILON) )  \
                inactive[nI++] = i;
                
    #define FREE \
        if(!ws){ \
            if(w) free(w); \
            if(g) free(g); \
            if(d) free(d); \
            if(aux) free(aux); \
            if(aux2) free(aux2); \
            if(inactive) free(inactive); \
        }
        
    #define CANCEL(txt,info) \
        printf("PN_TV1: %s\n"); \
        FREE \
        if(info) info[INFO_RC] = RC_ERROR;\
        return 0;
            
    /* Alloc memory if no workspace available */
    if(!ws){
        w = (double*)malloc(sizeof(double)*nn);
        g = (double*)malloc(sizeof(double)*nn);
        d = (double*)malloc(sizeof(double)*nn);
        aux = (double*)malloc(sizeof(double)*nn);
        aux2 = (double*)malloc(sizeof(double)*nn);
        inactive = (int*)malloc(sizeof(int)*nn);
        if(!w || !g || ! d || !aux || !aux2 || !inactive){CANCEL("out of memory",info)}
    }
    /* If a workspace is available, assign pointers */
    else{
        w = ws->d[0];
        g = ws->d[1];
        d = ws->d[2];
        aux = ws->d[3];
        aux2 = ws->d[4];
        inactive = ws->i[0];
    }

    /* Precompute useful quantities */
    for(i=0;i<nn;i++)
        w[i] = y[i+1] - y[i]; /* Dy */
    iters = 0;
        
    /* Factorize Hessian */
    for(i=0;i<nn-1;i++){
        aux[i] = 2;
        aux2[i] = -1;
    }
    aux[nn-1] = 2;
    dpttrf_(&nnp,aux,aux2,&rc);
    /* Solve Choleski-like linear system to obtain unconstrained solution */
    dpttrs_(&nnp, &one, aux, aux2, w, &nnp, &rc);
    
    /* Compute maximum effective penalty */
    lambdaMax = 0;
    for(i=0;i<nn;i++) 
        if((tmp = fabs(w[i])) > lambdaMax) lambdaMax = tmp;

    /* Check if the unconstrained solution is feasible for the given lambda */
    #ifdef DEBUG
        printf("lambda=%lf,lambdaMax=%lf\n",lambda,lambdaMax);
    #endif
    if(lambda >= lambdaMax){
        /* In this case all entries of the primal solution should be the same as the mean of y */
        tmp = 0;
        for(i=0;i<n;i++) tmp += y[i];
        tmp /= n;
        for(i=0;i<n;i++) x[i] = tmp;
        /* Gradient evaluation */
        PRIMAL2GRAD(x,g,i)
        /* Compute dual gap */
        GRAD2GAP(g,w,stop,i)
        if(info){
            info[INFO_GAP] = fabs(stop);
            info[INFO_ITERS] = 0;
            info[INFO_RC] = RC_OK;
        }
        FREE
        return 1;
    }
    
    /* If restart info available, use it to decide starting point */
    if(ws && ws->warm)
        memcpy(w,ws->warmDual,sizeof(double)*(n-1));
    
    /* Initial guess and gradient */
    PROJECTION(w)
    DUAL2PRIMAL(w,x,i)
    PRIMAL2GRAD(x,g,i)
    PRIMAL2VAL(x,fval0,i)

    /* Identify inactive constraints at the starting point */
    CHECK_INACTIVE(w,g,inactive,nI,i)
    #ifdef DEBUG
        printf("---------Starting point--------\n");
        printf("w=["); for(i=0;i<nn;i++) printf("%lf ",w[i]); printf("]\n");
        printf("g=["); for(i=0;i<nn;i++) printf("%lf ",g[i]); printf("]\n");
        printf("inactive=["); for(i=0;i<nI;i++) printf("%d ",inactive[i]); printf("]\n");
        printf("fVal=%lf\n",fval0);
        printf("-------------------------------\n");
    #endif
    
    /* Solver loop */
    stop = DBL_MAX;
    stopPrev = -DBL_MAX;
    iters = 0;
    maxIters = (ws && ws->maxIters>0) ? ws->maxIters : MAX_ITERS_PN;
    while(stop > STOP_PN && iters < maxIters && fabs(stop-stopPrev) > EPSILON){
        /* If every constraint is active, we have finished */
        if(!nI){ FREE return 1;}
        
        /* Compute reduced Hessian (only inactive rows/columns) */
        for(i=0;i<nI-1;i++){
            aux[i] = 2;
            if(inactive[i+1]-inactive[i]!=1) aux2[i] = 0;
            else aux2[i] = -1;
        }
        aux[i] = 2;
        #ifdef DEBUG
            printf("alpha=["); for(i=0;i<nI;i++) printf("%lf ",aux[i]); printf("]\n");
            printf("beta=["); for(i=0;i<nI-1;i++) printf("%lf ",aux2[i]); printf("]\n");
        #endif
        /* Factorize reduced Hessian */
        nIp = nI;
        dpttrf_(&nIp,aux,aux2,&rc);
        #ifdef DEBUG
            printf("c=["); for(i=0;i<nI;i++) printf("%lf ",aux[i]); printf("]\n");
            printf("l=["); for(i=0;i<nI-1;i++) printf("%lf ",aux2[i]); printf("]\n");
        #endif
        
        /* Solve Choleski-like linear system to obtain Newton updating direction */
        for(i=0;i<nI;i++)
            d[i] = g[inactive[i]];
        dpttrs_(&nIp, &one, aux, aux2, d, &nIp, &rc);
        #ifdef DEBUG
            printf("d=["); for(i=0;i<nI;i++) printf("%lf ",d[i]); printf("]\n");
        #endif
        
        /* Stepsize selection algorithm (quadratic interpolation) */
        gRd = 0;
        for(i=0;i<nI;i++)
            gRd += g[inactive[i]] * d[i];
        recomp = 0; delta = 1; found = 0;
        memcpy((void*)aux,(void*)w,sizeof(double)*nn);
        while(!found){
            /* Compute projected point after update */
            for(i=0;i<nI;i++){
                ind = inactive[i];
                aux[ind] = w[ind] - delta*d[i];
                if(aux[ind] > lambda) aux[ind] = lambda;
                else if(aux[ind] < -lambda) aux[ind] = -lambda;
            }
            /* Get primal point */
            DUAL2PRIMAL(aux,x,i)
            /* Compute new value of the objective function */
            PRIMAL2VAL(x,fval1,i)
            improve = fval0 - fval1;
            /* If zero improvement, the updating direction is not useful */
            if(improve <= EPSILON)
                break;
            /* Compute right hand side of Armijo rule */
            rhs = sigma * delta * gRd;
            /* Check if the rule is met */
            if(improve >= rhs) found = 1;
            else{
                if(!recomp){
                    /* Compute maximum useful stepsize */
                    maxStep = -DBL_MAX;
                    for(i=0;i<nI;i++){
                        if(d[i] < 0){
                            if((tmp=(w[inactive[i]]-lambda)/d[i]) > maxStep) maxStep = tmp;
                        } else if(d[i] > 0 && (tmp=(w[inactive[i]]+lambda)/d[i]) > maxStep) maxStep = tmp;
                    }
                    #ifdef DEBUG
                        printf("maxStep=%lf\n",maxStep);
                    #endif
                    
                    /* Compute gradient w.r.t stepsize at the present position */
                    grad0 = 0;
                    if(!inactive[0]){
                        if( !((lambda == w[0]) && d[0] > 0) && !((lambda == w[0]) && d[0] < 0) )
                            grad0 += -d[0] * (2*w[0] - w[1] - y[1] - y[0]);
                    }
                    for(i=1;i<nI-1;i++){
                        ind = inactive[i];
                        if( !((lambda == w[ind]) && d[i] > 0) && !((lambda == w[ind]) && d[i] < 0) )
                            grad0 += -d[i] * (2*w[ind] - w[ind+1] - w[ind-1] - y[ind+1] - y[ind]);
                    }
                    if(inactive[nI-1] == nn-1){
                        if( !((lambda == w[nn-1]) && d[nI-1] > 0) && !((lambda == w[nn-1]) && d[nI-1] < 0) )
                            grad0 += -d[nI-1] * (2*w[nn-1] - w[nn-2] - y[nn] - y[nn-1]);
                    }
                
                    recomp = 1;
                }
                /* Use quadratic interpolation to determine next stepsize */
                tmp = grad0 * delta;
                prevDelta = delta;
                delta = - (tmp*delta) / (2 * (-improve - tmp));
                /* If larger than maximum stepsize, clip */
                if(delta > maxStep) delta = maxStep;
                /* If too similar to previous stepsize or larger, cut in half */
                if(delta-prevDelta >= -EPSILON) delta = prevDelta/2;
                /* If negative or zero, stop! */
                if(delta < EPSILON) found = true;
                #ifdef DEBUG
                    printf("delta=%lf\n",delta);
                #endif
                /* Readjust maximum allowed step */
                maxStep = delta;
            }
        }
            
        /* Perform update */
        memcpy((void*)w,(void*)aux,sizeof(double)*nn);
        fval0 = fval1;
        
        /* Reconstruct gradient */
        PRIMAL2GRAD(x,g,i)

        /* Identify active and inactive constraints */
        CHECK_INACTIVE(w,g,inactive,nI,i)

        /* Compute stopping criterion */
        stopPrev = stop;
        GRAD2GAP(g,w,stop,i)
        
        iters++;
        
        #ifdef DEBUG
            printf("---------End of iteration %d--------\n",iters);
            printf("w=["); for(i=0;i<nn;i++) printf("%lf ",w[i]); printf("]\n");
            printf("g=["); for(i=0;i<nn;i++) printf("%lf ",g[i]); printf("]\n");
            printf("inactive=["); for(i=0;i<nI;i++) printf("%d ",inactive[i]); printf("]\n");
            printf("fVal=%lf\n",fval0);
            printf("stop=%lf\n",stop);
        #endif
    }
    
    /* Termination check */
    if(iters >= MAX_ITERS_PN){
        #ifdef DEBUG
            printf("(PN_TV1) WARNING: maximum number of iterations reached (%d).\n",MAX_ITERS_PN);
        #endif
        if(info)
            info[INFO_RC] = RC_ITERS;
    }
    else if(fabs(stop-stopPrev) <= EPSILON){
        #ifdef DEBUG
            printf("(PN_TV1) WARNING: search stuck, improvement is not possible.\n");
        #endif
        if(info)
            info[INFO_RC] = RC_STUCK;
    }
    else if(info) info[INFO_RC] = RC_OK;

    if(info){
        info[INFO_ITERS] = iters;
        info[INFO_GAP] = fabs(stop);
    }
    
    /* If restart structure available, store info for later warm restart */
    if(ws){
        memcpy(ws->warmDual,w,sizeof(double)*(n-1));
        ws->warm = 1;
    }
    
    FREE
    return 1;
         
    #undef GRAD2GAP        
    #undef PRIMAL2VAL            
    #undef PROJECTION            
    #undef CHECK_INACTIVE
    #undef FREE
    #undef CANCEL
}

/*  more_TV2

    Given a reference signal y and a penalty parameter lambda, solves the proximity operator
    
        min_x 0.5 ||x-y||^2 + lambda ||x_i - x_(i-1)||_2 .
        
    To do so a More-Sorensen algorithm is used to solve its dual problem.
    
    Inputs:
        - y: reference signal.
        - lambda: penalty parameter.
        - x: array in which to store the solution.
        - info: array in which to store optimizer information.
        - n: length of array y (and x).
*/
int more_TV2(double *y,double lambda,double *x,double *info,int n){
    int nn=n-1,i;
    double stop,tmp,tmp2,lam,pNorm,qNorm,pNormSq,dist;
    double *Dy,*alpha,*beta,*minus,*p,*aux;
    ptrdiff_t one=1,rc,nnp=nn;
    
    /* Macros */
    
    // Solves Rx = y for lower bidiagonal R given by diag. alpha and subdiag. beta using forward substitution
    // Returns the solution overwriting y
    #define FW_SUBS(alpha,beta,y,n,i) \
        y[0] /= alpha[0]; \
        for(i=1;i<n;i++) \
            y[i] = (y[i] - beta[i-1] * y[i-1]) / alpha[i];
            
    #define GRAD2GAP(w,g,gap,lambda,n,i,tmp) \
        gap = tmp = 0; \
        for(i=0;i<n;i++){ \
            tmp += g[i]*g[i]; \
            gap += w[i] * g[i]; \
        } \
        gap += lambda * sqrt(tmp); \
        gap = fabs(gap);
    
    #define FREE \
        if(Dy) free(Dy); \
        if(minus) free(minus); \
        if(alpha) free(alpha); \
        if(beta) free(beta); \
        if(p) free(p); \
        if(aux) free(aux);
        
    #define CANCEL(txt,info) \
        printf("more_TV2: %s\n"); \
        FREE \
        info[INFO_RC] = RC_ERROR;\
        return 0;
    
    /* Alloc memory */
    Dy = (double*)malloc(sizeof(double)*nn);
    minus = (double*)malloc(sizeof(double)*(nn-1));
    alpha = (double*)malloc(sizeof(double)*nn);
    beta = (double*)malloc(sizeof(double)*(nn-1));
    p = (double*)malloc(sizeof(double)*nn);
    aux = (double*)malloc(sizeof(double)*nn);
    if(!Dy || !minus || !alpha || !beta || !p || !aux){CANCEL("out of memory",info)}
    
    /* Correct penalty value */
    lambda *= lambda;

    /* Precomputations */
    
    for(i=0;i<nn-1;i++){
        Dy[i] = -y[i] + y[i+1];
        minus[i] = -1;
    }
    Dy[nn-1] = -y[nn-1] + y[nn];
    
    /* Iterate till convergence */
    stop = DBL_MAX;
    info[INFO_ITERS] = 0;
    lam = 0;
    #ifdef DEBUG
        printf("--------------- Start ---------------\n",lam);
        printf("lam=%lf\n",lam);
    #endif
    while(stop > STOP_MS && info[INFO_ITERS] < MAX_ITERS_MS){
        /* Generate tridiagonal representation of Hessian */
        tmp = 2+lam;
        for(i=0;i<nn;i++)
            alpha[i] = tmp;    
        memcpy((void*)beta,(void*)minus,sizeof(double)*(nn-1));

        /* Compute tridiagonal factorization of Hessian */
        dpttrf_(&nnp,alpha,beta,&rc);
        
        /* Obtain p by solving Cholesky system */
        memcpy((void*)aux,(void*)Dy,sizeof(double)*nn);
        dpttrs_(&nnp, &one, alpha, beta, aux, &nnp, &rc);
        memcpy((void*)p,(void*)aux,sizeof(double)*nn);
        pNorm = 0; for(i=0;i<nn;i++) pNorm += aux[i]*aux[i];
        pNormSq = sqrt(pNorm);
        
        /* Compute Cholesky matrix */
        for(i=0;i<nn-1;i++){
            alpha[i] = tmp = sqrt(alpha[i]);
            beta[i] *= tmp;
        }
        alpha[nn-1] = sqrt(alpha[nn-1]);


        /* Obtain q by solving yet another system */
        FW_SUBS(alpha,beta,aux,nn,i)
        qNorm = 0; for(i=0;i<nn;i++) qNorm += aux[i]*aux[i];

        /* Update the constraint satisfaction parameter of the algorithm */
        lam += (pNorm / qNorm) * (pNormSq - lambda) / lambda;
        /* If negative, set to zero */
        if(lam < 0) lam = 0;
        
        /* Compute distance to boundary */
        dist = pNormSq - lambda;
        /* Check if the distance criterion is met
          If we are in the lam=0 case and the p is in the interior, it is automatically met */
        if((!lam && dist <= 0) || fabs(dist) <= STOP_MSSUB){
            /* Compute dual gap */
            DUAL2PRIMAL(p,x,i)
            PRIMAL2GRAD(x,aux,i)
            GRAD2GAP(p,aux,stop,lambda,nn,i,tmp)
            stop = fabs(stop);
        }
        //else stop = dist;
        else stop = DBL_MAX;

        info[INFO_ITERS]++;
        
        #ifdef DEBUG
            printf("--------------- End of iteration %lf ---------------\n",info[INFO_ITERS]);
            printf("p=["); for(i=0;i<nn;i++) printf("%lf ",p[i]); printf("]\n");
        #endif
    }
    
    info[INFO_GAP] = stop;
    
    /* Termination check */
    if(info[INFO_ITERS] >= MAX_ITERS_MS){
        #ifdef DEBUG
            printf("(more_TV2) WARNING: maximum number of iterations reached (%d).\n",MAX_ITERS_PN);
        #endif
        info[INFO_RC] = RC_ITERS;
    }
    else info[INFO_RC] = RC_OK;
    
    FREE
    return 1;
    
    #undef FW_SUBS
    #undef FREE
    #undef CANCEL
}

/*  morePG_TV2

    Given a reference signal y and a penalty parameter lambda, solves the proximity operator
    
        min_x 0.5 ||x-y||^2 + lambda ||x_i - x_(i-1)||_2 .
        
    To do so a More-Sorensen + Projected Gradient algorithm is used to solve its dual problem.
    
    Inputs:
        - y: reference signal.
        - lambda: penalty parameter.
        - x: array in which to store the solution.
        - info: array in which to store optimizer information.
        - n: length of array y (and x).
        - ws: workspace of allocated memory to use. If NULL, any needed memory is locally managed.
*/
int morePG_TV2(double *y,double lambda,double *x,double *info,int n,Workspace *ws){
    int nn=n-1,i,iters,maxIters;
    double stop,tmp,tmp2,lam,pNorm,qNorm,pNormSq,dist,lamOrig;
    double *Dy,*alpha,*beta,*minus,*p,*aux;
    ptrdiff_t one=1,rc,nnp=nn;
    
    /* Macros */
    
    // Solves Rx = y for lower bidiagonal R given by diag. alpha and subdiag. beta using forward substitution
    // Returns the solution overwriting y
    #define FW_SUBS(alpha,beta,y,n,i) \
        y[0] /= alpha[0]; \
        for(i=1;i<n;i++) \
            y[i] = (y[i] - beta[i-1] * y[i-1]) / alpha[i];
            
    #define GRAD2GAP(w,g,gap,lambda,n,i,tmp) \
        gap = tmp = 0; \
        for(i=0;i<n;i++){ \
            tmp += g[i]*g[i]; \
            gap += w[i] * g[i]; \
        } \
        gap += lambda * sqrt(tmp); \
        gap = fabs(gap);
        
    #define NORM(x,n,i,tmp) \
        tmp = 0; \
        for(i=0;i<n;i++) tmp += x[i]*x[i]; tmp = sqrt(tmp);
    
    #define FREE \
        if(!ws) { \
            if(Dy) free(Dy); \
            if(minus) free(minus); \
            if(alpha) free(alpha); \
            if(beta) free(beta); \
            if(p) free(p); \
            if(aux) free(aux); \
        }
        
    #define CANCEL(txt,info) \
        printf("more_TV2: %s\n"); \
        FREE \
        if(info) info[INFO_RC] = RC_ERROR;\
        return 0;
    
    /* Alloc memory if needed */
    if(!ws){
        p = (double*)malloc(sizeof(double)*nn);
        aux = (double*)malloc(sizeof(double)*nn);
        if(!p || !aux){CANCEL("out of memory",info)}
    }
    else{
        p = ws->d[0];
        aux = ws->d[1];
    }
    
    stop = DBL_MAX;
    iters = 0;
    
    /* Correct penalty value */
    lamOrig = lambda;
    lambda *= lambda;
    
    /* Rule-of-thumb to check if PG might help */
    NORM(y,n,i,tmp)
    if(tmp > lamOrig){
        #define STEP 0.25
        #define MAX_PG 50
        
        /* Warm restart (if possible) */
        if(ws && ws->warm){
            memcpy(p,ws->warmDual,sizeof(double)*nn);
            DUAL2PRIMAL(p,x,i)
            PRIMAL2GRAD(x,aux,i)
        }
        /* Else start at 0 */
        else{
            for(i=0;i<nn;i++){
                p[i] = 0;
                aux[i] = y[i] - y[i+1];
            }
        }
        
        /* Projected Gradient iterations */
        maxIters = (ws && ws->maxIters>0) ? ws->maxIters : MAX_PG;
        while(stop > STOP_MS && iters < maxIters){
            /* Gradient step */
            for(i=0;i<nn;i++) p[i] = p[i] - STEP * aux[i];
            
            /* Projection step */
            NORM(p,n,i,tmp)
            if(tmp > lambda){
                tmp = lambda / tmp;
                for(i=0;i<nn;i++) p[i] *= tmp;
            }
            
            DUAL2PRIMAL(p,x,i)
            PRIMAL2GRAD(x,aux,i)
            GRAD2GAP(p,aux,stop,lambda,nn,i,tmp)

            iters++;
        }
        
        /* Stop if solution is good enough */
        if(stop <= STOP_MS){
            if(info){
                info[INFO_ITERS] = iters;
                info[INFO_GAP] = fabs(stop);
                info[INFO_RC] = RC_OK;
            }
            /* Store info for warm restart */
            if(ws){
                memcpy(ws->warmDual,p,sizeof(double)*nn);
                ws->warmLambda = 0;
                ws->warm = 1;
            }
            FREE
            return 1;
        }
        
        #undef STEP
        #undef MAX_PG
    }
    
    /* Alloc more memory */
    if(!ws){
        Dy = (double*)malloc(sizeof(double)*nn);
        minus = (double*)malloc(sizeof(double)*(nn-1));
        alpha = (double*)malloc(sizeof(double)*nn);
        beta = (double*)malloc(sizeof(double)*(nn-1));
        if(!Dy || !minus || !alpha || !beta || !p || !aux){CANCEL("out of memory",info)}
    }
    else{
        Dy = ws->d[2];
        minus = ws->d[3];
        alpha = ws->d[4];
        beta = ws->d[5];
    }

    /* Precomputations */
    
    for(i=0;i<nn-1;i++){
        Dy[i] = -y[i] + y[i+1];
        minus[i] = -1;
    }
    Dy[nn-1] = -y[nn-1] + y[nn];
    
    /* Warm restart if possible */
    if(ws && ws->warm){
        lam = ws->warmLambda;
    }
    else lam = 0;
    
    /* Iterate till convergence */
    #ifdef DEBUG
        printf("--------------- Start ---------------\n",lam);
        printf("lam=%lf\n",lam);
    #endif
    maxIters = (ws && ws->maxIters>0) ? ws->maxIters : MAX_ITERS_MS;
    while(stop > STOP_MS && iters < maxIters){
        /* Generate tridiagonal representation of Hessian */
        tmp = 2+lam;
        for(i=0;i<nn;i++)
            alpha[i] = tmp;    
        memcpy((void*)beta,(void*)minus,sizeof(double)*(nn-1));

        /* Compute tridiagonal factorization of Hessian */
        dpttrf_(&nnp,alpha,beta,&rc);
        
        /* Obtain p by solving Cholesky system */
        memcpy((void*)aux,(void*)Dy,sizeof(double)*nn);
        dpttrs_(&nnp, &one, alpha, beta, aux, &nnp, &rc);
        memcpy((void*)p,(void*)aux,sizeof(double)*nn);
        pNorm = 0; for(i=0;i<nn;i++) pNorm += aux[i]*aux[i];
        pNormSq = sqrt(pNorm);
        
        /* Compute Cholesky matrix */
        for(i=0;i<nn-1;i++){
            alpha[i] = tmp = sqrt(alpha[i]);
            beta[i] *= tmp;
        }
        alpha[nn-1] = sqrt(alpha[nn-1]);


        /* Obtain q by solving yet another system */
        FW_SUBS(alpha,beta,aux,nn,i)
        qNorm = 0; for(i=0;i<nn;i++) qNorm += aux[i]*aux[i];

        /* Update the constraint satisfaction parameter of the algorithm */
        lam += (pNorm / qNorm) * (pNormSq - lambda) / lambda;
        /* If negative, set to zero */
        if(lam < 0) lam = 0;
        
        /* Compute distance to boundary */
        dist = pNormSq - lambda;
        /* Check if the distance criterion is met
          If we are in the lam=0 case and the p is in the interior, it is automatically met */
        if((!lam && dist <= 0) || fabs(dist) <= STOP_MSSUB){
            /* Compute dual gap */
            DUAL2PRIMAL(p,x,i)
            PRIMAL2GRAD(x,aux,i)
            GRAD2GAP(p,aux,stop,lambda,nn,i,tmp)
            stop = fabs(stop);
        }
        //else stop = dist;
        else stop = DBL_MAX;

        iters++;
        
        #ifdef DEBUG
            printf("--------------- End of iteration %d ---------------\n",iters);
            printf("p=["); for(i=0;i<nn;i++) printf("%lf ",p[i]); printf("]\n");
        #endif
    }
    
    if(info){
        info[INFO_GAP] = stop;
        info[INFO_ITERS] = iters;
    }
    
    /* Termination check */
    if(iters >= MAX_ITERS_MS){
        #ifdef DEBUG
            printf("(more_TV2) WARNING: maximum number of iterations reached (%d).\n",MAX_ITERS_PN);
        #endif
        if(info) info[INFO_RC] = RC_ITERS;
    }
    else if(info) info[INFO_RC] = RC_OK;
    
    /* Store info for warm restart */
    if(ws){
        memset(ws->warmDual,0,sizeof(double)*nn);
        ws->warmLambda = lam;
        ws->warm = 1;
    }
    
    FREE
    return 1;
    
    #undef FW_SUBS
    #undef NORM
    #undef FREE
    #undef CANCEL
}

/*  PG_TV2

    Given a reference signal y and a penalty parameter lambda, solves the proximity operator
    
        min_x 0.5 ||x-y||^2 + lambda ||x_i - x_(i-1)||_2 .
        
    To do so a Projected Gradient algorithm is used to solve its dual problem.
    
    Inputs:
        - y: reference signal.
        - lambda: penalty parameter.
        - x: array in which to store the solution.
        - info: array in which to store optimizer information.
        - n: length of array y (and x).
*/
int PG_TV2(double *y,double lambda,double *x,double *info,int n){
    int nn=n-1,i;
    double stop,tmp,tmp2,lam,pNorm,qNorm,pNormSq,dist;
    double *p,*aux;
    ptrdiff_t one=1,rc,nnp=nn;
    
    /* Macros */
            
    #define GRAD2GAP(w,g,gap,lambda,n,i,tmp) \
        gap = tmp = 0; \
        for(i=0;i<n;i++){ \
            tmp += g[i]*g[i]; \
            gap += w[i] * g[i]; \
        } \
        gap += lambda * sqrt(tmp); \
        gap = fabs(gap);
        
    #define NORM(x,n,i,tmp) \
        tmp = 0; \
        for(i=0;i<n;i++) tmp += x[i]*x[i]; tmp = sqrt(tmp);
    
    #define FREE \
        if(p) free(p); \
        if(aux) free(aux);
        
    #define CANCEL(txt,info) \
        printf("more_TV2: %s\n"); \
        FREE \
        info[INFO_RC] = RC_ERROR;\
        return 0;
        
    #define STEP 0.25
    #define MAX_PG 100000
    
    /* Alloc memory */
    p = (double*)calloc(nn,sizeof(double));
    aux = (double*)malloc(sizeof(double)*nn);
    if(!p || !aux){CANCEL("out of memory",info)}
    
    /* Correct penalty value */
    lambda *= lambda;
    
    stop = DBL_MAX;
    info[INFO_ITERS] = 0;
    
    /* Construct problem */
    for(i=0;i<nn;i++)
        aux[i] = y[i] - y[i+1];
    
    /* Projected Gradient iterations */
    while(stop > STOP_MS && info[INFO_ITERS] < MAX_PG){
        /* Gradient step */
        for(i=0;i<nn;i++) p[i] = p[i] - STEP * aux[i];
        
        /* Projection step */
        NORM(p,n,i,tmp)
        if(tmp > lambda){
            tmp = lambda / tmp;
            for(i=0;i<nn;i++) p[i] *= tmp;
        }
        
        DUAL2PRIMAL(p,x,i)
        PRIMAL2GRAD(x,aux,i)
        GRAD2GAP(p,aux,stop,lambda,nn,i,tmp)

        info[INFO_ITERS]++;
    }

    info[INFO_GAP] = stop;
    
    /* Termination check */
    if(info[INFO_ITERS] >= MAX_PG){
        #ifdef DEBUG
            printf("(PG_TV2) WARNING: maximum number of iterations reached (%d).\n",MAX_PG);
        #endif
        info[INFO_RC] = RC_ITERS;
    }
    else info[INFO_RC] = RC_OK;
    
    FREE
    return 1;
    
    #undef NORM
    #undef FREE
    #undef CANCEL
    #undef STEP
    #undef MAX_PG
}

/*  PD_TV

    Given a reference multidimensional signal y and a series of penalty terms P(x,lambda,d,p), solves the generalized Total Variation
    proximity operator
    
        min_x 0.5 ||x-y||^2 + sum_i P(x,lambda_i,d_i,p_i) .
        
    where P(x,lambda_i,d_i,p_i) = lambda_i * sum_j TV(x(d_i)_j,p_i) with x(d)_j every possible 1-dimensional slice of x following the dimension d_i, TV(x,p) the TV-Lp prox operator for x.
    
    This general formulation allows to apply different TV regularizers over each dimension of the signal in a modular way.
        
    To solve the problem, a Parallel Dykstra-like splitting method is applied, using as building blocks the 1-dimensional TV solvers.
    
    Inputs:
        - y: reference multidimensional signal in vectorized form.
        - lambdas: array of penalty parameters.
        - norms: array indicating the norm for each penalty term.
        - dims: array indicating the dimension over which each penalty term is applied (1 to N).
        - x: array in which to store the solution in vectorized form.
        - info: array in which to store optimizer information (or NULL if not required)
        - ns: array with the lengths of each dimension of y (and x).
        - nds: number of dimensions.
        - npen: number of penalty terms.
        - ncores: number of cores to use
*/
int PD_TV(double *y,double *lambdas,double *norms,double *dims,double *x,double *info,int *ns,int nds,int npen,int ncores,int maxIters){
    long n,k,nBytes,idx1,idx2;
    int i,j,d,maxDim,iters,nThreads;
    double stop;
    double *xLast=NULL,*slice=NULL,*out1d=NULL;
    double **p=NULL,**z=NULL;
    long *incs=NULL,*nSlices=NULL;
    Workspace **ws=NULL;

    #define FREE \
        if(p) { for(i=0;i<npen;i++) free(p[i]); free(p); } \
        if(z) { for(i=0;i<npen;i++) free(z[i]); free(z); } \
        if(xLast) free(xLast); \
        if(incs) free(incs); \
        if(nSlices) free(nSlices); \
        if(slice) free(slice); \
        if(out1d) free(out1d); \
        if(ws) freeWorkspaces(ws,nThreads);
        
    #define CANCEL(txt,info) \
        printf("PD_TV: %s\n"); \
        FREE \
        if(info) info[INFO_RC] = RC_ERROR;\
        return 0;
        
    /* Set number of threads */
    nThreads = (ncores > 1) ? ncores : 1;
    #ifdef DEBUG
        printf("Threads: %d\n",nThreads);
    #endif
    omp_set_num_threads(nThreads);
    
    /* Set number of iterations */
    if(maxIters <= 0) maxIters = MAX_ITERS_PD;

    /* Compute total number of elements and maximum along dimensions */
    n = 1; maxDim = 0;
    for(i=0;i<nds;i++){
        n *= ns[i];
        if(ns[i] > maxDim) maxDim = ns[i];
    }
    nBytes = sizeof(double)*n;
    
    #ifdef DEBUG
        printf("ns: ");
        for(i=0;i<nds;i++)
            printf("%d ",ns[i]);
        printf("\n");
        printf("n=%ld\n",n);
        printf("nBytes=%ld, %d\n",nBytes,(size_t)nBytes);
    #endif
    
    /* Scale penalties */
    for(i=0;i<npen;i++)
        lambdas[i] *= npen;
    
    /* Alloc auxiliary memory */
    p = (double**)calloc(npen,sizeof(double*));
    z = (double**)calloc(npen,sizeof(double*));
    if(!p || !z) {CANCEL("out of memory",info)}
    for(i=0;i<npen;i++){
        p[i] = (double*)malloc(nBytes);
        z[i] = (double*)malloc(nBytes);
        if(!p[i] || !z[i]) {CANCEL("out of memory",info)}
    }
    xLast = (double*)malloc(nBytes);
    incs = (long*)malloc(sizeof(long)*nds);
    nSlices = (long*)malloc(sizeof(long)*nds);
    ws = newWorkspaces(maxDim,nThreads);
    if(!xLast || !incs || !nSlices || !ws) {CANCEL("out of memory",info)}
    
    #ifdef DEBUG
        for(i=0;i<n;i++)
            printf("%lf ",y[i]);
        printf("\n");
    #endif
    
    /* Initialization */
    #pragma omp parallel for shared(n,x,npen,z,y) private(i,j) default(none)  
    for(i=0;i<n;i++){
        x[i] = 0;
        for(j=0;j<npen;j++)
            z[j][i] = y[i];
    }
        
    /* Computes increments and number of slices to slice the signal over each dimension */
    incs[0] = 1;
    nSlices[0] = n / ns[0];
    for(i=1;i<nds;i++){
        incs[i] = incs[i-1]*ns[i-1];
        nSlices[i] = n / ns[i];
    }
    
    #ifdef DEBUG
        printf("incs: ");
        for(i=0;i<nds;i++) printf("%d ",incs[i]);
        printf("\n");
        printf("nSlices: ");
        for(i=0;i<nds;i++) printf("%d ",nSlices[i]);
        printf("\n");
    #endif
    
    /* Main loop */
    stop = DBL_MAX; iters = 0;
    while(stop > STOP_PD && iters < maxIters){
        #ifdef DEBUG
            printf("----------Iteration %d start----------\n",iters+1);
        #endif
    
        /* Copy actual solution */
        #pragma omp parallel for shared(x,xLast,n) private(i) default(none)  
        for(i=0;i<n;i++){
            xLast[i] = x[i];
            x[i] = 0;
        }
        
        /* Parallelize */
        #pragma omp parallel shared(ws,nSlices,ns,incs,x,p,lambdas,z,norms,npen,dims) private(d,i,j,k,idx1,idx2) default(none)  
        {
            /* Get thread number */
            int id = omp_get_thread_num();
            Workspace *wsi = ws[id];
            
            /* Prox step for every penalty term */    
            for(i=0;i<npen;i++){
				int top=nSlices[d];
                #ifdef DEBUG
                    printf("··········Penalty %d··········\n",i);
                #endif
                d = dims[i]-1;

                wsi->warm = 0;
                
                /* Run 1-dimensional prox operator over each 1-dimensional slice along the specified dimension */    
                #pragma omp for nowait
                for(j=0;j<top;j++){
                    /* Find slice starting point */
                    idx1 = (j / incs[d])*incs[d]*ns[d] + (j % incs[d]);
            
                    /* Construct slice */
                    for(k=0,idx2=0 ; k<ns[d] ; k++,idx2+=incs[d])
                        wsi->in[k] = z[i][idx1+idx2];
                    
                    #ifdef DEBUG
                    {
                        int dbgi;
                        printf("Slice %d: ",j);
                        for(dbgi=0;dbgi<ns[d];dbgi++)
                            printf("%lf ",slice[dbgi]);
                        printf("\n");
                    }
                    #endif
                
                    /* Apply 1-dimensional solver */
                    switch((int)norms[i]){
                        case 1: PN_TV1(wsi->in,lambdas[i],wsi->out,NULL,ns[d],SIGMA,wsi); break;
                        case 2: morePG_TV2(wsi->in,lambdas[i],wsi->out,NULL,ns[d],wsi); break;
                    }
                
                    /* Plug solution back */
                    for(k=0,idx2=0 ; k<ns[d] ; k++,idx2+=incs[d])
                        p[i][idx1+idx2] = wsi->out[k];
                }
            }
        }
        
        /* Reconstruct signal x from partial penalties solutions */
        for(k=0;k<n;k++)
            for(i=0;i<npen;i++)        
                x[k] += p[i][k] / npen;
    
        /* Z update step */
        #pragma omp parallel for shared(n,npen,z,x,p) private(k,i) default(none)  
        for(k=0;k<n;k++)
            for(i=0;i<npen;i++)
                z[i][k] += x[k] - p[i][k];
        
        /* Compute stopping criterion: mean change */
        stop = 0;
        #pragma omp parallel for shared(x,xLast,n) private(k) reduction(+:stop) default(none)  
        for(k=0;k<n;k++)
            stop += fabs(x[k]-xLast[k]);
        stop /= n;
        
        iters++;
    }
    
    /* Gather output information */
    if(info){
        info[INFO_ITERS] = iters;
        info[INFO_GAP] = stop;
    }
    
    /* Termination check */
    if(iters >= MAX_ITERS_PD){
        #ifdef DEBUG
            printf("(PD_TV) WARNING: maximum number of iterations reached (%d).\n",MAX_ITERS_PD);
        #endif
        if(info) info[INFO_RC] = RC_ITERS;
    }
    else if(info) info[INFO_RC] = RC_OK;
    
    FREE
    return 1;
    
    #undef FREE
    #undef CANCEL
}

/*  PD2_TV

    Optimized version of PD_TV for the case where only 1 or 2 penalty terms appear.
*/
int PD2_TV(double *y,double *lambdas,double *norms,double *dims,double *x,double *info,int *ns,int nds,int npen,int ncores,int maxIters){
    long n,k,nBytes,idx1,idx2;
    int i,j,d,maxDim,iters;
    double stop;
    double *xLast=NULL;
    double *p=NULL,*z=NULL,*q=NULL;
    long *incs=NULL,*nSlices=NULL;
    Workspace **ws=NULL;
    short nThreads;

    #define FREE \
        if(p) free(p); \
        if(z) free(z); \
        if(q) free(q); \
        if(xLast) free(xLast); \
        if(incs) free(incs); \
        if(nSlices) free(nSlices); \
        if(ws) freeWorkspaces(ws,nThreads);
        
    #define CANCEL(txt,info) \
        printf("PD2_TV: %s\n"); \
        FREE \
        if(info) info[INFO_RC] = RC_ERROR;\
        return 0;
        
    /* Set number of threads */
    nThreads = (ncores > 1) ? ncores : 1;
    #ifdef DEBUG
        printf("Threads: %d\n",nThreads);
    #endif
    omp_set_num_threads(nThreads);
    
    /* Set number of iterations */
    if(maxIters <= 0) maxIters = MAX_ITERS_PD;

    /* This algorithm can only work with 1 or 2 penalties */
    if(npen > 2)
        {CANCEL("this algorithm can not work with more than 2 penalties",info)}

    /* Compute total number of elements and maximum along dimensions */
    n = 1; maxDim = 0;
    for(i=0;i<nds;i++){
        n *= ns[i];
        if(ns[i] > maxDim) maxDim = ns[i];
    }
    nBytes = sizeof(double)*n;
    
    #ifdef DEBUG
        printf("ns: ");
        for(i=0;i<nds;i++)
            printf("%d ",ns[i]);
        printf("\n");
        printf("n=%ld\n",n);
        printf("nBytes=%ld, %d\n",nBytes,(size_t)nBytes);
    #endif
    
    /* Alloc auxiliary memory */
    p = (double*)malloc(nBytes);
    z = (double*)malloc(nBytes);
    q = (double*)malloc(nBytes);
    if(!p || !z || !q) {CANCEL("out of memory",info)}
    xLast = (double*)malloc(nBytes);
    incs = (long*)malloc(sizeof(long)*nds);
    nSlices = (long*)malloc(sizeof(long)*nds);
    ws = newWorkspaces(maxDim,nThreads);
    if(!xLast || !incs || !nSlices || !ws) {CANCEL("out of memory",info)}
    
    #ifdef DEBUG
        for(i=0;i<n;i++)
            printf("%lf ",y[i]);
        printf("\n");
    #endif
    
    /* Initialization */
    #pragma omp parallel for shared(x,y,p,q,n) private(i) default(none)  
    for(i=0;i<n;i++){
        x[i] = y[i];
        p[i] = 0;
        q[i] = 0;
    }
        
    /* Computes increments and number of slices to slice the signal over each dimension */
    incs[0] = 1;
    nSlices[0] = n / ns[0];
    for(i=1;i<nds;i++){
        incs[i] = incs[i-1]*ns[i-1];
        nSlices[i] = n / ns[i];
    }
    
    #ifdef DEBUG
        printf("incs: ");
        for(i=0;i<nds;i++) printf("%ld ",incs[i]);
        printf("\n");
        printf("nSlices: ");
        for(i=0;i<nds;i++) printf("%ld ",nSlices[i]);
        printf("\n");
    #endif
    
    /* Main loop */
    stop = DBL_MAX; iters = 0;
    while(stop > STOP_PD && (npen > 1 || !iters) && iters < maxIters){
        #ifdef DEBUG
            printf("----------Iteration %d start----------\n",iters+1);
        #endif
        
        /* Copy actual solution */
        #pragma omp parallel for shared(x,xLast,n) private(i) default(none)  
        for(i=0;i<n;i++)
            xLast[i] = x[i];
        
        /* Prox step for the first penalty term */
        #ifdef DEBUG
            printf("··········Penalty 0··········\n");
        #endif
        d = dims[0]-1;
        /* Run 1-dimensional prox operator over each 1-dimensional slice along the specified dimension (parallelized) */
        #pragma omp parallel shared(ws,nSlices,ns,d,incs,x,p,lambdas,z,norms) private(j,k,idx1,idx2) default(none)  
        {
            /* Get thread number */
            int id = omp_get_thread_num();
			int top=nSlices[d];
            Workspace *wsi = ws[id];
            wsi->warm = 0;
            
            #pragma omp for
            for(j=0;j<top;j++){
                /* Find slice starting point */
                idx1 = (j / incs[d])*incs[d]*ns[d] + (j % incs[d]);
            
                /* Construct slice */
                for(k=0,idx2=0 ; k<ns[d] ; k++,idx2+=incs[d])
                    wsi->in[k] = x[idx1+idx2]+p[idx1+idx2];
                    
                #ifdef DEBUG
                {
                    int dbgi;
                    printf("Slice %d: ",j);
                    for(dbgi=0;dbgi<ns[d];dbgi++)
                        printf("%lf ",slice[dbgi]);
                    printf("\n");
                }
                #endif
                
                /* Apply 1-dimensional solver */
                switch((int)norms[0]){
                    case 1: PN_TV1(wsi->in,lambdas[0],wsi->out,NULL,ns[d],SIGMA,wsi); break;
                    case 2: morePG_TV2(wsi->in,lambdas[0],wsi->out,NULL,ns[d],wsi); break;
                }
                
                /* Plug solution back */
                for(k=0,idx2=0 ; k<ns[d] ; k++,idx2+=incs[d])
                    z[idx1+idx2] = wsi->out[k];
            }
        }
        
        /* Update p */
        #pragma omp parallel for shared(p,x,z,n) private(i) default(none)  
        for(i=0;i<n;i++)
            p[i] += x[i] - z[i];
    
        /* Prox step for the second penalty term (if any) */
        if(npen >= 2){
            #ifdef DEBUG
                printf("··········Penalty 1··········\n");
            #endif
            d = dims[1]-1;
            
            /* Run 1-dimensional prox operator over each 1-dimensional slice along the specified dimension (parallelized) */
            #pragma omp parallel shared(ws,nSlices,ns,d,incs,x,q,lambdas,z,norms) private(j,k,idx1,idx2) default(none)  
            {
                /* Get thread number */
                int id = omp_get_thread_num();
				int top=nSlices[d];
                Workspace *wsi = ws[id];
                wsi->warm = 0;
                
                #pragma omp parallel for
                for(j=0;j<top;j++){
                    /* Find slice starting point */
                    idx1 = (j / incs[d])*incs[d]*ns[d] + (j % incs[d]);
                
                    /* Construct slice */
                    for(k=0,idx2=0 ; k<ns[d] ; k++,idx2+=incs[d])
                        wsi->in[k] = z[idx1+idx2] + q[idx1+idx2];
                        
                    #ifdef DEBUG
                    {
                        int dbgi;
                        printf("Slice %d: ",j);
                        for(dbgi=0;dbgi<ns[d];dbgi++)
                            printf("%lf ",slice[dbgi]);
                        printf("\n");
                    }
                    #endif
                    
                    /* Apply 1-dimensional solver */
                    switch((int)norms[1]){
                        case 1: PN_TV1(wsi->in,lambdas[1],wsi->out,NULL,ns[d],SIGMA,wsi); break;
                        case 2: morePG_TV2(wsi->in,lambdas[1],wsi->out,NULL,ns[d],wsi); break;
                    }
                    
                    /* Plug solution back */
                    for(k=0,idx2=0 ; k<ns[d] ; k++,idx2+=incs[d])
                        x[idx1+idx2] = wsi->out[k];
                }
            }
            
            /* Update q */
            #pragma omp parallel for shared(q,z,x,n) private(i) default(none)  
            for(i=0;i<n;i++)
                q[i] += z[i] - x[i];
        }
        else{
            #pragma omp parallel for shared(z,x,n) private(i) default(none)  
            for(i=0;i<n;i++)
                x[i] = z[i];
            memcpy(x,z,nBytes);
        }
        
        /* Compute stopping criterion: mean change */
        stop = 0;
        #pragma omp parallel for shared(x,xLast,n) private(k) reduction(+:stop) default(none)  
        for(k=0;k<n;k++)
            stop += fabs(x[k]-xLast[k]);
        stop /= n;
        
        iters++;
    }
    
    /* Gather output information */
    if(info){
        info[INFO_ITERS] = iters;
        info[INFO_GAP] = stop;
    }
    
    /* Termination check */
    if(iters >= MAX_ITERS_PD){
        #ifdef DEBUG
            printf("(PD2_TV) WARNING: maximum number of iterations reached (%d).\n",MAX_ITERS_PD);
        #endif
        if(info) info[INFO_RC] = RC_ITERS;
    }
    else if(info) info[INFO_RC] = RC_OK;
    
    FREE
    return 1;
    
    #undef FREE
    #undef CANCEL
}

/* Creates and initiallizes a workspace structure */
Workspace* newWorkspace(int n){
    Workspace *ws;
    int i;
    
    #define CANCEL \
        freeWorkspace(ws); \
        return NULL;

    /* Alloc structure */
    ws = (Workspace*)calloc(1,sizeof(Workspace));
    if(!ws) {CANCEL}
    
    /* Alloc input and output fields */
    ws->in = (double*)malloc(sizeof(double)*n);
    ws->out = (double*)malloc(sizeof(double)*n);
    if(!ws->in || !ws->out) {CANCEL}
    
    /* Alloc generic double fields */
    ws->d = (double**)calloc(WS_DOUBLES,sizeof(double*));
    if(!ws->d) {CANCEL}
    for(i=0;i<WS_DOUBLES;i++){
        ws->d[i] = (double*)malloc(sizeof(double)*n);
        if(!ws->d[i]) {CANCEL} 
    }
    
    /* Alloc generic int fields */
    ws->i = (int**)calloc(WS_DOUBLES,sizeof(int*));
    if(!ws->i) {CANCEL}
    for(i=0;i<WS_INTS;i++){
        ws->i[i]  = (int*)malloc(sizeof(int)*n);
        if(!ws->i[i]) {CANCEL} 
    }
    
    /* Alloc warm restart fields */
    ws->warmDual = (double*)malloc(sizeof(double)*(n-1));
    if(!ws->warmDual) {CANCEL}
    
    /* Stablish number of iterations for inner solvers */
    ws->maxIters = MAX_ITERS_PD_INNER;
        
    return ws;
    
    #undef CANCEL
}

/* Frees a workspace structure */
void freeWorkspace(Workspace *ws){
    int i;

    if(ws){
        /* Input/output fields */
        if(ws->in) free(ws->in);
        if(ws->out) free(ws->out);
        /* Generic memory fields */
        if(ws->d){
            for(i=0;i<WS_DOUBLES;i++) if(ws->d[i]) free(ws->d[i]);
            free(ws->d);
        }
        if(ws->i){
            for(i=0;i<WS_INTS;i++) if(ws->i[i]) free(ws->i[i]);
            free(ws->i);
        }
        /* Warm restart fields */
        if(ws->warmDual) free(ws->warmDual);
        
        free(ws);
    }
}

/* Allocs memory for an array of p workspaces */
Workspace** newWorkspaces(int n,int p){
    int i;
    Workspace **wa=NULL;
    
    #define CANCEL \
        freeWorkspaces(wa,p); \
        return NULL;
    
    /* Alloc the array */
    wa = (Workspace**)calloc(p,sizeof(Workspace*));
    if(!wa) {CANCEL}
    
    /* Alloc each individual workspace */
    for(i=0;i<p;i++){
        wa[i] = newWorkspace(n);
        if(!wa[i]) {CANCEL}
    }
    
    return wa;
}

/* Frees an array of p workspaces */
void freeWorkspaces(Workspace **wa,int p){
    int i;
    
    if(wa){
        /* Free each workspace */
        for(i=0;i<p;i++) freeWorkspace(wa[i]);
        /* Free array */
        free(wa);
    }
}



