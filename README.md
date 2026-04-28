# Kubernetes dashboard devoos m2 ESGI IW
Groupe : Ikram Abid, Acil Kasraoui, Kadem Kamil Garnier, Khadim Cisse

Dashboard de supervision Kubernetes déployé via Helm, intégrant le monitoring (Prometheus / Grafana / Loki / Alloy), la sauvegarde (Velero + MinIO) et le suivi de notre projet annuel (GitHub + Trello).

## Stack

- **Kubernetes**
- **Helm**
- **Ingress NGINX** -> deprécié, mais on a choisi ceci avant la dépréciation, puis nous apprécions la solution opensource, nous connaissons les alternatives comme gateway api avec envoy grateway ou traefik que nous avons discuté en cours.
- **Homepage** (gethomepage.dev) deploye via chart Helm custom
- **Monitoring** : kube-prometheus-stack + Loki + Alloy
- **Backup** : Velero + MinIO (S3 local)

## Prerequis

```bash
# requis pr le projet
kubectl version --client
helm version
docker info

# cluster accessible
kubectl cluster-info
```

Ajouter le mapping DNS local dans le fichier `hosts` :

**macOS / Linux** :
```bash
echo "127.0.0.1  homepage.local grafana.local prometheus.local loki.local minio.local" | sudo tee -a /etc/hosts
```

**Windows** (PowerShell en Administrateur) :
```powershell
Add-Content -Path "C:\Windows\System32\drivers\etc\hosts" -Value "127.0.0.1  homepage.local grafana.local prometheus.local loki.local minio.local"
```

## Installation

### 1. Cloner le repo

```bash
git clone https://github.com/Kadem9/kubernetes-esgi.git
cd kubernetes-esgi
```

### 2. Ingress NGINX

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
--namespace ingress-nginx --create-namespace
```

### 3. Monitoring (Prometheus + Grafana)

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

### 4. Logs (Loki + Alloy)

```bash
helm repo add grafana https://grafana.github.io/helm-charts

helm install loki grafana/loki \
  --namespace monitoring \
  -f helm-values/loki-values.yaml

helm install alloy grafana/alloy \
  --namespace monitoring \
  -f helm-values/alloy-values.yaml
```

### 5. Sauvegarde (MinIO + Velero)

```bash
# minio
kubectl create namespace velero
kubectl apply -f velero/minio.yaml
kubectl apply -f velero/ingress-minio.yaml
kubectl apply -f velero/minio-create-bucket.yaml

# credentiels à créer depuis le template
cp velero/credentials-velero.example velero/credentials-velero

kubectl create secret generic cloud-credentials \
  --namespace velero \
  --from-file=cloud=velero/credentials-velero

# velero
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm install velero vmware-tanzu/velero \
  --namespace velero \
  -f velero/velero-values.yaml

# schedule backup automatique
kubectl apply -f velero/schedule-homepage.yaml
```

### 6. Homepage (le dashboard)

```bash
# créer votre fichier secret 
cat > charts/homepage/values-secrets.yaml << 'EOF'
github:
  enabled: true
  token: "ghp_TON_TOKEN_GITHUB"

trello:
  enabled: true
  key: "TA_CLE_TRELLO"
  token: "TON_TOKEN_TRELLO"
EOF

# installer le chart
kubectl create namespace homepage
helm install homepage charts/homepage \
  --namespace homepage \
  -f charts/homepage/values-secrets.yaml

# ingress monitoring
kubectl apply -f k8s/base/ingress-monitoring.yaml
```

### 7. Verification

```bash
helm list -A
kubectl get pods -A
```

Puis ouvrir dans le navigaeur
- http://homepage.local — dashboard principal
- http://grafana.local — Grafana (user `admin`, mdp via secret)
- http://prometheus.local — Prometheus
- http://minio.local — Console MinIO

## Mise a jour

Pr modifier la config du dashboard, editer les fichiers dans `charts/homepage/files/` puis :
```bash
helm upgrade homepage charts/homepage \
  --namespace homepage \
  -f charts/homepage/values-secrets.yaml
```

## Structure du repo

```
kube-projet-final/
├── charts/homepage/ # Chart Helm du dashboard (le livrable principal)
│   ├── files/ # Configuration du dashboard (services, widgets, etc...)
│   ├── templates/ # Templates Helm
│   └── values.yaml # Valeurs par defaut
├── helm-values/ # Values pr les charts Helm tiers (Loki, Alloy)
├── k8s/base/  # Manifests bruts (reference avant migration Helm)
├── velero/ # Configuration MinIO + Velero (backup)
└── README.md  # Ce fichier
```

## Desinstallation

```bash
helm uninstall homepage -n homepage
helm uninstall velero -n velero
helm uninstall loki alloy -n monitoring
helm uninstall monitoring -n monitoring
helm uninstall ingress-nginx -n ingress-nginx
```
