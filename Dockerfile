FROM savonet/liquidsoap:v2.3.3
WORKDIR /app
RUN mkdir -p /var/log/liquidsoap
COPY liquidsoap.liq /app/liquidsoap.liq
ENV ICECAST_HOST=192.168.1.12
ENV ICECAST_PORT=8000
ENV ICECAST_PASSWORD=supersecret
ENV ICECAST_MOUNT=/stream
ENV STATION_NAME=RadioStation
ENV STATION_DESCRIPTION=RadioStation
ENV STATION_GENRE=Various
ENV STATION_URL=http://radio.example.com
ENTRYPOINT ["liquidsoap", "/app/liquidsoap.liq"]
