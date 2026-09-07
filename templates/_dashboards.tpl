{{/*
Render one Grafana dashboard JSON for a single (service, span, exit-code) triple.

The dashboard runs ONE Tempo query (the hidden "Source Data" table, panel 100) and
feeds the timeseries and the four stat panels from it through the "-- Dashboard --"
datasource. Only the traces table issues a second query, because it needs the
per-operation span attributes pulled in via select(). That is 2 queries per
dashboard instead of the 10 the previous per-panel layout used.

Expected context (a dict):
  service  full resource.service.name value, e.g. InterLink-Plugin-<uuid>
  span     span name, e.g. CreateAPI
  label    display name, e.g. Create
  ok       true for exit.code=200, false for exit.code!=200
  selects  list of TraceQL attribute expressions for the traces table
  family   short tag describing which hop this dashboard covers
  ds       uid of the Tempo datasource
*/}}
{{- define "interlink-mon.traceDashboard" -}}
{{- $service := .service -}}
{{- $span := .span -}}
{{- $label := .label -}}
{{- $ok := .ok -}}
{{- $ds := .ds -}}
{{- $cmp := ternary "=" "!=" $ok -}}
{{- $suffix := ternary "200" "!200" $ok -}}
{{- $color := ternary "orange" "red" $ok -}}
{{- $title := printf "%s - %s (%s)" $service $label $suffix -}}
{{- $uid := printf "%s|%s|%s" $service $span $suffix | sha256sum | trunc 40 -}}
{{- $query := printf "{resource.service.name=\"%s\" && name=\"%s\" && span.exit.code%s200}" $service $span $cmp -}}
{{- $tableQuery := $query -}}
{{- range .selects -}}
{{- $tableQuery = printf "%s | select(%s)" $tableQuery . -}}
{{- end -}}
{
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": { "type": "grafana", "uid": "-- Grafana --" },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "links": [],
  "panels": [
    {
      "datasource": { "type": "tempo", "uid": {{ $ds | toJson }} },
      "fieldConfig": {
        "defaults": {
          "custom": {
            "align": "auto",
            "cellOptions": { "type": "auto" },
            "footer": { "reducers": [] },
            "inspect": false
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": 0 },
              { "color": "red", "value": 80 }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": { "h": 1, "w": 24, "x": 0, "y": 0 },
      "id": 100,
      "options": { "cellHeight": "sm", "showHeader": true },
      "targets": [
        {
          "datasource": { "type": "tempo", "uid": {{ $ds | toJson }} },
          "filters": [
            {
              "id": "exit-code",
              "operator": {{ $cmp | toJson }},
              "scope": "span",
              "tag": "exit.code",
              "value": ["200"]
            },
            {
              "id": "service-name",
              "operator": "=",
              "scope": "resource",
              "tag": "service.name",
              "value": [{{ $service | toJson }}],
              "valueType": "string"
            },
            {
              "id": "span-name",
              "operator": "=",
              "scope": "span",
              "tag": "name",
              "value": [{{ $span | toJson }}],
              "valueType": "string"
            }
          ],
          "limit": 10000,
          "metricsQueryType": "range",
          "query": {{ $query | toJson }},
          "queryType": "traceqlSearch",
          "refId": "A",
          "tableType": "traces"
        }
      ],
      "title": "Source Data (hidden)",
      "transparent": true,
      "type": "table"
    },
    {
      "datasource": { "type": "datasource", "uid": "-- Dashboard --" },
      "fieldConfig": {
        "defaults": {
          "color": { "fixedColor": {{ $color | toJson }}, "mode": "fixed" },
          "custom": {
            "axisBorderShow": false,
            "axisCenteredZero": false,
            "axisColorMode": "text",
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "barWidthFactor": 0.6,
            "drawStyle": "bars",
            "fillOpacity": 36,
            "gradientMode": "none",
            "hideFrom": { "legend": false, "tooltip": false, "viz": false },
            "insertNulls": false,
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": { "type": "linear" },
            "showPoints": "auto",
            "showValues": false,
            "spanNulls": false,
            "stacking": { "group": "A", "mode": "none" },
            "thresholdsStyle": { "mode": "off" }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": {{ $color | toJson }}, "value": 0 },
              { "color": {{ $color | toJson }}, "value": 80 }
            ]
          }
        },
        "overrides": []
      },
      "gridPos": { "h": 6, "w": 11, "x": 0, "y": 1 },
      "id": 1,
      "options": {
        "legend": { "calcs": [], "displayMode": "list", "placement": "bottom", "showLegend": true },
        "tooltip": { "hideZeros": false, "mode": "single", "sort": "none" }
      },
      "targets": [
        {
          "datasource": { "type": "datasource", "uid": "-- Dashboard --" },
          "panelId": 100,
          "refId": "A"
        }
      ],
      "title": {{ printf "%s (%s)" $label $suffix | toJson }},
      "type": "timeseries"
    },
    {
      "datasource": { "type": "datasource", "uid": "-- Dashboard --" },
      "fieldConfig": {
        "defaults": {
          "color": { "fixedColor": {{ $color | toJson }}, "mode": "fixed" },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [{ "color": {{ $color | toJson }}, "value": 0 }]
          }
        },
        "overrides": []
      },
      "gridPos": { "h": 6, "w": 3, "x": 11, "y": 1 },
      "id": 6,
      "options": {
        "colorMode": "value",
        "graphMode": "area",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": { "calcs": ["count"], "fields": "/^Trace ID$/", "values": false },
        "showPercentChange": false,
        "text": { "valueSize": 60 },
        "textMode": "auto",
        "wideLayout": true
      },
      "targets": [
        {
          "datasource": { "type": "datasource", "uid": "-- Dashboard --" },
          "panelId": 100,
          "refId": "A"
        }
      ],
      "title": {{ printf "%s #" $label | toJson }},
      "type": "stat"
    },
    {
      "datasource": { "type": "datasource", "uid": "-- Dashboard --" },
      "fieldConfig": {
        "defaults": {
          "color": { "fixedColor": {{ $color | toJson }}, "mode": "fixed" },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [{ "color": {{ $color | toJson }}, "value": 0 }]
          },
          "unit": "ms"
        },
        "overrides": []
      },
      "gridPos": { "h": 6, "w": 3, "x": 14, "y": 1 },
      "id": 7,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": { "calcs": ["mean"], "fields": "/^Duration$/", "values": false },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "targets": [
        {
          "datasource": { "type": "datasource", "uid": "-- Dashboard --" },
          "panelId": 100,
          "refId": "A"
        }
      ],
      "title": {{ printf "%s Mean" $label | toJson }},
      "type": "stat"
    },
    {
      "datasource": { "type": "datasource", "uid": "-- Dashboard --" },
      "fieldConfig": {
        "defaults": {
          "color": { "fixedColor": {{ $color | toJson }}, "mode": "fixed" },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [{ "color": {{ $color | toJson }}, "value": 0 }]
          },
          "unit": "ms"
        },
        "overrides": []
      },
      "gridPos": { "h": 6, "w": 3, "x": 17, "y": 1 },
      "id": 8,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": { "calcs": ["stdDev"], "fields": "/^Duration$/", "values": false },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "targets": [
        {
          "datasource": { "type": "datasource", "uid": "-- Dashboard --" },
          "panelId": 100,
          "refId": "A"
        }
      ],
      "title": {{ printf "%s StdDev" $label | toJson }},
      "type": "stat"
    },
    {
      "datasource": { "type": "datasource", "uid": "-- Dashboard --" },
      "fieldConfig": {
        "defaults": {
          "color": { "fixedColor": {{ $color | toJson }}, "mode": "fixed" },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [{ "color": {{ $color | toJson }}, "value": 0 }]
          }
        },
        "overrides": []
      },
      "gridPos": { "h": 6, "w": 4, "x": 20, "y": 1 },
      "id": 9,
      "options": {
        "colorMode": "value",
        "graphMode": "none",
        "justifyMode": "auto",
        "orientation": "auto",
        "percentChangeColorMode": "standard",
        "reduceOptions": { "calcs": ["lastNotNull"], "fields": "/^Start time$/", "values": false },
        "showPercentChange": false,
        "textMode": "auto",
        "wideLayout": true
      },
      "targets": [
        {
          "datasource": { "type": "datasource", "uid": "-- Dashboard --" },
          "panelId": 100,
          "refId": "A"
        }
      ],
      "title": {{ printf "%s Last Time" $label | toJson }},
      "type": "stat"
    },
    {
      "datasource": { "type": "tempo", "uid": {{ $ds | toJson }} },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "palette-classic-by-name" },
          "custom": {
            "align": "auto",
            "cellOptions": { "type": "color-text" },
            "filterable": false,
            "footer": { "reducers": [] },
            "inspect": false,
            "wrapText": false
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              { "color": "green", "value": 0 },
              { "color": "red", "value": 80 }
            ]
          }
        },
        "overrides": [
          {
            "matcher": { "id": "byName", "options": "Trace ID" },
            "properties": [{ "id": "custom.width", "value": 326 }]
          }
        ]
      },
      "gridPos": { "h": 9, "w": 24, "x": 0, "y": 7 },
      "id": 43,
      "options": {
        "cellHeight": "sm",
        "enablePagination": true,
        "showHeader": true,
        "sortBy": []
      },
      "targets": [
        {
          "datasource": { "type": "tempo", "uid": {{ $ds | toJson }} },
          "limit": 20,
          "query": {{ $tableQuery | toJson }},
          "queryType": "traceql",
          "refId": "A",
          "tableType": "traces"
        }
      ],
      "title": {{ printf "%s (%s) - Traces Table" $label $suffix | toJson }},
      "type": "table"
    }
  ],
  "preload": false,
  "refresh": "5m",
  "schemaVersion": 42,
  "tags": ["interlink", {{ .family | toJson }}, {{ $label | toJson }}, {{ $suffix | toJson }}],
  "templating": { "list": [] },
  "time": { "from": "now-30m", "to": "now" },
  "timepicker": {},
  "timezone": "browser",
  "title": {{ $title | toJson }},
  "uid": {{ $uid | toJson }}
}
{{- end -}}

{{/*
Emit every dashboard for one service as ConfigMap data keys: one dashboard per
HTTP operation, and a separate one for the failed (exit.code != 200) case.

Expected context (a dict): service, family, ops (list of dicts with
span/label/selects), ds.
*/}}
{{- define "interlink-mon.serviceDashboards" -}}
{{- $ctx := . -}}
{{- range $op := .ops }}
{{- range $ok := list true false }}
  {{ printf "%s-%s.json" ($op.label | lower) (ternary "ok" "failed" $ok) }}: |
{{ include "interlink-mon.traceDashboard" (dict "service" $ctx.service "family" $ctx.family "ds" $ctx.ds "span" $op.span "label" $op.label "selects" $op.selects "ok" $ok) | indent 4 }}
{{- end }}
{{- end }}
{{- end -}}
