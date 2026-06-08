{{- /*
python-dev-environment - A secure, non-root Python development environment for VS Code
Copyright (c) 2024
SPDX-License-Identifier: Apache-2.0
*/ -}}

{{- define "python-dev.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "python-dev.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "python-dev.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "python-dev.labels" -}}
helm.sh/chart: {{ include "python-dev.chart" . }}
{{ include "python-dev.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ include "python-dev.name" . }}
{{- end }}

{{- define "python-dev.selectorLabels" -}}
app.kubernetes.io/name: {{ include "python-dev.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "python-dev.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "python-dev.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}