{{- define "homepage.name" -}}
{{- default "homepage" .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "homepage.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- "homepage" }}
{{- end }}
{{- end }}

{{- define "homepage.labels" -}}
app.kubernetes.io/name: {{ include "homepage.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end }}

{{- define "homepage.selectorLabels" -}}
app.kubernetes.io/name: {{ include "homepage.name" . }}
{{- end }}
