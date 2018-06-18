## Openshift commands

# Restart openshift cluster
function restart_cluster {
  oc cluster stop && oc cluster up --host-data-dir /var/lib/origin/openshift.local.etcd --use-existing-config=true
}


# Test EncryptionConfig: No Encryption
oc create secretgeneric secret1 -n default --from-literal=XX_mykey_XX=ZZ_mydata_ZZ
oc get secret secret1 -n default -o yaml
etcds get $SECRETS_PATH/default/secret1 -w fields | grep Value

