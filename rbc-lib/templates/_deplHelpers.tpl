{{/*
Env vars consistent across containers
*/}}
{{- define "rbc-lib.containerEnv" -}}
- name: RBC_SVC_PORT
  value: "{{ .Values.service.port }}"
- name: RBC_APP_NAME
  value: "{{ include "rbc-lib.name" . }}"
- name: RBC_RELEASE_NAME
  value: "{{ .Release.Name }}"
- name: RBC_RELEASE_NAMESPACE
  value: "{{ .Release.Namespace }}"
{{- if .Values.global.umbrellaRelease }}
- name: RBC_UMBRELLA_RELEASE_NAME
  value: "{{ .Values.global.umbrellaRelease }}"
{{- end }}
{{- if .Values.database.name }}
- name: RBC_DATABASE_NAME
  value: "{{ .Values.database.name }}"
{{- end }}
{{- if .Values.database.port }}
- name: RBC_DATABASE_PORT
  value: "{{ .Values.database.port }}"
{{- end }}
{{- if or .Values.global.debug .Values.local.debug }}
- name: RBC_DEBUG
  value: "true"
{{- end }}
{{- end }}

{{/*
Container ports
*/}}
{{- define "rbc-lib.containerPorts" -}}
{{- if .Values.ports }}
{{- range .Values.ports }}
- name: {{ .name }}
  containerPort: {{ .port }}
  protocol: {{ .protocol }}
{{- end }}
{{- else }}
- name: {{ .Values.service.portName }}
  containerPort: {{ .Values.service.port }}
  protocol: {{ .Values.service.protocol }}
{{- end }}
{{- end }}

{{/*
Container probes
*/}}
{{- define "rbc-lib.containerProbes" -}}
{{- if .Values.livenessProbe }}
livenessProbe:
{{- toYaml .Values.livenessProbe | nindent 2 }}
{{- end }}
{{- if .Values.startupProbe }}
startupProbe:
{{- toYaml .Values.startupProbe | nindent 2 }}
{{- end }}
{{- if .Values.readinessProbe }}
readinessProbe:
{{- toYaml .Values.readinessProbe | nindent 2 }}
{{- end }}
{{- end }}
