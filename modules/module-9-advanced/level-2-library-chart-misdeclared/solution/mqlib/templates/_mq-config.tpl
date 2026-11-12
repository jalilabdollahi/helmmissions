{{- /* Broker settings shared by every mailer chart. */ -}}
{{- define "mqlib.broker" -}}
{{ .Values.mq.broker | default "mq.messaging.svc:5672" }}
{{- end -}}

{{- define "mqlib.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-mq
  labels:
    app.kubernetes.io/name: {{ .Chart.Name }}
    app.kubernetes.io/instance: {{ .Release.Name }}
data:
  broker: {{ include "mqlib.broker" . | quote }}
  retries: {{ .Values.mq.retries | default 3 | quote }}
{{- end -}}
