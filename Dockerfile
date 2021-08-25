FROM alpine:latest as builder-base

WORKDIR /build/

RUN apk add --no-cache build-base gcc make musl-dev glib glib-dev libc-dev

FROM builder-base as builder-althttpd

ENV ALTHTTPD_VERSION="3bd58672947cb446f72bc64471db63d525f949f6a258b89875436f992ebea39c"

ADD https://sqlite.org/althttpd/raw?ci=tip&name=Makefile    /build/src/Makefile
ADD https://sqlite.org/althttpd/raw?ci=tip&name=althttpd.c  /build/src/althttpd.c
ADD https://sqlite.org/althttpd/raw?ci=tip&name=althttpd.md /build/src/althttpd.md

ADD ./Makefile /build/Makefile

RUN make

#ADD https://sqlite.org/althttpd/raw/001b7cc47f3f2cbc7899ecb3dd16cc359baec3e1672c32414354c499d37c17ce?at=althttpd.c /althttpd.c

# RUN gcc -static -Ofast -o althttpd althttpd.c && strip althttpd

#############################################

FROM alpine:latest

ENV ALTHTTPD_VERSION="3bd58672947cb446f72bc64471db63d525f949f6a258b89875436f992ebea39c"

COPY --from=builder-althttpd /build/althttpd /usr/local/bin/althttpd
COPY --from=builder-althttpd /etc/passwd /etc/passwd

COPY /src/index.html /www/

RUN chmod +x /usr/local/bin/althttpd \
    && chown -R nobody /www \
    && chown 0755 /www \
    && chmod 0644 /www/index.html

USER nobody

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/althttpd", "-root", "/www", "-port", "80", "-logfile", "/dev/stderr", "-debug"]
