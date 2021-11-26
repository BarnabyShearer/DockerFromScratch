#syntax=docker/dockerfile:1.2-labs
# Huge props to http://www.linuxfromscratch.org/ and all the upstreams.
# ~ https://www.linuxfromscratch.org/lfs/view/10.1/
# ~ https://www.linuxfromscratch.org/blfs/view/10.1/

FROM gcc:10.2.0 AS cross

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LC_ALL=POSIX \
    PATH=/mnt/lfs/tools/bin:$PATH

WORKDIR /mnt/lfs/build

ADD https://ftp.gnu.org/gnu/binutils/binutils-2.35.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo fc8d55e2f6096de8ff8171173b6f5087 ../binutils-2.35.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../binutils-2.35.tar.xz \
    && ./configure \
        --prefix=/mnt/lfs/tools \
        --with-sysroot=/mnt/lfs \
        --target="$(uname -m)"-lfs-linux-gnu \
        --disable-nls \
        --disable-werror \
    && make -j16 \
    && make install-strip \
    ;

ADD https://ftp.gnu.org/gnu/gcc/gcc-10.2.0/gcc-10.2.0.tar.xz \
    https://www.mpfr.org/mpfr-4.1.0/mpfr-4.1.0.tar.xz \
    https://ftp.gnu.org/gnu/gmp/gmp-6.2.0.tar.xz \
    https://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz \
    ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo e9fd9b1789155ad09bcf3ae747596b50 ../gcc-10.2.0.tar.xz | md5sum --quiet --strict --check - \
    && echo bdd3d5efba9c17da8d83a35ec552baef ../mpfr-4.1.0.tar.xz | md5sum --quiet --strict --check - \
    && echo a325e3f09e6d91e62101e59f9bda3ec1 ../gmp-6.2.0.tar.xz | md5sum --quiet --strict --check - \
    && echo 4125404e41e482ec68282a2e687f6c73 ../mpc-1.1.0.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../gcc-10.2.0.tar.xz \
    && mkdir mpfr && tar -C mpfr --strip-components=1 -xf ../mpfr-4.1.0.tar.xz \
    && mkdir gmp && tar -C gmp --strip-components=1 -xf ../gmp-6.2.0.tar.xz \
    && mkdir mpc && tar -C mpc --strip-components=1 -xf ../mpc-1.1.0.tar.gz \
    && mkdir build && cd build \
    && ../configure \
        --target="$(uname -m)"-lfs-linux-gnu \
        --prefix=/mnt/lfs/tools \
        --with-glibc-version=2.11 \
        --with-sysroot=/mnt/lfs \
        --with-newlib \
        --without-headers \
        --enable-initfini-array \
        --disable-nls \
        --disable-shared \
        --disable-multilib \
        --disable-decimal-float \
        --disable-threads \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libssp \
        --disable-libvtv \
        --disable-libstdcxx \
        --enable-languages=c,c++ \
    && make -j16 \
    && make install-strip \
    && cat ../gcc/limitx.h ../gcc/glimits.h ../gcc/limity.h > \
        "$(dirname "$("$(uname -m)"-lfs-linux-gnu-gcc -print-libgcc-file-name)")"/install-tools/include/limits.h \
    ;

#ADD https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.8.3.tar.xz ..
ADD https://www.mirrorservice.org/sites/ftp.kernel.org/pub/linux/kernel/v5.x/linux-5.8.3.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 2656fe1a0942856c8740468d175e39b6 ../linux-5.8.3.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../linux-5.8.3.tar.xz \
    && make mrproper \
    && make headers \
    && find usr/include -name '.*' -delete \
    && rm usr/include/Makefile \
    && mkdir /mnt/lfs/usr \
    && cp -rv usr/include /mnt/lfs/usr \
    ;

ADD https://ftp.gnu.org/gnu/gawk/gawk-5.1.0.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 8470c34eeecc41c1aa0c5d89e630df50 ../gawk-5.1.0.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../gawk-5.1.0.tar.xz \
    && sed -i 's/extras//' Makefile.in \
    && ./configure \
        --build="$(./config.guess)" \
    && make -j16 \
    && make install-strip \
    ;

ADD https://ftp.gnu.org/gnu/bison/bison-3.7.1.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo e7c8c321351ebdf70f5f0825f3faaee2 ../bison-3.7.1.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../bison-3.7.1.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

ADD https://ftp.gnu.org/gnu/glibc/glibc-2.32.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 720c7992861c57cf97d66a2f36d8d1fa ../glibc-2.32.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../glibc-2.32.tar.xz \
    && mkdir build && cd build \
    && ../configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(../scripts/config.guess)" \
        --enable-kernel=3.2 \
        --with-headers=/mnt/lfs/usr/include \
        libc_cv_slibdir=/lib64 \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install \
    && /mnt/lfs/tools/libexec/gcc/"$(uname -m)"-lfs-linux-gnu/10.2.0/install-tools/mkheaders \
    ;

RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    tar --strip-components=1 -xf ../gcc-10.2.0.tar.xz \
    && mkdir build && cd build \
    && ../libstdc++-v3/configure \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(../config.guess)" \
        --prefix=/usr \
        --disable-multilib \
        --disable-nls \
        --disable-libstdcxx-pch \
        --with-gxx-include-dir=/tools/"$(uname -m)"-lfs-linux-gnu/include/c++/10.2.0 \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD https://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 730bb15d96fffe47e148d1e09235af82 ../m4-1.4.18.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../m4-1.4.18.tar.xz \
    && sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c \
    && echo '#define _IO_IN_BACKUP 0x100' >> lib/stdio-impl.h \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(build-aux/config.guess)" \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD https://ftp.gnu.org/gnu/ncurses/ncurses-6.2.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo e812da327b1c2214ac1aed440ea3ae8d ../ncurses-6.2.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../ncurses-6.2.tar.gz \
    && mkdir build && cd build \
    && ../configure \
    && make -C include \
    && make -C progs tic \
    && cd .. \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(./config.guess)" \
        --mandir=/usr/share/man \
        --with-manpage-format=normal \
        --with-shared \
        --without-debug \
        --without-ada \
        --without-normal \
        --enable-widec \
    && make -j16 \
    && make DESTDIR=/mnt/lfs TIC_PATH="$(pwd)"/build/progs/tic install \
    && echo 'INPUT(-lncursesw)' > /mnt/lfs/usr/lib/libncurses.so \
    ;

ADD https://ftp.gnu.org/gnu/bash/bash-5.0.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 2b44b47b905be16f45709648f671820b ../bash-5.0.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../bash-5.0.tar.gz \
    && ./configure \
        --prefix=/usr \
        --build="$(support/config.guess)" \
        --host="$(uname -m)"-lfs-linux-gnu \
        --without-bash-malloc \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    && ln -sv bash /mnt/lfs/usr/bin/sh \
    ;

ADD https://ftp.gnu.org/gnu/patch/patch-2.7.6.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 78ad9937e4caadcba1526ef1853730d5 ../patch-2.7.6.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../patch-2.7.6.tar.xz \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(build-aux/config.guess)" \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD https://ftp.gnu.org/gnu/coreutils/coreutils-8.32.tar.xz ..
ADD http://git.savannah.gnu.org/cgit/coreutils.git/patch/?id=10fcb97bd728f09d4a027eddf8ad2900f0819b0a ../coreutils-8.32_arm64_backport.patch
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 022042695b7d5bcf1a93559a9735e668 ../coreutils-8.32.tar.xz | md5sum --quiet --strict --check - \
    && echo 5248671fb52cff655fd02606416484ea ../coreutils-8.32_arm64_backport.patch | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../coreutils-8.32.tar.xz \
    && patch -p1 -i ../coreutils-8.32_arm64_backport.patch \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(build-aux/config.guess)" \
        --enable-install-program=hostname \
        --enable-no-install-program=kill,uptime \
    && make -j16 \
    && make DESTDIR=/mnt/lfs/mnt/bash install-strip \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD https://ftp.gnu.org/gnu/diffutils/diffutils-3.7.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 4824adc0e95dbbf11dfbdfaad6a1e461 ../diffutils-3.7.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../diffutils-3.7.tar.xz \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD http://ftp.astron.com/pub/file/file-5.39.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 1c450306053622803a25647d88f80f25 ../file-5.39.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../file-5.39.tar.gz \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD https://ftp.gnu.org/gnu/findutils/findutils-4.7.0.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 731356dec4b1109b812fecfddfead6b2 ../findutils-4.7.0.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../findutils-4.7.0.tar.xz \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(build-aux/config.guess)" \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    tar --strip-components=1 -xf ../gawk-5.1.0.tar.xz \
    && sed -i 's/extras//' Makefile.in \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(./config.guess)" \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD https://ftp.gnu.org/gnu/grep/grep-3.4.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 111b117d22d6a7d049d6ae7505e9c4d2 ../grep-3.4.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../grep-3.4.tar.xz \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD https://ftp.gnu.org/gnu/gzip/gzip-1.10.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 691b1221694c3394f1c537df4eee39d3 ../gzip-1.10.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../gzip-1.10.tar.xz \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD https://ftp.gnu.org/gnu/make/make-4.3.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo fc7a67ea86ace13195b0bce683fd4469 ../make-4.3.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../make-4.3.tar.gz \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(build-aux/config.guess)" \
        --without-guile \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD https://ftp.gnu.org/gnu/sed/sed-4.8.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 6d906edfdb3202304059233f51f9a71d ../sed-4.8.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../sed-4.8.tar.xz \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

ADD https://ftp.gnu.org/gnu/tar/tar-1.32.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo 83e38700a80a26e30b2df054e69956e5 ../tar-1.32.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../tar-1.32.tar.xz \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(build-aux/config.guess)" \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

