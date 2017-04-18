#!/usr/bin/env bash

set -eu
export LC_ALL=C

# export NODE_IP=$1

export KUBE_API_TEMPLATE=/etc/kubernetes/manifests/kube-apiserver.yaml
mkdir -p $(dirname $KUBE_API_TEMPLATE)
cat << EOF > $KUBE_API_TEMPLATE
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
  labels:
    tier: control-plane
    component: kube-apiserver
spec:
  hostNetwork: true
  containers:
  - name: kube-apiserver
    image: ${HYPERKUBE_IMAGE_REPO}:${KUBE_VERSION}
    command:
    - /hyperkube
    - apiserver
    - --bind-address=0.0.0.0
    - --insecure-bind-address=127.0.0.1
    - --admission-control=${KUBE_ADMISSION_CONTROL}
    - --service-cluster-ip-range=${KUBE_SERVICE_IP_RANGE}
    - --service-account-key-file=/etc/kubernetes/ssl/apiserver-key.pem
    - --client-ca-file=/etc/kubernetes/ssl/ca.pem
    - --tls-cert-file=/etc/kubernetes/ssl/apiserver.pem
    - --tls-private-key-file=/etc/kubernetes/ssl/apiserver-key.pem
    - --secure-port=${KUBE_INTERNAL_PORT}
    - --allow-privileged
    - --advertise-address=${NODE_IP}
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
    - --anonymous-auth=false
    - --etcd-servers=${ETCD_ENDPOINT}
    - --storage-backend=${KUBE_STORAGE_BACKEND}
    - --cloud-provider=${CLOUD_PROVIDER:-""}
    - --cloud-config=${CLOUD_CONFIG:-""}
    livenessProbe:
      httpGet:
        host: 127.0.0.1
        port: 8080
        path: /healthz
      initialDelaySeconds: 15
      timeoutSeconds: 15
    ports:
    - containerPort: ${KUBE_INTERNAL_PORT}
      hostPort: ${KUBE_INTERNAL_PORT}
      name: https
    - containerPort: 8080
      hostPort: 8080
      name: local
    volumeMounts:
    - mountPath: /etc/kubernetes
      name: k8s
      readOnly: true
    - mountPath: /etc/ssl/certs
      name: ssl-certs-host
      readOnly: true
  volumes:
  - hostPath:
      path: /etc/kubernetes
    name: k8s
  - hostPath:
      path: /etc/ssl/certs
    name: ssl-certs-host
EOF
