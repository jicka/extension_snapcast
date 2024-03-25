FROM alpine:latest AS builder

# Install required build dependencies
RUN apk update && apk add --no-cache \
    build-base \
    autoconf \
    automake \
    git \
    cmake \
    alsa-lib-dev \
    libvorbis-dev \
    opus-dev \
    flac-dev \
    soxr-dev \
    pkgconf \
    boost-dev \
    alsa-lib-dev \
    dbus-dev \
    glib-dev \
    cairo \
    cairo-dev \
    gobject-introspection-dev \
    python3 \
    py3-pip

RUN apk add --no-cache dbus

# Clone Snapcast repository and build it
RUN git clone https://github.com/badaix/snapcast /snapcast

# Build Snapcast
WORKDIR /snapcast
RUN cmake . \
    && make

RUN apk add --no-cache python3-dev

# Build snapcastmpris
RUN cd / && \
    git clone https://github.com/hifiberry/snapcastmpris &&  \
    cd snapcastmpris && \
    pip install --no-cache-dir --verbose  --break-system-packages -r requirements.txt

RUN find / -name site-packages

# Final stage: create the minimal runtime container
FROM alpine:latest

RUN apk update && apk add --no-cache \
    dbus \
    glib \
    gobject-introspection \
    py3-gobject3 \
    py3-gobject3-dev \
    python3 

# Copy python from builder image
COPY --from=builder /usr/lib/python3.11/site-packages /usr/lib/python3.11/site-packages
COPY --from=builder /snapcastmpris /snapcastmpris

# Copy built Snapcast binary from builder stage
COPY --from=builder /snapcast/bin/snapclient /usr/local/bin/snapclient

# Expose Snapcast port
EXPOSE 1704

# Run Snapcast server
CMD ["/usr/bin/python3" , "/snapcastmpris/snapcastmpris.py", "-m", "$CURRENT_MIXER_CONTROL"]
