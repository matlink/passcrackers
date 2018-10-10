FROM ubuntu:bionic

ENV POCL_VERSION v1.2
ENV HC_VERSION v4.2.1
ENV JOHN_DIR /opt/bin/john

RUN apt-get -qq update
RUN apt-get -y install git llvm-dev clang libclang-dev build-essential libltdl3-dev libhwloc-dev pkg-config cmake zlib1g-dev libssl-dev > /dev/null

RUN mkdir -p /opt
WORKDIR /opt

# Install pocl
RUN git clone https://github.com/pocl/pocl
WORKDIR /opt/pocl
RUN git checkout ${POCL_VERSION}
RUN cmake -DENABLE_ICD=0 .
RUN make
RUN make install
WORKDIR /opt
RUN rm -rf pocl

# Install Hashcat
RUN git clone https://github.com/hashcat/hashcat
WORKDIR /opt/hashcat
RUN git checkout ${HC_VERSION}
RUN make
RUN make install
RUN echo 'LD_LIBRARY_PATH=/usr/local/lib hashcat --force $@' > /bin/hashcat-cpu
RUN chmod +x /bin/hashcat-cpu
WORKDIR /opt
RUN rm -rf hashcat

# Install john
RUN git clone https://github.com/magnumripper/JohnTheRipper john
WORKDIR /opt/john/src
RUN git checkout bleeding-jumbo
RUN ./configure
RUN mkdir -p ${JOHN_DIR}
RUN make -s "RELEASE_BLD=-DJOHN_SYSTEMWIDE=1 -DJOHN_SYSTEMWIDE_HOME=\\\"${JOHN_DIR}\\\" -DJOHN_SYSTEMWIDE_EXEC=\\\"${JOHN_DIR}\\\""
RUN cp -R ../run/* ${JOHN_DIR}/
RUN ln -sf ${JOHN_DIR}/john /bin/john
RUN ln -sf /usr/local/lib/libOpenCL.so.2.2.0 /usr/lib/x86_64-linux-gnu/libOpenCL.so.2
WORKDIR /opt
RUN rm -rf john
