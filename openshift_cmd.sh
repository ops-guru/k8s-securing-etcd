## Openshift commands

# EncryptionConfig config file path:
/var/lib/origin/openshift.local.config/master/encryption-config.yaml
# Enable experimental-encryption-provider-config by adding this node in above yaml file:
kubernetesMasterConfig:
  apiServerArguments:
    experimental-encryption-provider-config:
    - /var/lib/origin/openshift.local.config/master/encryption-config.yaml


## Openshift commands
# Restart openshift cluster
function restart_cluster {
  oc cluster down
  oc cluster up --host-data-dir /var/lib/origin/openshift.local.etcd --use-existing-config=true
  oc login -u system:admin
}

# some vars to keep the commands shorter
DIR=/var/lib/origin/openshift.local.config/master/
SSL_OPTS="--cacert=${DIR}/ca.crt --cert=${DIR}/master.etcd-client.crt --key=${DIR}/master.etcd-client.key --endpoints=127.0.0.1:4001"
SECRETS_PATH=/kubernetes.io/secrets

# test list in etcd:
etcdCTL_API=3 etcdctl $SSL_OPTS get --keys-only=true --prefix $SECRETS_PATH

# Test EncryptionConfig: No Encryption
oc create secretgeneric secret1 -n default --from-literal=XX_mykey_XX=ZZ_mydata_ZZ
oc get secret secret1 -n default -o yaml
etcds get $SECRETS_PATH/default/secret1 -w fields | grep Value

# Test EncryptionConfig: aescbc
# default namespace in openshift is myproject
oc create secret generic secret2 --from-literal=XX_mykey_XX=ZZ_mydata_ZZ
oc get secret secret2 -o yaml
etcds get $SECRETS_PATH/myproject/secret2 -w fields | grep Value

# migrating data in etcd
# openshift has a tool that can migrate all resources 
oc adm migrate storage --include=secrets --confirm


# check the CN used to connect to etcd and save it openshift
openssl x509 -noout -text -in /var/lib/origin/openshift.local.config/master/master.etcd-client.crt | grep "Subject:"

# Create the CN as a user in etcd:
# for openshift use this workaround (it looks like it works with an older version):
docker run -it --rm --net=host --privileged -v /var/lib/origin/openshift.local.config/master:/keys --name temp gcr.io/google_containers/etcd-amd64:3.0.17 sh -c "etcdCTL_API=3 etcdctl --cacert=/keys/ca.crt --cert=/keys/master.etcd-client.crt --key=/keys/master.etcd-client.key --endpoints=127.0.0.1:4001 user add system:master"

# openshift etcd port and path to where certificates can be found
CA_PATH=/var/lib/origin/openshift.local.config/master
EP=4001

SSL_OPTS="--cacert=$CA_PATH/ca.crt --cert=$PWD/$NAME.pem --key=$PWD/$NAME-key.pem --endpoints=127.0.0.1:${EP}"

