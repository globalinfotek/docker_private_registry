# To create our own self-signed certificate, we can create our own CA

# Create a Private Key for the CA
openssl genrsa -des3 -out CAPrivate.key 2048

# Generate the root certificate
openssl req -x509 -new -nodes -key CAPrivate.key -sha256 -days 365 -out CAPrivate.pem

# Generate Key for our registry certificate
openssl genrsa -out MyPrivate.key 2048

# Generate CSR for our registry certificate
openssl req -new -key MyPrivate.key -out MyRequest.csr

# Generate the certificate using the CSR
openssl x509 -req -in MyRequest.csr -CA CAPrivate.pem -CAkey CAPrivate.key -CAcreateserial -out MyRequest.crt -days 365 -sha256
