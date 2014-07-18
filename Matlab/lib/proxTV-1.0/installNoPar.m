disp('Installing proxTV with no multi-thread support...');
cd src
mex -lmwblas -lmwlapack -lm CXXOPTIMFLAGS=-O3 CXXFLAGS="\$CFLAGS" LDFLAGS="\$LDFLAGS" solveTV1_PNc.cpp TVopt.cpp
mex -lmwblas -llapack -lm CXXOPTIMFLAGS=-O3 CXXFLAGS="\$CFLAGS" LDFLAGS="\$LDFLAGS" solveTV2_morec2.cpp TVopt.cpp
mex -lmwblas -llapack -lm CXXOPTIMFLAGS=-O3 CXXFLAGS="\$CFLAGS" LDFLAGS="\$LDFLAGS" solveTVgen_PDykstrac.cpp TVopt.cpp
cd ..
disp('proxTV successfully installed.');
