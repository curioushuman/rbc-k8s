{{- define "rbc-lib.service.tpl" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "rbc-lib.fullname" . }}
  labels:
    {{- include "rbc-lib.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
  {{- if .Values.ports }}
    {{- range .Values.ports }}
    - port: {{ .port }}
      targetPort: {{ .name }}
      protocol: {{ .protocol }}
      name: {{ .name }}
    {{- end }}
  {{- else }}
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.portName }}
      protocol: {{ .Values.service.protocol }}
      name: {{ .Values.service.portName }}
  {{- end }}
  selector:
    {{- include "rbc-lib.selectorLabels" . | nindent 4 }}
{{- end -}}
{{- define "rbc-lib.service" -}}
{{- include "rbc-lib.util.merge" (append . "rbc-lib.service.tpl") -}}
{{- end -}}
