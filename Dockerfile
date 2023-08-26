FROM nextcloud:apache as builder

# Build and install dlib on builder
RUN apt-get update ; \
    apt-get install -y build-essential wget cmake libx11-dev libopenblas-dev

ARG DLIB_BRANCH=v19.19
RUN wget -c -q https://github.com/davisking/dlib/archive/$DLIB_BRANCH.tar.gz \
    && tar xf $DLIB_BRANCH.tar.gz \
    && mv dlib-* dlib \
    && cd dlib/dlib \
    && mkdir build \
    && cd build \
    # && cmake -DBUILD_SHARED_LIBS=ON --config Release .. \
    && cmake -D BUILD_SHARED_LIBS=ON -D CMAKE_BUILD_TYPE=Release -S .. \
    && make \
    && make install

# Build and install PDLib on builder
ARG PDLIB_BRANCH=master
RUN apt-get install unzip
RUN wget -c -q https://github.com/matiasdelellis/pdlib/archive/$PDLIB_BRANCH.zip \
    && unzip $PDLIB_BRANCH \
    && mv pdlib-* pdlib \
    && cd pdlib \
    && phpize \
    && ./configure \
    && make \
    && make install

# Enable PDlib on builder
# If necesary take the php settings folder uncommenting the next line
# RUN php -i | grep "Scan this dir for additional .ini files"
RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini

# Install bzip2 needed to extract models

RUN apt-get install -y libbz2-dev
RUN docker-php-ext-install bz2

# Test PDlib instalation on builder

RUN apt-get install -y git
RUN git clone https://github.com/matiasdelellis/pdlib-min-test-suite.git \
    && cd pdlib-min-test-suite \
    && make

#
# If pass the tests, we are able to create the final image.
#
RUN ls /usr/local/lib/php/extensions/

FROM nextcloud:apache

# Install dependencies to image

RUN apt-get update ; \
    apt-get install -y ffmpeg nodejs npm libopenblas0

# Install dlib and PDlib to image

COPY --from=builder /usr/local/lib/libdlib.so* /usr/local/lib/

# If is necesary take the php extention folder uncommenting the next line
RUN php -i | grep extension_dir
COPY --from=builder /usr/local/lib/php/extensions/no-debug-non-zts-20220829/pdlib.so /usr/local/lib/php/extensions/no-debug-non-zts-20220829/
# Enable PDlib on final image

RUN echo "extension=pdlib.so" > /usr/local/etc/php/conf.d/pdlib.ini

# Increse memory limits

RUN echo memory_limit=2048M > /usr/local/etc/php/conf.d/memory-limit.ini

RUN apt-get update && \
    apt-get install -y lsb-release && \
    echo "deb http://ftp.debian.org/debian $(lsb_release -cs) non-free" >> \
    /etc/apt/sources.list.d/intel-graphics.list && \
    apt-get update && \
    apt-get install -y intel-media-va-driver-non-free && \
    rm -rf /var/lib/apt/lists/*

# RUN GID=$(stat -c "%g" /dev/dri/renderD128) \
#     && groupadd -g "$GID" render2 || true \
#     && GROUP=$(getent group "$GID" | cut -d: -f1) \
#     && usermod -aG "$GROUP" www-data
