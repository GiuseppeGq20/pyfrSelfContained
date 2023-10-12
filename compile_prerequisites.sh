#!/bin/bash

# script to bootstrap the required PYFR environment and library

# this variable are the basenames of the tar archives
libffi=libffi-3.4.4
python=Python-3.11.6
sqlite=sqlite-autoconf-3430200

gk_repo=https://github.com/KarypisLab/GKlib.git
gk_tag=master

metis_repo=https://github.com/KarypisLab/METIS.git
metis_tag=v5.2.1
metis_patch=CMakeList.txt.patch

libxsmm_repo=https://github.com/libxsmm/libxsmm.git
libxsmm_tag=main_stable

# number of processes tu use with make
n_make=48

#source environments variables needed


module purge
module load gcc/11.2.0
module load openmpi/gcc112/4.1.1
module load hdf5/1.12.1/openmpi/gcc112
module load ROCm/5.7.0


mkdir locals

PREFIX=$(pwd)/locals

export PATH=$PREFIX/bin:$PATH
export LD_LIBRARY_PATH=$PREFIX/lib:$PREFIX/lib64:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$PREFIX/lib64:$LD_LIBRARY_PATH
export LD_RUN_PATH=$PREFIX/lib:$PREFIX/lib64:$LD_RUN_PATH

export LIBRARY_PATH=$PREFIX/lib:$PREFIX/lib64:$LIBRARY_PATH

export INCLUDE=$PREFIX/include:$INCLUDE
export C_INCLUDE_PATH=$PREFIX/include:$C_INCLUDE_PATH
export MANPATH=$PREFIX/share/man:$MANPATH


# build and install libffi

if [ ! -d $libffi ]; then

tar -xvzf $libffi.tar.gz
cd $libffi
./configure --prefix=$PREFIX 2>&1 | tee ../$libffi.configure.log
make -j $n_make 2>&1 | tee ../$libffi.make.log
make install 2>&1 | tee ../$libffi.install.log
cd ..

fi

# build and install sqlite
if [ ! -d $sqlite ]; then

tar -xvzf $sqlite.tar.gz
cd $sqlite
./configure --prefix=$PREFIX 2>&1 | tee ../$sqlite.configure.log
make -j $n_make 2>&1 | tee ../$sqlite.make.log
make install 2>&1 | tee ../$sqlite.install.log
cd ..

fi


# build and install python3.11
if [ ! -d $python ]; then

tar -xvzf $python.tgz
cd $python
export LDFLAGS=-L$PREFIX/lib64 && echo "adjust LDFLAGS to point to location of libffi"
./configure --enable-optimizations --with-lto --prefix=$PREFIX 2>&1 | tee ../$python.configure.log
make -j $n_make 2>&1 | tee ../$python.make.log
make install 2>&1 | tee ../$python.install.log
cd ..

fi



#buil and install metis

## dowload GKlib and METIS

### build gk

gk="${gk_repo##*/}"
gk="${gk%.*}"

if [ ! -d $gk ]; then

git clone --depth=1 --branch $gk_tag $gk_repo && echo "clone GKLib at $gk_repo and tag $gk_tag"
cd $gk
make config prefix=$PREFIX 2>&1 | tee ../$gk.configure.log
make -j $n_make 2>&1 | tee ../$gk.make.log
make install 2>&1 | tee ../$gk.install.log
cd ..

fi


### build metis

metis="${metis_repo##*/}"
metis="${metis%.*}"

if [ ! -d $metis ]; then

git clone --depth=1 --branch $metis_tag $metis_repo && echo "clone $metis at $metis_repo and tag $metis_tag"
cd $metis
cp ../etc/$metis_patch libmetis/CMakeLists.txt && echo "patch metis to link to GKlib when building it as .so"
make config shared=1 prefix=$PREFIX gklib_path=$PREFIX 2>&1 | tee ../$metis.configure.log
make -j $n_make 2>&1 | tee ../$metis.make.log
make install 2>&1 | tee ../$metis.install.log
cd ..

fi

## build libxsmm

libxsmm="${libxsmm_repo##*/}"
libxsmm="${libxsmm%.*}"

echo $libxsmm
if [ ! -d $libxsmm ]; then

git clone --depth=1 --branch $libxsmm_tag $libxsmm_repo && echo "clone $libxsmm at $libxsmm_repo and tag $libxsmm_tag" 
cd $libxsmm
make -j $n_make STATIC=0 BLAS=0 PREFIX=$PREFIX install 2>&1 | tee ../$libxsmm.make.log
cd ..

fi

