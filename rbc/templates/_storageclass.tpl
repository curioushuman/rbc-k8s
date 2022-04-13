{{/*
Storage class name
*/}}
{{- define "rbc.storageClassName" -}}
{{- if .Values.storageClass.create }}
{{- default (include "rbc.fullname" .) .Values.storageClass.name }}
{{- else }}
{{- default "default" .Values.storageClass.name }}
{{- end }}
{{- end }}

{{/*
Return the appropriate apiVersion for the storage class
*/}}
{{- define "rbc.storageClassApiVersion" -}}
{{- default "storage.k8s.io/v1" .Values.storageClass.apiVersion -}}
{{- end }}

{{/*
Provisioner
*/}}
{{- define "rbc.storageClassProvisioner" -}}
{{- default "kubernetes.io/no-provisioner" .Values.storageClass.provisioner }}
{{- end }}

{{/*
Volume expansion policy
*/}}
{{- define "rbc.storageClassVolumeExpansion" -}}
{{- default "false" .Values.storageClass.allowVolumeExpansion }}
{{- end }}

{{/*
Volume binding mode
*/}}
{{- define "rbc.storageClassVolumeBinding" -}}
{{- default "WaitForFirstConsumer" .Values.storageClass.volumeBindingMode }}
{{- end }}

{{/*
Reclaim policy
*/}}
{{- define "rbc.storageClassReclaimPolicy" -}}
{{- default "Retain" .Values.storageClass.reclaimPolicy }}
{{- end }}
