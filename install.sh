#! /bin/bash

dpkg --fsys-tarfile SafenetAuthenticationClient-BR-10.0.37-0_amd64.deb | \
    tar -C teste -xvf - --transform='s|^|usr/|S' --wildcards './lib/libeToken.so*' './lib/libcardos*'
    
dpkg --fsys-tarfile SafenetAuthenticationClient-BR-10.0.37-0_amd64.deb | \
    tar -C teste -xvf - --transform='s|share/eToken|lib/pcsc|S' ./usr/share/eToken/drivers
