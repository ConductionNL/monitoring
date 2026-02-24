# Nextcloud-dashboard: geen data?

Als het dashboard "Nextcloud-omgevingen" leeg blijft, controleer het volgende in **Grafana → Explore** (datasource: Prometheus).

## 1. Dropdown Namespaces

- Staan er namespaces in de dropdown? Zo nee: **datasource** klopt niet of Prometheus heeft geen `kube_pod_info`.
- Test: `label_values(kube_pod_info, namespace)` → moet een lijst namespaces geven.
- Zet de variabele op **All** of kies expliciet bijvoorbeeld `vng-backend-accept` en `epe`.

## 2. Pod-/deployment-aantallen (bovenste stat-panels)

- `count(kube_pod_info{namespace=~"vng-backend-accept|epe"})` → moet een getal geven als er pods zijn.
- `count(kube_deployment_created{namespace=~"vng-backend-accept|epe"})` → idem voor deployments.

Als dit al geen getal geeft: er is geen data voor die namespaces in **kube-state-metrics**, of de regex/selectie dekt je namespaces niet.

## 3. CPU / memory (container-metrics)

De panels gebruiken metrics van de **kubelet** (cAdvisor). Die worden niet altijd geschraapt.

- Bestaat de metric?  
  `container_cpu_usage_seconds_total` (één keer uitvoeren, zonder filter).  
  Zo nee: kubelet/cAdvisor wordt niet geschraapt; dan kunnen we alleen de kube-state-metrics-panels vullen (aantallen pods/deployments, running pods, replicas).
- Welke labels heeft de metric?  
  `container_cpu_usage_seconds_total{container!=""}` → kijk in de legenda/labels of je `pod` of `pod_name` en eventueel `namespace` ziet.
- Als er een **namespace**-label is:  
  `sum(rate(container_cpu_usage_seconds_total{namespace=~"vng-backend-accept|epe",container!="",container!="POD"}[5m])) by (namespace, pod)`  
  moet series geven.
- Als er **geen** namespace-label is (alleen `pod`):  
  het dashboard gebruikt een join met `kube_pod_info`. Controleer of de **pod-naam** overeenkomt:  
  `kube_pod_info{namespace=~"vng-backend-accept|epe"}` toont pod-namen; die moeten overeenkomen met de `pod`-label op de container-metrics.

## 4. Datasource-UID

Het dashboard gebruikt datasource-UID `prometheus`. Als jullie Prometheus-datasource een andere UID heeft (Settings → Data sources → Prometheus → UID), dan faalt de variabele-query. Pas dan in het dashboard de datasource aan naar jullie Prometheus, of clone het dashboard en kies daar de juiste datasource.

## Samenvatting

| Wat je ziet | Mogelijke oorzaak |
|-------------|--------------------|
| Geen namespaces in dropdown | Datasource verkeerd of geen `kube_pod_info` |
| Dropdown ok, maar 0 pods/0 deployments | Geen kube-state-metrics voor die namespaces, of verkeerde selectie |
| Aantallen ok, maar geen CPU/memory | Geen kubelet/cAdvisor-scrape, of andere metric/label-namen |
