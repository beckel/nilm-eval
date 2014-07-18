disp('Installing proxTV...');
cd src
mex -lmwblas -lmwlapack -lm CXXOPTIMFLAGS=-O3 CXXFLAGS="\$CFLAGS -fopenmp" LDFLAGS="\$LDFLAGS -fopenmp" solveTV1_PNc.cpp TVopt.cpp
mex -lmwblas -lmwlapack -lm CXXOPTIMFLAGS=-O3 CXXFLAGS="\$CFLAGS -fopenmp" LDFLAGS="\$LDFLAGS -fopenmp" solveTV2_morec2.cpp TVopt.cpp
mex -lmwblas -lmwlapack -lm CXXOPTIMFLAGS=-O3 CXXFLAGS="\$CFLAGS -fopenmp" LDFLAGS="\$LDFLAGS -fopenmp" solveTVgen_PDykstrac.cpp TVopt.cpp
cd ..
disp('proxTV successfully installed.');