#ADD https://tukaani.org/xz/xz-5.2.5.tar.xz ..
ADD https://slackware.uk/slackware/slackware-current/source/a/xz/xz-5.2.5.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    echo aa1621ec7013a19abab52a8aff04fe5b ../xz-5.2.5.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../xz-5.2.5.tar.xz \
    && ./configure \
        --prefix=/usr \
        --host="$(uname -m)"-lfs-linux-gnu \
        --build="$(build-aux/config.guess)" \
        --disable-static \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    tar --strip-components=1 -xf ../binutils-2.35.tar.xz \
    && mkdir build && cd build \
    && ../configure \
        --prefix=/usr \
        --build="$(../config.guess)" \
        --host="$(uname -m)"-lfs-linux-gnu \
        --disable-nls \
        --enable-shared \
        --disable-werror \
        --enable-64-bit-bfd \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/mnt/lfs/build \
    tar --strip-components=1 -xf ../gcc-10.2.0.tar.xz \
    && mkdir mpfr && tar -C mpfr --strip-components=1 -xf ../mpfr-4.1.0.tar.xz \
    && mkdir gmp && tar -C gmp --strip-components=1 -xf ../gmp-6.2.0.tar.xz \
    && mkdir mpc && tar -C mpc --strip-components=1 -xf ../mpc-1.1.0.tar.gz \
    && mkdir build && cd build \
    && mkdir -pv "$(uname -m)"-lfs-linux-gnu/libgcc \
    && ln -s ../../../libgcc/gthr-posix.h "$(uname -m)"-lfs-linux-gnu/libgcc/gthr-default.h \
    && ../configure \
        --build="$(../config.guess)" \
        --host="$(uname -m)"-lfs-linux-gnu \
        --prefix=/usr \
        CC_FOR_TARGET="$(uname -m)"-lfs-linux-gnu-gcc \
        --with-build-sysroot=/mnt/lfs \
        --enable-initfini-array \
        --disable-nls \
        --disable-multilib \
        --disable-decimal-float \
        --disable-libatomic \
        --disable-libgomp \
        --disable-libquadmath \
        --disable-libssp \
        --disable-libvtv \
        --disable-libstdcxx \
        --enable-languages=c,c++ \
    && make -j16 \
    && make DESTDIR=/mnt/lfs install-strip \
    && ln -sv gcc /mnt/lfs/usr/bin/cc \
    ;

RUN --network=none \
    rm -Rf /mnt/lfs/build/ /mnt/lfs/tools/ \
    && ln -s usr/bin /mnt/lfs/bin \
    && [ "$(uname -m)" = "aarch64" ] && mkdir /mnt/lfs/lib && ln -s ../lib64/ld-2.32.so /mnt/lfs/lib/ld-linux-aarch64.so.1 || true \
    && mkdir /mnt/lfs/tmp \
    && chmod 1777 /mnt/lfs/tmp \
    ;

FROM scratch AS build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /build/
COPY --from=cross --chown=0:0 /mnt/lfs/ /

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../gcc-10.2.0.tar.xz \
    && ln -s gthr-posix.h libgcc/gthr-default.h \
    && mkdir build && cd build \
    && ../libstdc++-v3/configure \
        CXXFLAGS="-g -O2 -D_GNU_SOURCE" \
        --prefix=/usr \
        --disable-multilib \
        --disable-nls \
        --host="$(uname -m)"-lfs-linux-gnu \
        --disable-libstdcxx-pch \
    && make -j16 \
    && make install-strip \
    ;

ADD https://ftp.gnu.org/gnu/gettext/gettext-0.21.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 40996bbaf7d1356d3c22e33a8b255b31 ../gettext-0.21.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../gettext-0.21.tar.xz \
    && ./configure \
        --disable-shared \
    && make -j16 \
    && cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin \
    ;

ADD https://ftp.gnu.org/gnu/bison/bison-3.7.1.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo e7c8c321351ebdf70f5f0825f3faaee2 ../bison-3.7.1.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../bison-3.7.1.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

ADD https://www.cpan.org/src/5.0/perl-5.32.0.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 3812cd9a096a72cb27767c7e2e40441c ../perl-5.32.0.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../perl-5.32.0.tar.xz \
    && sh Configure \
        -des \
        -Dprefix=/usr \
        -Dvendorprefix=/usr \
        -Dprivlib=/usr/lib/perl5/5.32/core_perl \
        -Darchlib=/usr/lib/perl5/5.32/core_perl \
        -Dsitelib=/usr/lib/perl5/5.32/site_perl \
        -Dsitearch=/usr/lib/perl5/5.32/site_perl \
        -Dvendorlib=/usr/lib/perl5/5.32/vendor_perl \
        -Dvendorarch=/usr/lib/perl5/5.32/vendor_perl \
    && make -j16 \
    && make install-strip \
    ;

