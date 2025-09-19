import kopf
import requests
from kubernetes import client, config

config.load_incluster_config()
apps_api = client.AppsV1Api()

@kopf.timer('llm.dev', 'v1', 'llmautoscalers', interval=15.0)
def autoscale_llm(spec, **kwargs):
    deployment = spec['deploymentName']
    namespace = spec['namespace']
    metric_url = spec['scaleTargetURL']
    metric_name = spec['metric']
    threshold = float(spec['threshold'])
    min_replicas = int(spec['minReplicas'])
    max_replicas = int(spec['maxReplicas'])

    try:
        resp = requests.get(metric_url)
        if not resp.ok:
            raise RuntimeError(f"Metric scrape failed: {resp.status_code}")
        lines = resp.text.splitlines()
        metric_val = None
        for line in lines:
            if line.startswith(metric_name):
                metric_val = float(line.split()[-1])
                break

        if metric_val is None:
            raise RuntimeError(f"Metric '{metric_name}' not found")

        deploy = apps_api.read_namespaced_deployment(deployment, namespace)
        current_replicas = deploy.spec.replicas

        desired = current_replicas
        if metric_val > threshold:
            desired += 1
        elif metric_val < threshold * 0.5:
            desired -= 1

        desired = max(min_replicas, min(max_replicas, desired))

        if desired != current_replicas:
            print(f"Scaling {deployment} to {desired} replicas (metric={metric_val})")
            deploy.spec.replicas = desired
            apps_api.patch_namespaced_deployment(deployment, namespace, deploy)

    except Exception as e:
        print(f"[Autoscaler] Error: {e}")