ARG ARCH

# Base image
FROM debian:bullseye-slim
ARG ARCH
ARG VERSION=4.1.3

# Switch to working directory for our app
WORKDIR /opt/chirpstack

# Checkout and compile remote code
COPY ./artifacts/binaries/chirpstack-mqtt-forwarder_${VERSION}_${ARCH}.tar.gz ./chirpstack-mqtt-forwarder.tar.gz
COPY ./artifacts/configs/chirpstack-mqtt-forwarder.toml ./chirpstack-mqtt-forwarder.toml
COPY ./start.sh ./
RUN tar -xf chirpstack-mqtt-forwarder.tar.gz && chmod +x start.sh

# Launch our binary on container startup.
CMD ["bash", "start.sh"]
