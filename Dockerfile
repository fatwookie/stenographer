FROM debian:stretch as builder

RUN apt-get update -y && apt-get full-upgrade -y

RUN apt-get install -y tcpdump build-essential make git openssl apt-utils wget curl libleveldb-dev libaio-dev libsnappy-dev libcap-dev libseccomp-dev jq debianutils sudo

RUN wget https://dl.google.com/go/go1.12.4.linux-amd64.tar.gz && \ 
    tar xzf go1.12.4.linux-amd64.tar.gz && \
    mv go /opt

ENV GOPATH=/go GOROOT=/opt/go 
ENV PATH=$GOPATH/bin:$GOROOT/bin:$PATH

RUN go get github.com/google/stenographer && \
    cd /go/src/github.com/google/stenographer && \
    go build && \
    make -C stenotype

WORKDIR /go/src/github.com/google/stenographer


FROM debian:stretch

RUN apt-get update -y && apt-get full-upgrade -y
RUN apt-get install -y tcpdump build-essential make git openssl apt-utils wget curl libleveldb-dev libaio-dev libsnappy-dev libcap-dev libseccomp-dev jq debianutils sudo

COPY --from=builder /go/src/github.com/google/stenographer/stenotype /usr/bin
COPY --from=builder /go/src/github.com/google/stenographer/stenocurl /usr/bin
COPY --from=builder /go/src/github.com/google/stenographer/stenoread  /usr/bin
COPY --from=builder /go/src/github.com/google/stenographer/stenographer /usr/bin
COPY --from=builder /go/src/github.com/google/stenographer/stenokeys.sh /usr/bin

RUN adduser --group --system --no-create-home stenographer && \
    mkdir -p /etc/stenographer /etc/stenographer/certs && \
    chown -R root.root /etc/stenographer/certs

ADD configs/steno.conf /etc/stenographer/config
# ADD configs/limits.conf /etc/stenographer

RUN chmod 644 /etc/stenographer/config && \
    /usr/bin/stenokeys.sh stenographer stenographer

CMD ["/usr/bin/stenographer", "-syslog=false", "-v=1"]