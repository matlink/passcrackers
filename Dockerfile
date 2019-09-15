FROM ubuntu:bionic as builder

ENV POCL_VERSION v1.3
ENV HC_VERSION v5.1.0

RUN apt-get update && \
    apt-get -y install git llvm-dev clang libclang-dev build-essential libltdl3-dev libhwloc-dev pkg-config cmake zlib1g-dev libssl-dev

RUN mkdir -p /opt

# Install pocl
RUN git clone https://github.com/pocl/pocl /opt/pocl
WORKDIR /opt/pocl
RUN git checkout ${POCL_VERSION} && \
    cmake -DENABLE_ICD=0 . && \
    make && \
    make install

# Install Hashcat
RUN git clone https://github.com/hashcat/hashcat /opt/hashcat
WORKDIR /opt/hashcat
RUN git checkout ${HC_VERSION} && \
    make && \
    make install && \
    echo 'LD_LIBRARY_PATH=/usr/local/lib hashcat --force $@' > /bin/hashcat-cpu && \
    chmod +x /bin/hashcat-cpu

# Install john
RUN git clone https://github.com/magnumripper/JohnTheRipper /opt/john
WORKDIR /opt/john/src
RUN git checkout bleeding-jumbo && \
    ./configure && \
    make -j4

FROM ubuntu:bionic as runner
WORKDIR /opt
RUN apt update && apt -y install libltdl3-dev libhwloc-dev libssl-dev libclang-dev
COPY --from=builder /opt/john/run /opt/john/run
COPY --from=builder /usr/local/bin/hashcat /bin/hashcat
COPY --from=builder /bin/hashcat-cpu /bin/hashcat-cpu
COPY --from=builder /usr/local/lib/libOpenCL* /usr/local/lib/
COPY --from=builder /usr/local/share/hashcat /usr/local/share/hashcat
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/share/pocl /usr/local/share/pocl
RUN ln -sf /usr/local/lib/libOpenCL.so.2.3.0 /usr/lib/x86_64-linux-gnu/libOpenCL.so.2
