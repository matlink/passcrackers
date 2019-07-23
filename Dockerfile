FROM ubuntu:bionic

ENV POCL_VERSION v1.3
ENV HC_VERSION v5.1.0
ENV JOHN_DIR /opt/bin/john

RUN apt-get -qq update && \
    apt-get -y install git llvm-dev clang libclang-dev build-essential libltdl3-dev libhwloc-dev pkg-config cmake zlib1g-dev libssl-dev > /dev/null

RUN mkdir -p /opt
WORKDIR /opt

# Install pocl
RUN git clone https://github.com/pocl/pocl
WORKDIR /opt/pocl
RUN git checkout ${POCL_VERSION} && \
    cmake -DENABLE_ICD=0 . && \
    make && \
    make install
WORKDIR /opt

# Install Hashcat
RUN git clone https://github.com/hashcat/hashcat
WORKDIR /opt/hashcat
RUN git checkout ${HC_VERSION} && \
    make && \
    make install && \
    echo 'LD_LIBRARY_PATH=/usr/local/lib hashcat --force $@' > /bin/hashcat-cpu && \
    chmod +x /bin/hashcat-cpu
WORKDIR /opt

# Install john
RUN git clone https://github.com/magnumripper/JohnTheRipper john
WORKDIR /opt/john/src
RUN git checkout bleeding-jumbo && \
    ./configure && \
    mkdir -p ${JOHN_DIR} && \
    make -s "RELEASE_BLD=-DJOHN_SYSTEMWIDE=1 -DJOHN_SYSTEMWIDE_HOME=\\\"${JOHN_DIR}\\\" -DJOHN_SYSTEMWIDE_EXEC=\\\"${JOHN_DIR}\\\"" && \
    cp -R ../run/* ${JOHN_DIR}/ && \
    ln -sf ${JOHN_DIR}/john /bin/john && \
    ln -sf /usr/local/lib/libOpenCL.so.2.2.0 /usr/lib/x86_64-linux-gnu/libOpenCL.so.2
WORKDIR /opt
RUN rm -rf pocl hashcat john
