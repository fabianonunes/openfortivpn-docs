#! /bin/bash

dpkg --fsys-tarfile SafenetAuthenticationClient-BR-10.0.37-0_amd64.deb | \
    tar -C teste -xvf - --transform='s|^|usr/|' --wildcards './lib/libeToken.so*' './lib/libcardos*'
    
dpkg --fsys-tarfile SafenetAuthenticationClient-BR-10.0.37-0_amd64.deb | \
    tar -C teste -xvf - --transform='s|share/eToken|lib/pcsc|' ./usr/share/eToken/drivers
