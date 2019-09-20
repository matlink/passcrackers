FROM ubuntu:bionic as builder

ENV POCL_VERSION v1.4-RC2
ENV HC_VERSION master
ENV JOHN_DIR /opt/john

RUN apt update
RUN apt -y install git llvm-dev clang libclang-dev build-essential libltdl3-dev libhwloc-dev pkg-config cmake zlib1g-dev libssl-dev

RUN mkdir -p /opt

# Install pocl
RUN git clone https://github.com/pocl/pocl /opt/pocl
WORKDIR /opt/pocl
RUN git checkout ${POCL_VERSION}
RUN cmake -DENABLE_ICD=0 -DCMAKE_BUILD_TYPE=Release .
RUN make
RUN make install

# Install Hashcat
RUN git clone https://github.com/hashcat/hashcat /opt/hashcat
WORKDIR /opt/hashcat
RUN git checkout ${HC_VERSION}
RUN make
RUN make install
RUN echo 'LD_LIBRARY_PATH=/usr/local/lib hashcat --force $@' > /bin/hashcat-cpu
RUN chmod +x /bin/hashcat-cpu

# Install john
RUN git clone https://github.com/magnumripper/JohnTheRipper /opt/john
WORKDIR /opt/john/src
RUN git checkout bleeding-jumbo
RUN ./configure --disable-native-tests CPPFLAGS="-DJOHN_SYSTEMWIDE -DJOHN_SYSTEMWIDE_EXEC=\"\\\"${JOHN_DIR}\\\"\" -DJOHN_SYSTEMWIDE_HOME=\"\\\"${JOHN_DIR}\\\"\""
RUN make
RUN make install

FROM ubuntu:bionic as runner
WORKDIR /opt
RUN apt update && \
    apt -y install libltdl3-dev libhwloc-dev libssl-dev libclang-dev && \
    apt clean && rm -rf /var/cache/apt /var/lib/apt/lists
COPY --from=builder 	/usr/local/bin/hashcat \
			/bin/hashcat-cpu \
			/opt/john/run/john \
			/bin/

COPY --from=builder 	/opt/john/run/*.conf \
			/opt/john/run/rules \
			/opt/john/

COPY --from=builder 	/usr/local/lib/libOpenCL* \
			/usr/local/lib/

COPY --from=builder 	/usr/local/share/hashcat \
			/usr/local/share/hashcat

COPY --from=builder 	/usr/local/share/pocl \
			/usr/local/share/pocl

COPY --from=builder 	/usr/local/bin/ \
			/usr/local/bin/

RUN ln -sf /usr/local/lib/libOpenCL.so.2.3.0 /usr/lib/x86_64-linux-gnu/libOpenCL.so.2