ADD https://www.python.org/ftp/python/3.8.5/Python-3.8.5.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 35b5a3d0254c1c59be9736373d429db7 ../Python-3.8.5.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../Python-3.8.5.tar.xz \
    && ./configure \
        --prefix=/usr \
        --enable-shared \
        --without-ensurepip \
    && make \
    && make install \
    ;

RUN find /usr/{lib,libexec} -name \*.la -delete \
    && rm -rf /usr/share/{info,man,doc}/* \
    ;

ADD https://github.com/Mic92/iana-etc/releases/download/20200821/iana-etc-20200821.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo ff19c45f5ac800f5d77c680d9b757fbc ../iana-etc-20200821.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../iana-etc-20200821.tar.gz \
    && cp services protocols /etc \
    ;

# hadolint ignore=SC2016
RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../glibc-2.32.tar.xz \
    && mkdir build && cd build \
    && ../configure \
        --prefix=/usr \
        --disable-werror \
        --enable-stack-protector=strong \
        --enable-kernel=3.2 \
        --with-headers=/usr/include \
        libc_cv_slibdir=/lib64 \
    && make -j16 \
    && sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile \
    && make DESTDIR=/mnt/base install \
    && make install \
    && cp -v ../nscd/nscd.conf /etc/nscd.conf \
    && cp -v ../nscd/nscd.conf /mnt/base/etc/nscd.conf \
    && mkdir -pv /var/cache/nscd \
    && mkdir -pv /usr/lib/locale \
    && mkdir -pv /mnt/base/var/cache/nscd \
    && mkdir -pv /mnt/base/usr/lib/locale \
    && localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true \
    && localedef -i en_GB -f UTF-8 en_GB.UTF-8 \
    ;

ADD https://www.iana.org/time-zones/repository/releases/tzdata2020a.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 96a985bb8eeab535fb8aa2132296763a ../tzdata2020a.tar.gz | md5sum --quiet --strict --check - \
    && tar -xf ../tzdata2020a.tar.gz \
    && mkdir -pv /usr/share/zoneinfo/{posix,right} \
    && for tz in \
        etcetera \
        southamerica \
        northamerica \
        europe \
        africa \
        antarctica \
        asia \
        australasia \
        backward \
        pacificnew \
        systemv \
    ; do \
        zic -L /dev/null -d /usr/share/zoneinfo ${tz} \
        && zic -L /dev/null -d /usr/share/zoneinfo/posix ${tz} \
        && zic -L leapseconds -d /usr/share/zoneinfo/right ${tz} \
    ; done \
    && cp -v zone.tab zone1970.tab iso3166.tab /usr/share/zoneinfo \
    && zic -d /usr/share/zoneinfo -p Europe/London \
    && ln -sfv /usr/share/zoneinfo/Europe/London /etc/localtime \
    && mkdir -p /mnt/base/usr/share \
    && cp -r /usr/share/zoneinfo /mnt/base/usr/share \
    && ln -sfv ../usr/share/zoneinfo/Europe/London /mnt/base/etc/localtime \
    ;

ADD https://zlib.net/zlib-1.2.11.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 85adef240c5f370b308da8c938951a68 ../zlib-1.2.11.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../zlib-1.2.11.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make DESTDIR=/mnt/base install \
    && make install \
    ;

ADD https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 67e051268d0c475ea773822f7500d0e5 ../bzip2-1.0.8.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../bzip2-1.0.8.tar.gz \
    && make -f Makefile-libbz2_so \
    && make clean \
    && make -j16 \
    && ln -sv libbz2.so.1.0 libbz2.so \
    && make PREFIX=/usr DESTDIR=/mnt/base install \
    && cp -av libbz2.so* /mnt/base/usr/lib \
    && make PREFIX=/usr install \
    && cp -av libbz2.so* /usr/lib \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../xz-5.2.5.tar.xz \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make -j16 \
    && make DESTDIR=/mnt/base install-strip \
    && make install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../file-5.39.tar.gz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

ADD https://ftp.gnu.org/gnu/readline/readline-8.0.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 7e6c1f16aee3244a69aba6e438295ca3 ../readline-8.0.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../readline-8.0.tar.gz \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --with-curses \
    && make SHLIB_LIBS="-lncursesw" -j16 \
    && make SHLIB_LIBS="-lncursesw" DESTDIR=/mnt/bash install \
    && make SHLIB_LIBS="-lncursesw" install \
    ;

ADD https://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../m4-1.4.18.tar.xz \
    && sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c \
    && echo '#define _IO_IN_BACKUP 0x100' >> lib/stdio-impl.h \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

ADD https://github.com/gavinhoward/bc/releases/download/3.1.5/bc-3.1.5.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo bd6a6693f68c2ac5963127f82507716f ../bc-3.1.5.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../bc-3.1.5.tar.xz \
    && PREFIX=/usr CC=gcc CFLAGS="-std=c99" ./configure.sh -G -O3 \
    && make -j16 \
    && make install \
    ;

ADD https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 2882e3179748cc9f9c23ec593d6adc8d ../flex-2.6.4.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../flex-2.6.4.tar.gz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../binutils-2.35.tar.xz \
    && mkdir build && cd build \
    && ../configure \
        --prefix=/usr \
         --enable-gold \
         --enable-ld=default \
         --enable-plugins \
         --enable-shared \
         --disable-werror \
         --enable-64-bit-bfd \
         --with-system-zlib \
    && make -j16 \
    && make tooldir=/usr install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../gmp-6.2.0.tar.xz \
    && cp -v configfsf.guess config.guess \
    && cp -v configfsf.sub config.sub \
    && ./configure \
        --prefix=/usr \
        --enable-cxx \
        --disable-static \
    && make -j16 \
    && make install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../mpfr-4.1.0.tar.xz \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --enable-thread-safe \
    && make -j16 \
    && make install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../mpc-1.1.0.tar.gz \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make -j16 \
    && make install-strip \
    ;

ADD https://download.savannah.gnu.org/releases/attr/attr-2.4.48.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo bc1e5cb5c96d99b24886f1f527d3bb3d ../attr-2.4.48.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../attr-2.4.48.tar.gz \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --sysconfdir=/etc \
    && make -j16 \
    && make install-strip \
    ;

ADD https://download.savannah.gnu.org/releases/acl/acl-2.2.53.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 007aabf1dbb550bcddde52a244cd1070 ../acl-2.2.53.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../acl-2.2.53.tar.gz \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --libexecdir=/usr/lib \
    && make -j16 \
    && make install-strip \
    ;

#ADD https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.42.tar.xz ..
ADD https://www.mirrorservice.org/sites/ftp.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.42.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo f22cd619e04ae7b88a6a0c109b9523eb ../libcap-2.42.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../libcap-2.42.tar.xz \
    && sed -i '/install -m.*STACAPLIBNAME/d' libcap/Makefile \
    && make -j16 \
    && make DESTDIR=/mnt/uwsgi install lib=lib64 \
    && make install lib=lib64 \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../gcc-10.2.0.tar.xz \
    && mkdir build && cd build \
    && ../configure \
        --prefix=/usr \
        LD=ld \
        --enable-languages=c,c++ \
        --disable-multilib \
        --disable-bootstrap \
        --with-system-zlib \
    && make -j16 \
    && make install-strip \
    && rm -rf /usr/lib/gcc/"$(gcc -dumpmachine)"/10.2.0/include-fixed/bits/ \
    && chown -v -R 0:0 /usr/lib/gcc/*linux-gnu/10.2.0/include{,-fixed} \
    && ln -sv ../usr/bin/cpp /lib \
    && install -v -dm755 /usr/lib/bfd-plugins \
    && ln -sfv ../../libexec/gcc/"$(gcc -dumpmachine)"/10.2.0/liblto_plugin.so /usr/lib/bfd-plugins/ \
    && mkdir -pv /usr/share/gdb/auto-load/usr/lib \
    && mv -v /usr/lib64/*gdb.py /usr/share/gdb/auto-load/usr/lib \
    ;

ADD https://pkg-config.freedesktop.org/releases/pkg-config-0.29.2.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo f6e931e319531b736fadc017f470e68a ../pkg-config-0.29.2.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../pkg-config-0.29.2.tar.gz \
    && ./configure \
        --prefix=/usr \
        --with-internal-glib \
        --disable-host-tool \
    && make -j16 \
    && make install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../ncurses-6.2.tar.gz \
    && sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in \
    && ./configure \
        --prefix=/usr \
        --with-shared \
        --without-debug \
        --without-normal \
        --enable-pc-files \
        --enable-widec \
    && make -j16 \
    && make DESTDIR=/mnt/python install \
    && make install \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../sed-4.8.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

# ADD https://prdownloads.sourceforge.net/psmisc/psmisc-23.3.tar.xz ..
ADD https://slackware.uk/slackware/slackware-current/source/a/procps-ng/psmisc-23.3.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 573bf80e6b0de86e7f307e310098cf86 ../psmisc-23.3.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../psmisc-23.3.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../gettext-0.21.tar.xz \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make -j16 \
    && make install-strip \
    && chmod -v 0755 /usr/lib/preloadable_libintl.so \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../bison-3.7.1.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../grep-3.4.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../bash-5.0.tar.gz \
    && ./configure \
        --prefix=/usr \
        --without-bash-malloc \
        --with-installed-readline \
    && make -j16 \
    && make DESTDIR=/mnt/bash install-strip \
    && make install-strip \
    ;

ADD https://ftp.gnu.org/gnu/libtool/libtool-2.4.6.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 1bfb9b923f2c1339b4d2ce1807064aa5 ../libtool-2.4.6.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../libtool-2.4.6.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

ADD https://ftp.gnu.org/gnu/gdbm/gdbm-1.18.1.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 988dc82182121c7570e0cb8b4fcd5415 ../gdbm-1.18.1.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../gdbm-1.18.1.tar.gz \
    && sed -r -i '/^char.*parseopt_program_(doc|args)/d' src/parseopt.c \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --enable-libgdbm-compat \
    && make -j16 \
    && make DESTDIR=/mnt/python install-strip \
    && make install-strip \
    ;

ADD https://ftp.gnu.org/gnu/gperf/gperf-3.1.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 9e251c0a618ad0824b51117d5d9db87e ../gperf-3.1.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../gperf-3.1.tar.gz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install \
    ;

#ADD https://prdownloads.sourceforge.net/expat/expat-2.2.9.tar.xz ..
ADD https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo d2384fa607223447e713e1b9bd272376 ../expat-2.2.9.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../expat-2.2.9.tar.xz \
    && ./configure \
        --prefix=/usr \
        --disable-static \
    && make -j16 \
    && make install-strip \
    ;

ADD https://ftp.gnu.org/gnu/inetutils/inetutils-1.9.4.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 87fef1fa3f603aef11c41dcc097af75e ../inetutils-1.9.4.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../inetutils-1.9.4.tar.xz \
    && ./configure \
        --prefix=/usr \
        --localstatedir=/var \
        --disable-logger \
        --disable-whois \
        --disable-rcp \
        --disable-rexec \
        --disable-rlogin \
        --disable-rsh \
        --disable-servers \
    && make -j16 \
    && make install-strip \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../perl-5.32.0.tar.xz \
    && export BUILD_ZLIB=False \
    && export BUILD_BZIP2=0 \
    && sh Configure \
        -des \
        -Dprefix=/usr \
        -Dvendorprefix=/usr \
        -Dprivlib=/usr/lib/perl5/5.32/core_perl \
        -Darchlib=/usr/lib/perl5/5.32/core_perl \
        -Dsitelib=/usr/lib/perl5/5.32/site_perl \
        -Dsitearch=/usr/lib/perl5/5.32/site_perl \
        -Dvendorlib=/usr/lib/perl5/5.32/vendor_perl \
        -Dvendorarch=/usr/lib/perl5/5.32/vendor_perl \
        -Dpager="/usr/bin/less -isR" \
        -Duseshrplib \
        -Dusethreads \
    && make -j16 \
    && make install-strip \
    ;

ADD https://cpan.metacpan.org/authors/id/T/TO/TODDR/XML-Parser-2.46.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 80bb18a8e6240fcf7ec2f7b57601c170 ../XML-Parser-2.46.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../XML-Parser-2.46.tar.gz \
    && perl Makefile.PL \
    && make -j16 \
    && make install \
    ;

ADD https://launchpad.net/intltool/trunk/0.51.0/+download/intltool-0.51.0.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 12e517cac2b57a0121cda351570f1e63 ../intltool-0.51.0.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../intltool-0.51.0.tar.gz \
    && sed -i 's:\\\${:\\\$\\{:' intltool-update.in \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

ADD https://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 50f97f4159805e374639a73e2636f22e ../autoconf-2.69.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../autoconf-2.69.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;
    
ADD https://ftp.gnu.org/gnu/automake/automake-1.16.2.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 6cb234c86f3f984df29ce758e6d0d1d7 ../automake-1.16.2.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../automake-1.16.2.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;
    
ADD https://sourceware.org/ftp/elfutils/0.180/elfutils-0.180.tar.bz2 ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 23feddb1b3859b03ffdbaf53ba6bd09b ../elfutils-0.180.tar.bz2 | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../elfutils-0.180.tar.bz2 \
    && ./configure \
        --prefix=/usr \
        --disable-debuginfod \
        --enable-libdebuginfod=dummy \
    && make -j16 \
    && make -C libelf install \
    && install -vm644 config/libelf.pc /usr/lib/pkgconfig \
    && rm /usr/lib/libelf.a \
    ;
    
ADD https://sourceware.org/pub/libffi/libffi-3.3.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 6313289e32f1d38a9df4770b014a2ca7 ../libffi-3.3.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../libffi-3.3.tar.gz \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --with-gcc-arch=native \
    && make -j16 \
    && make DESTDIR=/mnt/python install-strip \   
    && make install-strip \
    ;    

ADD https://www.openssl.org/source/openssl-1.1.1g.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 76766e98997660138cdaf13a187bd234 ../openssl-1.1.1g.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../openssl-1.1.1g.tar.gz \
    && ./Configure linux-"$(uname -m)" \
        --prefix=/usr \
        --openssldir=/etc/ssl \
        shared \
        zlib-dynamic \
    && make -j16 \
    && make DESTDIR=/mnt/base install_sw \
    && make install_sw \
    && ldconfig \
    ;

RUN --network=none --mount=type=tmpfs,target=/build \
    tar --strip-components=1 -xf ../Python-3.8.5.tar.xz \
    && ./configure \
        --prefix=/usr \
        --enable-shared \
        --with-system-expat \
        --with-system-ffi   \
        --with-ensurepip=yes \
    && make \
    && make DESTDIR=/mnt/python install \
    && make install \
    ;

ADD https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.16.0.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 531208de3729d42e2af0a32890f08736 ../libtasn1-4.16.0.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../libtasn1-4.16.0.tar.gz \
    && ./configure \
        --host="$(uname -m)"-lfs-linux-gnu \
        --prefix=/usr \
        --disable-static \
    && make -j16 \
    && make install-strip \
    ;

ADD https://github.com/p11-glue/p11-kit/releases/download/0.23.22/p11-kit-0.23.22.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 03f93a4eb62127b5d40e345c624a0665 ../p11-kit-0.23.22.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../p11-kit-0.23.22.tar.xz \
    && ./configure \
        --host="$(uname -m)"-lfs-linux-gnu \
        --prefix=/usr \
        --sysconfdir=/etc \
        --with-trust-paths=/etc/pki/anchors \
    && make -j16 \
    && make install-strip \
    ;

ADD https://github.com/djlucas/make-ca/releases/download/v1.7/make-ca-1.7.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo e0356f5ae5623f227a3f69b5e8848ec6 ../make-ca-1.7.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../make-ca-1.7.tar.xz \
    && make install \
    ;

ADD https://hg.mozilla.org/releases/mozilla-release/raw-file/default/security/nss/lib/ckfw/builtins/certdata.txt ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 347105b06db3b64594013675125a86d4 ../certdata.txt | md5sum --quiet --strict --check - \
    && cp ../certdata.txt . \
    && /usr/sbin/make-ca \
    ;

ADD http://xmlsoft.org/sources/libxml2-2.9.10.tar.gz ..
ADD http://www.linuxfromscratch.org/patches/blfs/10.1/libxml2-2.9.10-security_fixes-1.patch ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 10942a1dc23137a8aa07f0639cbfece5 ../libxml2-2.9.10.tar.gz | md5sum --quiet --strict --check - \
    && echo 8219ac0c91e7c79dac9cf45dbedb0708 ../libxml2-2.9.10-security_fixes-1.patch | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../libxml2-2.9.10.tar.gz \
    && patch -p1 -i ../libxml2-2.9.10-security_fixes-1.patch \
    && sed -i '/if Py/{s/Py/(Py/;s/)/))/}' python/{types.c,libxml.c} \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --with-history \
        --with-python=/usr/bin/python3 \
    && make -j16 \
    && make DESTDIR=/mnt/python install-strip \
    && make install-strip \
    ;

ADD http://xmlsoft.org/sources/libxslt-1.1.34.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo db8765c8d076f1b6caafd9f2542a304a ../libxslt-1.1.34.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../libxslt-1.1.34.tar.gz \
    && sed -i s/3000/5000/ libxslt/transform.c doc/xsltproc.{1,xml} \
    && ./configure \
        --prefix=/usr \
        --disable-static \
        --without-python \
    && make -j16 \
    && make DESTDIR=/mnt/python install-strip \
    && make install-strip \
    ;

ADD https://pyyaml.org/download/pyyaml/PyYAML-5.3.1.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo d3590b85917362e837298e733321962b ../PyYAML-5.3.1.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../PyYAML-5.3.1.tar.gz \
    && python3 setup.py build \
    && python3 setup.py install --optimize=1 --prefix=/mnt/python/usr \
    ;    

ADD https://files.pythonhosted.org/packages/source/l/lxml/lxml-4.6.2.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 2e39c6e17d61f61e5be68fd328ba6a51 ../lxml-4.6.2.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../lxml-4.6.2.tar.gz \
    && python3 setup.py build \
    && python3 setup.py install --optimize=1 --prefix=/mnt/python/usr \
    ;

ADD https://ftp.postgresql.org/pub/source/v13.2/postgresql-13.2.tar.bz2 ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo c7b352c2774d6c3e03bd2558c03da876 ../postgresql-13.2.tar.bz2 | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../postgresql-13.2.tar.bz2 \
    && ./configure \
        --prefix=/usr \
        --enable-thread-safety \
        --with-openssl \
        --with-python \
    && make -j16 \
    && make -C src/interfaces DESTDIR=/mnt/python install-strip \
    && make DESTDIR=/mnt/postgres install-strip \
    && make install-strip \
    && install -v -dm700 /mnt/postgres/srv/pgsql/data \
    && chown 41:41 /mnt/postgres/srv/pgsql/data \
    ;

ADD https://github.com/psycopg/psycopg2/archive/2_8_6.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo e01db8d822843c057ec3201ff1ebd8de ../2_8_6.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../2_8_6.tar.gz \
    && python3 setup.py build \
    && PYTHONPATH=/mnt/python/usr/lib/python3.8/site-packages/ python3 setup.py install --optimize=1 --prefix=/mnt/python/usr \
    ;

COPY group nsswitch.conf passwd /etc/

RUN --network=none \
    rm -Rf /build ../*.tar.* \
    && mkdir -p /mnt/base/etc/ssl/ \
    && cp -a /etc/group /etc/nsswitch.conf /etc/passwd /mnt/base/etc/ \
    && cp -a /etc/ssl/certs/ /mnt/base/etc/ssl/ \
    && mkdir /mnt/base/tmp \
    && chmod 1777 /mnt/base/tmp \
    && cp /usr/lib/locale/locale-archive /mnt/base/usr/lib/locale/locale-archive \
    && ln -s usr/bin /mnt/base/bin \
    && ln -s bash /mnt/bash/usr/bin/sh \
    && [ "$(uname -m)" = "aarch64" ] && mkdir /mnt/base/lib && ln -s ../lib64/ld-2.32.so /mnt/base/lib/ld-linux-aarch64.so.1 || true \
    ;

ENTRYPOINT ["/usr/bin/bash"]

FROM build AS build-uwsgi

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ADD https://projects.unbit.it/downloads/uwsgi-2.0.19.1.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo cfbc6b37c52ef745b4dac9361a950e77 ../uwsgi-2.0.19.1.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../uwsgi-2.0.19.1.tar.gz \
    && python3 ./uwsgiconfig.py --build \
    && mkdir -p /mnt/uwsgi/usr/bin \
    && cp uwsgi /mnt/uwsgi/usr/bin \
    ;

FROM build AS build-nginx

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ADD https://ftp.exim.org/pub/pcre/pcre-8.44.tar.bz2 ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo cf7326204cc46c755b5b2608033d9d24 ../pcre-8.44.tar.bz2 | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../pcre-8.44.tar.bz2 \
    && ./configure \
        --prefix=/usr \
        --enable-unicode-properties \
        --enable-pcre16 \
        --enable-pcre32 \
        --disable-static \
    && make -j16 \
    && make DESTDIR=/mnt/nginx install-strip \
    && make install-strip \
    ;

ADD https://nginx.org/download/nginx-1.19.0.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 1dd77bbe9fb949919e18c810abb5c397 ../nginx-1.19.0.tar.gz  md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../nginx-1.19.0.tar.gz \
    && ./configure \
        --prefix=/usr \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-http_stub_status_module \
        --with-http_v2_module \
        --with-stream \
        --with-stream_ssl_module \
        --with-threads \
    && make -j16 \
    && make DESTDIR=/mnt/nginx install \
    ;

FROM build AS utils

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ADD https://curl.haxx.se/download/curl-7.75.0.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 9730df8636d67b4e256ebc49daf27246 ../curl-7.75.0.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../curl-7.75.0.tar.xz \
    && ./configure \
        --host="$(uname -m)"-lfs-linux-gnu \
        --prefix=/usr \
        --disable-static \
        --enable-threaded-resolver \
        --with-ca-path=/etc/ssl/certs \
    && make -j16 \
    && make install-strip \
    ;

ADD https://strace.io/files/5.11/strace-5.11.tar.xz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo f5a317fd535465cf9130d0547661f5c4 ../strace-5.11.tar.xz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../strace-5.11.tar.xz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

ADD https://www.bitwizard.nl/mtr/files/mtr-0.94.tar.gz ..
RUN --network=none --mount=type=tmpfs,target=/build \
    echo 3468a94927109981de49957d0cc6d50e ../mtr-0.94.tar.gz | md5sum --quiet --strict --check - \
    && tar --strip-components=1 -xf ../mtr-0.94.tar.gz \
    && ./configure \
        --prefix=/usr \
    && make -j16 \
    && make install-strip \
    ;

FROM scratch AS python

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=build /mnt/base /mnt/bash /mnt/python /

RUN --network=none \
    ["ldconfig"]

WORKDIR /app

USER python:python

ENTRYPOINT ["/usr/bin/python3"]

FROM scratch AS uwsgi

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=build /mnt/base /mnt/bash /mnt/python /
COPY --from=build-uwsgi /mnt/uwsgi /

RUN --network=none \
    ["ldconfig"]

WORKDIR /app

USER python:python

ENTRYPOINT ["/usr/bin/uwsgi"]

FROM scratch AS postgres

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=build /mnt/base /mnt/bash /mnt/python /

RUN --network=none \
    ["ldconfig"]

COPY --from=build /mnt/postgres /

USER postgres:postgres

ENV LC_ALL=C.utf8 \
    PGDATA=/srv/pgsql/data

RUN --network=none \
    ["/usr/bin/initdb"]

ENTRYPOINT ["/usr/bin/postgres"]

FROM scratch AS nginx

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY --from=build /mnt/base /

RUN --network=none \
    ["ldconfig"]

COPY --from=build-nginx /mnt/nginx /

ENTRYPOINT ["/usr/sbin/nginx", "-g", "daemon off;error_log /dev/stdout info;"]
