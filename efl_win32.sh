#! /bin/bash

E_URL="http://download.enlightenment.org/releases/"

base=`pwd`

export TARGET=i686-w64-mingw32
export MINGW_PREFIX="$base/package/"

export CPPFLAGS="-I$MINGW_PREFIX/include -I$MINGW_PREFIX/include/evil-1"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="$LDFLAGS -L$MINGW_PREFIX/lib"
export PATH="$HOME/local/opt/mingw-w64-x86_32/bin:$MINGW_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$MINGW_PREFIX/lib"
export PKG_CONFIG_PATH="$MINGW_PREFIX/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$MINGW_PREFIX/lib/pkgconfig"

update="no"
packaging="no"
revision="1.7.3"

deps_bin="autoreconf automake g++ gcc libtool pkg-config"
packages="evil eina eet evas ecore embryo eio edje efreet elementary"


declare -A packages_opt
packages_opt=( ["evil"]="--with-windows-version=win"
               ["eina"]=""
	       ["eet"]="--disable-gnutls --disable-openssl"
	       ["evas"]="--disable-async-preload --disable-async-render --disable-direct3d"
	       ["ecore"]="--disable-glib --enable-win32-threads=yes --disable-gnutls --disable-openssl"
	       ["embryo"]=""
	       ["eio"]="--enable-win32-threads=yes"
	       ["edje"]="--disable-edje-recc --enable-build-examples --with-edje-cc=$base/package/bin/edje_cc"
	       ["efreet"]=""
	       ["elementary"]="--with-edje-cc=/home/torri/local/e17/bin/edje_cc --with-eet-eet=/home/torri/local/e17/bin/eet --enable-win32-threads=yes -enable-build-examples"
             )

function check_deps ()
{
    echo "- basic dependency check:"
    max=23
    for dep in $deps_bin $make `echo "$cmd_src_checkout" | cut -d' ' -f1`; do
	cnt=${#dep}

	echo -n "  - '$dep' "
	while [ ! $cnt = $max ]; do
            echo -n "."
            cnt=$(($cnt+1))
	done
	echo -n " "

	if [ `type $dep &>/dev/null; echo $?` -ne 0 ]; then
	    echo -e "\033[1mNOT INSTALLED!\033[0m"
	    error "Command missing!"
	    exit -1
	else
	    echo "ok"
	fi
    done
}

function get_packages ()
{
    echo "- get packages:"
    for pkg in $packages; do
	if [ "$pkg" == "evil" ]; then
	    if [ "$revision" == "1.7.3" ]; then
		if [ ! -f $pkg-1.7.2.tar.bz2 ]; then
		    echo "wget $E_URL/$pkg-1.7.2.tar.bz2"
		    wget $E_URL/$pkg-1.7.2.tar.bz2 &> /dev/null
		fi
	    fi
	else
	    if [ ! -f $pkg-$revision.tar.bz2 ]; then
		echo "wget $E_URL/$pkg-$revision.tar.bz2"
		wget $E_URL/$pkg-$revision.tar.bz2 &> /dev/null
	    fi
	fi
    done
}

function untar_packages ()
{
    echo "- untar packages:"
    for pkg in $packages; do
	if [ "$pkg" == "evil" ]; then
	    if [ "$revision" == "1.7.3" ]; then
		if [ ! -d $base/src/$pkg-1.7.2 ]; then
		    echo "untar $pkg-1.7.2.tar.bz2"
		    tar jxvf $base/$pkg-1.7.2.tar.bz2 -C src/ &> /dev/null
		fi
	    fi
	else
	    if [ ! -d $base/src/$pkg-$revision ]; then
		echo "untar $pkg-$revision.tar.bz2"
		tar jxvf $base/$pkg-$revision.tar.bz2 -C src/ &> /dev/null
	    fi
	fi
    done

}

function build_packages ()
{
    echo "- build packages:"
    for pkg in $packages; do
	if [ "$pkg" == "evil" ]; then
	    if [ "$revision" == "1.7.3" ]; then
		if [ -d $base/src/$pkg-1.7.2 ]; then
		    cd $base/src/$pkg-1.7.2
		else
		    echo "error directory $base/src/$pkg-1.7.2 not found"
		    exit -1
		fi
	    fi
	else
	    if [ -d $base/src/$pkg-$revision ]; then
		cd $base/src/$pkg-$revision
	    else
		echo "error directory $pkg-$revision not found"
		exit -1;
	    fi
	fi
	echo "building $pkg"
	make maintainer-clean #&> /dev/null
	echo "autogen $pkg with options --prefix=$MINGW_PREFIX --host=$TARGET --disable-static ${packages_opt[$pkg]}"
	
	./autogen.sh --prefix=$MINGW_PREFIX --host=$TARGET --disable-static ${packages_opt[$pkg]} #&> /dev/null
	echo "make $pkg"
	make install || exit -1 #&> /dev/null || exit 1
	#   make distcheck DISTCHECK_CONFIGURE_FLAGS="--host=$TARGET ${options[${i}]}" || exit 1


    done
}

check_deps

if [ ! -f efl_dep.zip ]; then
    wget http://www.maths.univ-evry.fr/pages_perso/vtorri/files/efl_dep.zip &> /dev/null
fi

rm -rf $base/package/
rm -rf $base/src/
mkdir -p $base/package
cd $base/package
unzip ../efl_dep.zip &> /dev/null
cd $base
mkdir $base/src
get_packages
untar_packages
build_packages
exit 0
