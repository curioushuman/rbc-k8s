{{/*
Backend output
*/}}
{{- define "rbc-lib.ingressBackEnd" -}}
service:
  name: {{ .serviceName }}
  port:
    number: {{ .servicePort }}
{{- end }}

{{/*
Backend, legacy output
*/}}
{{- define "rbc-lib.ingressBackEndLegacy" -}}
serviceName: {{ .serviceName }}
servicePort: {{ .servicePort }}
{{- end }}