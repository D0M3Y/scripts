#!/bin/bash

# Script created by Dominik Bauer (@d0m3y)

read -p "Bitte CN angeben: " CN
read -p "Bitte FQDN angeben: " FQDN
read -p "Wie lange soll das Zertifikat gültig sein? (In Tagen): " DAYS

mkdir $FQDN

if [ $1 == "ca" ]
then
    echo "Erstelle Ordner \"ca\"..."
    mkdir ca
    echo 'Erstelle "ca-key.pem"...'
    openssl genrsa -aes256 -out ca/ca-key.pem 4096
    echo 'Erstelle "ca.pem"...'
    openssl req -new -x509 -sha256 -days 365 -key ca/ca-key.pem -out ca/ca.pem
    echo 'Kopiere CA-Zertifikat in Cert-Store...'
    sudo cp ca/ca.pem /usr/local/share/ca-certificates/ca_$FQDN.crt
    echo 'Start update-ca-certificates...'
    sudo update-ca-certificates
else
    echo "Überspringe CA-Generierung"
fi

echo 'Erstelle "cert-key.pem"...'
openssl genrsa -out $FQDN/cert-key.pem 4096
echo 'Erstelle "cert.csr"...'
openssl req -new -sha256 -subj "/CN=$CN" -key $FQDN/cert-key.pem -out $FQDN/cert.csr

echo 'Erstelle "extfile.cnf"...'
echo "subjectAltName=DNS:$FQDN" >> $FQDN/extfile.cnf
echo 'Erstelle Zertifikat (cert.pem)...'
openssl x509 -req -sha256 -days $DAYS -in $FQDN/cert.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -out $FQDN/cert.pem -extfile $FQDN/extfile.cnf -CAcreateserial

echo 'Verifiziere Zertifikat...'
openssl verify -CAfile ca/ca.pem -verbose $FQDN/cert.pem

echo 'Erstelle fullchain.pem...'
cat $FQDN/cert.pem > $FQDN/fullchain.pem
cat ca/ca.pem >> $FQDN/fullchain.pem

echo "Made by Dominik Bauer (@d0m3y)"
