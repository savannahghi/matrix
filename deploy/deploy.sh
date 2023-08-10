#!/usr/bin/env sh

set -eux

# Create the namespace
kubectl create namespace $NAMESPACE || true

# Delete Kubernetes secret if exists
kubectl delete secret matrix-service-account --namespace $NAMESPACE || true

# Create GCP service account file
cat $GOOGLE_APPLICATION_CREDENTIALS >> ./service-account.json

# Recreate service account file as Kubernetes secret
kubectl create secret generic matrix-service-account \
    --namespace $NAMESPACE \
    --from-file=key.json=./service-account.json

helm upgrade \
    --install \
    --debug \
    --create-namespace \
    --namespace "${NAMESPACE}" \
    --set service.serverName="${SERVER_NAME}"\
    --set app.container.env.dbHost="${DB_HOST}"\
    --set app.container.env.dbName="${DB_NAME}"\
    --set app.container.env.dbPassword="${DB_PASSWORD}"\
    --set app.container.env.dbUser="${DB_USER}"\
    --set networking.issuer.name="letsencrypt-prod"\
    --set networking.issuer.privateKeySecretRef="letsencrypt-prod"\
    --set networking.synapse.ingress.host="${SYNAPSE_DOMAIN}"\
    --set networking.element.ingress.host="${ELEMENT_DOMAIN}"\
    --set app.container.env.databaseInstanceConnectionName="${DATABASE_INSTANCE_CONNECTION_NAME}"\
    --wait \
    --timeout 300s \
    -f ./charts/matrix/values.yaml \
    $APP_NAME \
    ./charts/matrix
