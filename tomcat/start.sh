#!/bin/bash
CERT_DIR=/cert
KEYSTORE=~/.keystore

CONTEXT_PATH=$(yml.pl /conf/config.yml registry.context_path)
CATALINA_OPTS="$CATALINA_OPTS -Dcontext.path=${REGISTRY_CONTEXT_PATH:-$CONTEXT_PATH}"
echo CATALINA_OPTS: $CATALINA_OPTS

if [[ -d $CERT_DIR && ! -z "$KEYSTORE_PASS" ]]
then
	if [[ ! -f ${CERT_DIR}/cert_and_key.p12 ]]
	then
		openssl pkcs12 -export -in ${CERT_DIR}/fullchain.pem -inkey ${CERT_DIR}/privkey.pem -out ${CERT_DIR}/cert_and_key.p12 -name tomcat -CAfile ${CERT_DIR}/chain.pem -caname root -password pass:"$KEYSTORE_PASS"
	fi

	if [[ ! -f ${KEYSTORE} ]]
	then
		keytool -importkeystore -srcstorepass "$KEYSTORE_PASS" -deststorepass changeit -destkeypass changeit -srckeystore ${CERT_DIR}/cert_and_key.p12 -srcstoretype PKCS12 -alias tomcat -keystore $KEYSTORE
		keytool -import -trustcacerts -alias root -deststorepass changeit -file ${CERT_DIR}/chain.pem -noprompt -keystore $KEYSTORE
	fi
	
	sed -i 's/SSLEnabled="false"/SSLEnabled="true"/' $CATALINA_BASE/conf/server.xml
fi

exec catalina.sh run
