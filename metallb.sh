# install MetalLB to the cluster for load balancing
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

kubectl wait --namespace metallb-system --for=condition=ready pod --selector=app=metallb --timeout=90s

cat <<EOF | kubectl apply -f -
    apiVersion: metallb.io/v1beta1
    kind: IPAddressPool
    metadata:
      name: first-pool
      namespace: metallb-system
    spec:
      addresses:
      - 192.168.56.200-192.168.56.210
    ---
    apiVersion: metallb.io/v1beta1
    kind: L2Advertisement
    metadata:
      name: l2-advert
      namespace: metallb-system
    EOF