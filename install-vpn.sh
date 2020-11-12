#!/bin/bash

set -e

echo "Instalando arquivos do driver SAC"
chown -R root:root pkg
cp -r pkg/* /

echo "Atualizando ld"
ldconfig

echo "Reiniciando pcscd"
systemctl restart pcscd

echo "Instalação concluída"
