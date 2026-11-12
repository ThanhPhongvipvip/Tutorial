#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# manage.py - Công Cụ Quản Lý Hệ Thống Giám Sát & Metadata ERD Tập Trung
# ==============================================================================
# Tích hợp toàn bộ chức năng:
# 1. generate  : Sinh tệp cấu hình dashboard (monitoring-dashboard.json)
# 2. import    : Tự động import dashboard lên Grafana qua HTTP API
# 3. collect   : Thu thập metadata PostgreSQL & đẩy về Central Catalog
# ==============================================================================

import os
import sys
import json
import yaml
import subprocess
import urllib.request
import urllib.error
import base64

# ==============================================================================
# PHẦN 1: GENERATE DASHBOARD (Sinh JSON Dashboard Chuẩn)
# ==============================================================================

INFLUX = {"type": "influxdb", "uid": "ag3xs672o3if4e"}
PSQL   = {"type": "postgres", "uid": "fg3xs673n239ca"}

ECHART_FUNCTION = """
// Business Charts (Volkov Labs) - ERD Viewer Chuyên Dụng (Cytoscape.js + ELK.js Chuẩn pgAdmin 4)
let chart = (typeof echartsInstance !== 'undefined') ? echartsInstance : (typeof context !== 'undefined' && context.panel ? context.panel.chart : null);

let dom = null;
if (chart && typeof chart.getDom === 'function') {
  dom = chart.getDom();
} else if (typeof context !== 'undefined' && context.element) {
  dom = context.element;
} else if (typeof context !== 'undefined' && context.container) {
  dom = context.container;
}

if (!dom) {
  dom = document.querySelector('[data-panelid="61"]');
}

let deviceName = '';
let dbName = '';

try {
  if (typeof replaceVariables === 'function') {
    deviceName = replaceVariables('${device}') || '';
    dbName = replaceVariables('${db_name}') || '';
  } else if (typeof context !== 'undefined' && context.grafana && typeof context.grafana.replaceVariables === 'function') {
    deviceName = context.grafana.replaceVariables('${device}') || '';
    dbName = context.grafana.replaceVariables('${db_name}') || '';
  } else if (typeof context !== 'undefined' && context.panel && context.panel.scopedVars) {
    deviceName = context.panel.scopedVars.device?.value || '';
    dbName = context.panel.scopedVars.db_name?.value || '';
  }
} catch (e) {
  console.warn('Error reading Grafana variables:', e);
}

const host = window.location.hostname || 'localhost';
const iframeUrl = 'http://' + host + ':8088/?device=' + encodeURIComponent(deviceName) + '&db=' + encodeURIComponent(dbName);

if (dom) {
  dom.style.position = 'relative';
  dom.style.overflow = 'hidden';
  dom.style.width = '100%';
  dom.style.height = '100%';

  let iframe = dom.querySelector('iframe.erd-iframe');
  if (!iframe) {
    iframe = document.createElement('iframe');
    iframe.className = 'erd-iframe';
    iframe.src = iframeUrl;
    iframe.setAttribute('data-url', iframeUrl);
    iframe.style.position = 'absolute';
    iframe.style.top = '0';
    iframe.style.left = '0';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.style.border = 'none';
    iframe.style.zIndex = '100';
    iframe.style.background = '#f8fafc';
    iframe.style.borderRadius = '6px';
    dom.appendChild(iframe);
  } else if (iframe.getAttribute('data-url') !== iframeUrl) {
    iframe.src = iframeUrl;
    iframe.setAttribute('data-url', iframeUrl);
  }
}

return {};
"""


def generate_dashboard_data():
    panels = []

    # 1. TOP KPI STAT CARDS (Thu nhỏ gọn gàng: w=6, h=3)
    panels.append({
        "id": 1,
        "title": "Tổng Số Thiết Bị",
        "type": "stat",
        "datasource": INFLUX,
        "gridPos": {"x": 0, "y": 0, "w": 6, "h": 3},
        "targets": [{
            "refId": "A",
            "query": (
                'from(bucket: "system_metrics")\n'
                '  |> range(start: -5m)\n'
                '  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_idle")\n'
                '  |> filter(fn: (r) => r.device != "THAY_THANH_TEN_MAY_CUA_BAN")\n'
                '  |> group(columns: ["device"])\n'
                '  |> last()\n'
                '  |> group()\n'
                '  |> count()'
            )
        }],
        "options": {
            "reduceOptions": {"calcs": ["lastNotNull"], "values": False},
            "colorMode": "background",
            "graphMode": "none",
            "justifyMode": "center",
            "textMode": "value",
            "orientation": "auto"
        },
        "fieldConfig": {
            "defaults": {
                "unit": "short",
                "color": {"mode": "fixed", "fixedColor": "blue"},
                "noValue": "0",
                "thresholds": {"mode": "absolute", "steps": [{"color": "blue", "value": None}]}
            },
            "overrides": []
        }
    })

    panels.append({
        "id": 2,
        "title": "Thiết Bị Online",
        "type": "stat",
        "datasource": INFLUX,
        "gridPos": {"x": 6, "y": 0, "w": 6, "h": 3},
        "targets": [{
            "refId": "A",
            "query": (
                'from(bucket: "system_metrics")\n'
                '  |> range(start: -2m)\n'
                '  |> filter(fn: (r) => r._measurement == "cpu" and r._field == "usage_idle")\n'
                '  |> filter(fn: (r) => r.device != "THAY_THANH_TEN_MAY_CUA_BAN")\n'
                '  |> group(columns: ["device"])\n'
                '  |> last()\n'
                '  |> group()\n'
                '  |> count()'
            )
        }],
        "options": {
            "reduceOptions": {"calcs": ["lastNotNull"], "values": False},
            "colorMode": "background",
            "graphMode": "none",
            "justifyMode": "center",
            "textMode": "value",
            "orientation": "auto"
        },
        "fieldConfig": {
            "defaults": {
                "unit": "short",
                "color": {"mode": "fixed", "fixedColor": "green"},
                "noValue": "0",
                "thresholds": {"mode": "absolute", "steps": [{"color": "green", "value": None}]}
            },
            "overrides": []
        }
    })

    # 2. ROW: TÀI NGUYÊN HỆ THỐNG
    panels.append({
        "id": 20,
        "title": "TÀI NGUYÊN HỆ THỐNG: $device",
        "type": "row",
        "gridPos": {"x": 0, "y": 3, "w": 24, "h": 1},
        "collapsed": False
    })

    # 2.1 CPU
    panels.append({
        "id": 21,
        "title": "CPU Usage (%) - ${device}",
        "description": "• CPU Hệ Thống (Kernel)\n• CPU Ứng Dụng (User)",
        "type": "timeseries",
        "datasource": INFLUX,
        "gridPos": {"x": 0, "y": 4, "w": 8, "h": 7},
        "targets": [
            {
                "refId": "System",
                "query": (
                    'from(bucket: "system_metrics")\n'
                    '  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n'
                    '  |> filter(fn: (r) => r._measurement == "cpu" and r.cpu == "cpu-total" and r._field == "usage_system")\n'
                    '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                    '  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n'
                    '  |> drop(columns: ["cpu", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])\n'
                    '  |> yield(name: "System")'
                )
            },
            {
                "refId": "User",
                "query": (
                    'from(bucket: "system_metrics")\n'
                    '  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n'
                    '  |> filter(fn: (r) => r._measurement == "cpu" and r.cpu == "cpu-total" and r._field == "usage_user")\n'
                    '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                    '  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n'
                    '  |> drop(columns: ["cpu", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])\n'
                    '  |> yield(name: "User")'
                )
            }
        ],
        "options": {
            "legend": {"displayMode": "list", "placement": "bottom", "showLegend": True},
            "tooltip": {"mode": "multi", "sort": "desc"}
        },
        "fieldConfig": {
            "defaults": {
                "unit": "percent",
                "custom": {"lineInterpolation": "smooth", "fillOpacity": 15, "spanNulls": True}
            },
            "overrides": [
                {"matcher": {"id": "byFrameRefID", "options": "System"}, "properties": [{"id": "displayName", "value": "CPU Hệ Thống (Kernel)"}, {"id": "color", "value": {"fixedColor": "blue", "mode": "fixed"}}]},
                {"matcher": {"id": "byFrameRefID", "options": "User"}, "properties": [{"id": "displayName", "value": "CPU Ứng Dụng (User)"}, {"id": "color", "value": {"fixedColor": "orange", "mode": "fixed"}}]}
            ]
        }
    })

    # 2.2 RAM
    panels.append({
        "id": 22,
        "title": "RAM Usage (%) - ${device}",
        "type": "timeseries",
        "datasource": INFLUX,
        "gridPos": {"x": 8, "y": 4, "w": 8, "h": 7},
        "targets": [{
            "refId": "RAM",
            "query": (
                'from(bucket: "system_metrics")\n'
                '  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n'
                '  |> filter(fn: (r) => r._measurement == "mem" and r._field == "used_percent")\n'
                '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                '  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n'
                '  |> drop(columns: ["device", "device_name", "host", "location", "_measurement", "_start", "_stop"])\n'
                '  |> yield(name: "RAM")'
            )
        }],
        "options": {
            "legend": {"displayMode": "table", "placement": "bottom", "showLegend": True, "calcs": ["lastNotNull", "max"]}
        },
        "fieldConfig": {
            "defaults": {
                "unit": "percent",
                "color": {"mode": "fixed", "fixedColor": "green"},
                "custom": {"lineInterpolation": "smooth", "fillOpacity": 25, "spanNulls": True}
            },
            "overrides": [{"matcher": {"id": "byFrameRefID", "options": "RAM"}, "properties": [{"id": "displayName", "value": "RAM Đã Dùng (%)"}]}]
        }
    })

    # 2.3 Disk
    panels.append({
        "id": 23,
        "title": "Disk Usage (Root /) - ${device}",
        "type": "piechart",
        "datasource": INFLUX,
        "gridPos": {"x": 16, "y": 4, "w": 8, "h": 7},
        "targets": [{
            "refId": "A",
            "query": (
                'from(bucket: "system_metrics")\n'
                '  |> range(start: -5m)\n'
                '  |> filter(fn: (r) => r._measurement == "disk" and r.path == "/" and (r._field == "used" or r._field == "free"))\n'
                '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                '  |> group(columns: ["_field"])\n'
                '  |> last()\n'
                '  |> map(fn: (r) => ({\n'
                '      _time: r._time,\n'
                '      _field: if r._field == "used" then "Đã dùng" else "Còn trống",\n'
                '      _value: r._value\n'
                '  }))'
            )
        }],
        "options": {
            "pieType": "donut",
            "reduceOptions": {"calcs": ["lastNotNull"], "values": False},
            "displayLabels": ["name", "percent"],
            "legend": {"displayMode": "table", "placement": "bottom", "values": ["value", "percent"]}
        },
        "fieldConfig": {
            "defaults": {"unit": "bytes"},
            "overrides": [
                {"matcher": {"id": "byName", "options": "Đã dùng"}, "properties": [{"id": "color", "value": {"fixedColor": "orange", "mode": "fixed"}}]},
                {"matcher": {"id": "byName", "options": "Còn trống"}, "properties": [{"id": "color", "value": {"fixedColor": "green", "mode": "fixed"}}]}
            ]
        }
    })

    # 2.4 Network Download (Sơ đồ quạt có kim chỉ)
    panels.append({
        "id": 24,
        "title": "Network Download - ${device}",
        "type": "gauge",
        "datasource": INFLUX,
        "gridPos": {"x": 0, "y": 11, "w": 12, "h": 6},
        "targets": [{
            "refId": "Download",
            "query": (
                'from(bucket: "system_metrics")\n'
                '  |> range(start: -15m)\n'
                '  |> filter(fn: (r) => r._measurement == "net" and r._field == "bytes_recv")\n'
                '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                '  |> derivative(unit: 1s, nonNegative: true)\n'
                '  |> last()\n'
                '  |> group()\n'
                '  |> sum(column: "_value")\n'
                '  |> map(fn: (r) => ({_value: if exists r._value and r._value > 0.0 then r._value else 0.0}))'
            )
        }],
        "options": {
            "reduceOptions": {"calcs": ["lastNotNull"], "values": False},
            "orientation": "auto",
            "showThresholdLabels": False,
            "showThresholdMarkers": True
        },
        "fieldConfig": {
            "defaults": {
                "unit": "binBps",
                "min": 0,
                "noValue": "0 B/s",
                "color": {"mode": "thresholds"},
                "thresholds": {
                    "mode": "absolute",
                    "steps": [
                        {"color": "green", "value": None},
                        {"color": "#EAB839", "value": 5242880},
                        {"color": "#E24D42", "value": 20971520}
                    ]
                }
            },
            "overrides": []
        }
    })

    # 2.5 Network Upload (Sơ đồ quạt có kim chỉ)
    panels.append({
        "id": 25,
        "title": "Network Upload - ${device}",
        "type": "gauge",
        "datasource": INFLUX,
        "gridPos": {"x": 12, "y": 11, "w": 12, "h": 6},
        "targets": [{
            "refId": "Upload",
            "query": (
                'from(bucket: "system_metrics")\n'
                '  |> range(start: -15m)\n'
                '  |> filter(fn: (r) => r._measurement == "net" and r._field == "bytes_sent")\n'
                '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                '  |> derivative(unit: 1s, nonNegative: true)\n'
                '  |> last()\n'
                '  |> group()\n'
                '  |> sum(column: "_value")\n'
                '  |> map(fn: (r) => ({_value: if exists r._value and r._value > 0.0 then r._value else 0.0}))'
            )
        }],
        "options": {
            "reduceOptions": {"calcs": ["lastNotNull"], "values": False},
            "orientation": "auto",
            "showThresholdLabels": False,
            "showThresholdMarkers": True
        },
        "fieldConfig": {
            "defaults": {
                "unit": "binBps",
                "min": 0,
                "noValue": "0 B/s",
                "color": {"mode": "thresholds"},
                "thresholds": {
                    "mode": "absolute",
                    "steps": [
                        {"color": "green", "value": None},
                        {"color": "#EAB839", "value": 5242880},
                        {"color": "#E24D42", "value": 20971520}
                    ]
                }
            },
            "overrides": []
        }
    })

    # 3. ROW: GIÁM SÁT CARD ĐỒ HỌA (NVIDIA GPU)
    panels.append({
        "id": 30,
        "title": "GIÁM SÁT CARD ĐỒ HỌA (NVIDIA GPU): $device",
        "type": "row",
        "gridPos": {"x": 0, "y": 17, "w": 24, "h": 1},
        "collapsed": False
    })

    # 3.1 GPU Core Utilization
    panels.append({
        "id": 31,
        "title": "GPU Core Utilization (%) - ${device}",
        "description": "Mức tải GPU Core (%):\n• Nếu hiện 0%: Do GPU đang nhàn rỗi (idle), không có tác vụ AI/đồ hoạ nào.\n• Khi có tác vụ chạy, biểu đồ sẽ hiển thị biến động theo thời gian thực.",
        "type": "timeseries",
        "datasource": INFLUX,
        "gridPos": {"x": 0, "y": 18, "w": 12, "h": 7},
        "targets": [{
            "refId": "A",
            "query": (
                'from(bucket: "system_metrics")\n'
                '  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n'
                '  |> filter(fn: (r) => r._measurement == "nvidia_smi" and r._field == "utilization_gpu")\n'
                '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                '  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n'
                '  |> drop(columns: ["arch", "compute_mode", "pstate", "uuid", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])\n'
                '  |> yield(name: "GPU Core")'
            )
        }],
        "options": {
            "legend": {"displayMode": "table", "placement": "bottom", "showLegend": True, "calcs": ["lastNotNull", "max", "mean"]},
            "tooltip": {"mode": "multi", "sort": "desc"}
        },
        "fieldConfig": {
            "defaults": {
                "unit": "percent",
                "min": 0,
                "max": 100,
                "displayName": "GPU #${__field.labels.index}: ${__field.labels.name}",
                "noValue": "0%",
                "color": {"mode": "palette-classic"},
                "custom": {"lineInterpolation": "smooth", "lineWidth": 2, "fillOpacity": 15, "spanNulls": True}
            },
            "overrides": []
        }
    })

    # 3.2 GPU VRAM Memory
    panels.append({
        "id": 32,
        "title": "GPU VRAM Memory Usage (MiB) - ${device}",
        "type": "timeseries",
        "datasource": INFLUX,
        "gridPos": {"x": 12, "y": 18, "w": 12, "h": 7},
        "targets": [
            {
                "refId": "Used",
                "query": (
                    'from(bucket: "system_metrics")\n'
                    '  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n'
                    '  |> filter(fn: (r) => r._measurement == "nvidia_smi" and r._field == "memory_used")\n'
                    '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                    '  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n'
                    '  |> drop(columns: ["arch", "compute_mode", "pstate", "uuid", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])\n'
                    '  |> yield(name: "Used")'
                )
            },
            {
                "refId": "Total",
                "query": (
                    'from(bucket: "system_metrics")\n'
                    '  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n'
                    '  |> filter(fn: (r) => r._measurement == "nvidia_smi" and r._field == "memory_total")\n'
                    '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                    '  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n'
                    '  |> drop(columns: ["arch", "compute_mode", "pstate", "uuid", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])\n'
                    '  |> yield(name: "Total")'
                )
            }
        ],
        "options": {
            "legend": {"displayMode": "table", "placement": "bottom", "showLegend": True, "calcs": ["lastNotNull", "max"]}
        },
        "fieldConfig": {
            "defaults": {
                "unit": "mbytes",
                "noValue": "Thiết bị không có GPU",
                "custom": {"lineInterpolation": "smooth", "lineWidth": 2, "fillOpacity": 15, "spanNulls": True}
            },
            "overrides": [
                {"matcher": {"id": "byFrameRefID", "options": "Used"}, "properties": [{"id": "displayName", "value": "GPU #${__field.labels.index} (${__field.labels.name}) — Đã dùng"}, {"id": "custom.fillOpacity", "value": 20}]},
                {"matcher": {"id": "byFrameRefID", "options": "Total"}, "properties": [{"id": "displayName", "value": "GPU #${__field.labels.index} (${__field.labels.name}) — Tổng"}, {"id": "custom.lineStyle", "value": {"dash": [6, 4], "fill": "dash"}}, {"id": "custom.fillOpacity", "value": 0}, {"id": "custom.lineWidth", "value": 1}]}
            ]
        }
    })

    # 3.3 GPU Nhiệt Độ
    panels.append({
        "id": 33,
        "title": "GPU Nhiệt Độ (°C) - ${device}",
        "type": "timeseries",
        "datasource": INFLUX,
        "gridPos": {"x": 0, "y": 25, "w": 12, "h": 7},
        "targets": [{
            "refId": "Temp",
            "query": (
                'from(bucket: "system_metrics")\n'
                '  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n'
                '  |> filter(fn: (r) => r._measurement == "nvidia_smi" and r._field == "temperature_gpu")\n'
                '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                '  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)\n'
                '  |> drop(columns: ["arch", "compute_mode", "pstate", "uuid", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])\n'
                '  |> yield(name: "Nhiệt Độ")'
            )
        }],
        "options": {
            "legend": {"displayMode": "table", "placement": "bottom", "showLegend": True, "calcs": ["lastNotNull", "max", "mean"]}
        },
        "fieldConfig": {
            "defaults": {
                "unit": "celsius",
                "displayName": "GPU #${__field.labels.index}: ${__field.labels.name}",
                "custom": {"lineInterpolation": "smooth", "fillOpacity": 20, "spanNulls": True}
            },
            "overrides": []
        }
    })

    # 3.4 GPU Công Suất
    panels.append({
        "id": 35,
        "title": "GPU Công Suất (W) - ${device}",
        "type": "timeseries",
        "datasource": INFLUX,
        "gridPos": {"x": 12, "y": 25, "w": 12, "h": 7},
        "targets": [{
            "refId": "Power",
            "query": (
                'from(bucket: "system_metrics")\n'
                '  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n'
                '  |> filter(fn: (r) => r._measurement == "nvidia_smi" and r._field == "power_draw")\n'
                '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                '  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)\n'
                '  |> drop(columns: ["arch", "compute_mode", "pstate", "uuid", "device", "device_name", "host", "location", "_measurement", "_start", "_stop"])\n'
                '  |> yield(name: "Công Suất")'
            )
        }],
        "options": {
            "legend": {"displayMode": "table", "placement": "bottom", "showLegend": True, "calcs": ["lastNotNull", "max", "mean"]}
        },
        "fieldConfig": {
            "defaults": {
                "unit": "watt",
                "displayName": "GPU #${__field.labels.index}: ${__field.labels.name}",
                "custom": {"lineInterpolation": "linear", "fillOpacity": 0, "lineWidth": 1, "spanNulls": True}
            },
            "overrides": []
        }
    })

    # 4. ROW: DỮ LIỆU TẬP TIN CSV
    panels.append({
        "id": 50,
        "title": "DỮ LIỆU TẬP TIN CSV: $device",
        "type": "row",
        "gridPos": {"x": 0, "y": 32, "w": 24, "h": 1},
        "collapsed": False
    })

    panels.append({
        "id": 51,
        "title": "Bảng Dữ Liệu CSV Chi Tiết: ${device} (Tập tin: ${csv_file})",
        "type": "table",
        "datasource": INFLUX,
        "gridPos": {"x": 0, "y": 33, "w": 24, "h": 9},
        "targets": [{
            "refId": "A",
            "query": (
                'from(bucket: "device_csv")\n'
                '  |> range(start: -30d)\n'
                '  |> filter(fn: (r) => r._measurement == "file")\n'
                '  |> filter(fn: (r) => r.device =~ /^${device:regex}$/)\n'
                '  |> filter(fn: (r) => if "${csv_file}" == ".*" or "${csv_file}" == "All" then true else r.csv_name =~ /^${csv_file:regex}$/ or r.file =~ /^${csv_file:regex}$/)\n'
                '  |> map(fn: (r) => ({ r with row_id: if exists r.row_id then r.row_id else "1" }))\n'
                '  |> group(columns: ["device", "csv_name", "row_id", "_field"])\n'
                '  |> last()\n'
                '  |> toString()\n'
                '  |> group(columns: ["device", "csv_name"])\n'
                '  |> pivot(rowKey: ["row_id"], columnKey: ["_field"], valueColumn: "_value")\n'
                '  |> drop(columns: ["_start", "_stop", "_measurement", "host", "device_name", "location", "source_file", "row_id"])\n'
                '  |> limit(n: 500)'
            )
        }],
        "options": {
            "showHeader": True,
            "footer": {"show": True, "enablePagination": True, "pagination": {"itemsPerPage": 20}}
        },
        "fieldConfig": {
            "defaults": {},
            "overrides": [
                {"matcher": {"id": "byName", "options": "_time"}, "properties": [{"id": "custom.displayName", "value": "Thời Gian"}]},
                {"matcher": {"id": "byName", "options": "device"}, "properties": [{"id": "custom.displayName", "value": "Thiết Bị"}]},
                {"matcher": {"id": "byName", "options": "csv_name"}, "properties": [{"id": "custom.displayName", "value": "Tập Tin"}]}
            ]
        }
    })

    # 5. ROW: SƠ ĐỒ THỰC THỂ QUAN HỆ (ERD) - BUSINESS CHARTS (ECHARTS)
    panels.append({
        "id": 60,
        "title": "SƠ ĐỒ THỰC THỂ QUAN HỆ (ERD) - THIẾT BỊ: $device",
        "type": "row",
        "gridPos": {"x": 0, "y": 42, "w": 24, "h": 1},
        "collapsed": False
    })

    # 1 SQL QUERY DUY NHẤT LẤY CẢ NODE VÀ EDGE TỪ KHO METADATA TẬP TRUNG
    erd_sql = """WITH nodes AS (
    SELECT 
        'node' AS type,
        device || '.' || database_name || '.' || schema_name || '.' || table_name AS id,
        schema_name || '.' || table_name AS label,
        columns_detail AS columns,
        NULL::text AS source,
        NULL::text AS target,
        database_name AS db,
        schema_name AS schema
    FROM db_metadata_tables
    WHERE device = '${device}'
      AND ('${db_name}' = 'All' OR '${db_name}' = '' OR database_name = '${db_name}')
),
edges AS (
    SELECT 
        'edge' AS type,
        constraint_name AS id,
        from_table || ' → ' || to_table AS label,
        COALESCE(cardinality, '1 : 0..N') AS columns,
        device || '.' || database_name || '.' || schema_name || '.' || to_table AS source,
        device || '.' || database_name || '.' || schema_name || '.' || from_table AS target,
        database_name AS db,
        schema_name AS schema
    FROM db_metadata_relations
    WHERE device = '${device}'
      AND ('${db_name}' = 'All' OR '${db_name}' = '' OR database_name = '${db_name}')
)
SELECT * FROM nodes
UNION ALL
SELECT * FROM edges;"""

    panels.append({
        "id": 61,
        "title": "Sơ Đồ Thực Thể Quan Hệ (ERD) Chuẩn pgAdmin 4 — Thiết Bị: ${device} | DB: ${db_name}",
        "description": "Sơ đồ ERD trực quan chuẩn pgAdmin 4 sử dụng Cytoscape.js + ELK.js (Orthogonal routing, tự động sắp xếp Sugiyama, hiển thị đầy đủ PK/FK/Data Type, hỗ trợ zoom, kéo thả và xuất ảnh PNG).",
        "type": "volkovlabs-echarts-panel",
        "datasource": PSQL,
        "gridPos": {"x": 0, "y": 43, "w": 24, "h": 22},
        "targets": [{
            "refId": "A",
            "format": "table",
            "rawSql": erd_sql
        }],
        "options": {
            "getOption": ECHART_FUNCTION.strip()
        }
    })

    dashboard = {
        "__inputs": [
            {
                "name": "DS_INFLUXDB",
                "label": "InfluxDB-Monitoring",
                "description": "Chọn InfluxDB Data Source",
                "type": "datasource",
                "pluginId": "influxdb",
                "pluginName": "InfluxDB"
            }
        ],
        "__elements": {},
        "__requires": [
            {"type": "grafana", "id": "grafana", "name": "Grafana", "version": "10.0.0"},
            {"type": "datasource", "id": "influxdb", "name": "InfluxDB", "version": "1.0.0"},
            {"type": "datasource", "id": "postgres", "name": "PostgreSQL", "version": "1.0.0"},
            {"type": "panel", "id": "volkovlabs-echarts-panel", "name": "Business Charts", "version": "5.0.0"}
        ],
        "editable": True,
        "graphTooltip": 1,
        "id": None,
        "liveNow": False,
        "panels": panels,
        "refresh": "10s",
        "schemaVersion": 38,
        "style": "dark",
        "tags": ["monitoring", "gpu", "erd", "business-charts"],
        "templating": {
            "list": [
                {
                    "name": "ds_postgres",
                    "label": "Kho Metadata Catalog",
                    "type": "datasource",
                    "query": "grafana-postgresql-datasource",
                    "refresh": 1,
                    "hide": 0,
                    "current": {
                        "selected": True,
                        "text": "grafana-postgresql-datasource",
                        "value": "grafana-postgresql-datasource"
                    },
                    "options": [],
                    "skipUrlSync": False
                },
                {
                    "name": "device",
                    "label": "Thiết Bị (Device)",
                    "type": "query",
                    "datasource": INFLUX,
                    "definition": 'import "influxdata/influxdb/schema"\nschema.tagValues(bucket: "system_metrics", tag: "device")\n  |> filter(fn: (r) => r._value != "THAY_THANH_TEN_MAY_CUA_BAN" and r._value != "")',
                    "query": 'import "influxdata/influxdb/schema"\nschema.tagValues(bucket: "system_metrics", tag: "device")\n  |> filter(fn: (r) => r._value != "THAY_THANH_TEN_MAY_CUA_BAN" and r._value != "")',
                    "regex": "/^(?!THAY_THANH_TEN_MAY_CUA_BAN$).*/",
                    "refresh": 2,
                    "sort": 1,
                    "multi": False,
                    "includeAll": False,
                    "hide": 0,
                    "current": {},
                    "options": [],
                    "skipUrlSync": False
                },
                {
                    "name": "db_name",
                    "label": "Cơ Sở Dữ Liệu",
                    "type": "query",
                    "datasource": PSQL,
                    "definition": "SELECT DISTINCT database_name FROM db_metadata_tables WHERE device = '${device}' ORDER BY database_name;",
                    "query": "SELECT DISTINCT database_name FROM db_metadata_tables WHERE device = '${device}' ORDER BY database_name;",
                    "refresh": 2,
                    "multi": False,
                    "includeAll": False,
                    "allValue": "All",
                    "hide": 0,
                    "current": {
                        "selected": True,
                        "text": "All",
                        "value": "All"
                    },
                    "options": [],
                    "skipUrlSync": False
                },
                
                {
                    "name": "csv_file",
                    "label": "Tập Tin CSV",
                    "type": "query",
                    "datasource": INFLUX,
                    "definition": 'import "influxdata/influxdb/schema"\nschema.tagValues(bucket: "device_csv", tag: "csv_name")',
                    "query": 'import "influxdata/influxdb/schema"\nschema.tagValues(bucket: "device_csv", tag: "csv_name")',
                    "refresh": 2,
                    "sort": 1,
                    "multi": False,
                    "includeAll": True,
                    "allValue": ".*",
                    "hide": 0,
                    "current": {
                        "selected": True,
                        "text": "All",
                        "value": ".*"
                    },
                    "options": [],
                    "skipUrlSync": False
                }
            ]
        },
        "time": {"from": "now-6h", "to": "now"},
        "timepicker": {"refresh_intervals": ["5s", "10s", "30s", "1m", "5m", "15m", "1h"]},
        "timezone": "browser",
        "title": "System Monitoring & Central ERD Dashboard",
        "uid": "monitoring",
        "version": 1
    }

    return dashboard

def cmd_generate(args=None):
    base_dir = os.path.dirname(os.path.abspath(__file__))
    out_file = os.path.join(base_dir, "monitoring-dashboard.json")
    db = generate_dashboard_data()
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(db, f, indent=2, ensure_ascii=False)
    print(f" Đã tạo thành công tệp dashboard: {out_file}")

# ==============================================================================
# PHẦN 2: IMPORT DASHBOARD VÀO GRAFANA QUA HTTP API (Thuần Python)
# ==============================================================================

def cmd_import(args=None):
    base_dir = os.path.dirname(os.path.abspath(__file__))
    json_path = os.path.join(base_dir, "monitoring-dashboard.json")
    if not os.path.exists(json_path):
        cmd_generate()

    grafana_url = os.environ.get("GRAFANA_URL", "http://localhost:3000").rstrip("/")
    user = os.environ.get("GRAFANA_USER", "admin")
    password = os.environ.get("GRAFANA_PASS", "admin")
    api_key = os.environ.get("GRAFANA_API_KEY", "")

    # Parse arguments if provided
    if args:
        for i, a in enumerate(args):
            if a == "--url" and i + 1 < len(args): grafana_url = args[i+1].rstrip("/")
            elif a == "--user" and i + 1 < len(args): user = args[i+1]
            elif a == "--pass" and i + 1 < len(args): password = args[i+1]
            elif a == "--api-key" and i + 1 < len(args): api_key = args[i+1]

    print(f" Bắt đầu import dashboard vào Grafana tại {grafana_url}...")

    # Load dashboard JSON
    with open(json_path, "r", encoding="utf-8") as f:
        dashboard_content = json.load(f)

    headers = {"Content-Type": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    else:
        creds = base64.b64encode(f"{user}:{password}".encode("utf-8")).decode("utf-8")
        headers["Authorization"] = f"Basic {creds}"

    # 1. Kiểm tra kết nối tới Grafana
    try:
        req = urllib.request.Request(f"{grafana_url}/api/health", headers=headers)
        with urllib.request.urlopen(req, timeout=5) as resp:
            if resp.status == 200:
                print(" Kết nối tới Grafana thành công!")
    except Exception as e:
        print(f" Không thể kết nối tới Grafana tại {grafana_url}: {e}")
        print(" Hãy kiểm tra xem service Grafana đã chạy chưa: sudo systemctl status grafana-server")
        print(" Hoặc bạn có thể import thủ công qua Web UI: Dashboards -> New -> Import -> tải file monitoring-dashboard.json")
        return False

    # 2. Chuẩn bị payload import (single dashboard with UID: monitoring)
    targets = [
        ("monitoring", "System Monitoring & ERD Dashboard"),
        ("monitoring-v7", "System Monitoring & Central ERD Dashboard"),
        ("monitoring-v8", "System Monitoring & Central ERD Dashboard a")
    ]
    success_count = 0
    try:
        for uid, title in targets:
            db_copy = json.loads(json.dumps(dashboard_content))
            db_copy["uid"] = uid
            db_copy["title"] = title
            payload = {
                "dashboard": db_copy,
                "overwrite": True
            }
            data_bytes = json.dumps(payload).encode("utf-8")
            req = urllib.request.Request(f"{grafana_url}/api/dashboards/db", data=data_bytes, headers=headers, method="POST")
            with urllib.request.urlopen(req, timeout=10) as resp:
                result = json.loads(resp.read().decode("utf-8"))
                print("============================================================")
                print(" IMPORT DASHBOARD THÀNH CÔNG LÊN GRAFANA!")
                print(f" Tiêu đề: {result.get('title')}")
                print(f" UID    : {result.get('uid')}")
                print(f" Đường dẫn: {grafana_url}{result.get('url')}")
                print("============================================================")
                success_count += 1
        return success_count > 0
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        if e.code == 401:
            print(f" Lỗi xác thực tài khoản Grafana (401 Unauthorized): Sai username hoặc password.")
            print(" Mật khẩu mặc định 'admin' có thể đã được thay đổi khi bạn đăng nhập Grafana lần đầu.")
            print("\n Cách 1: Chạy lại lệnh kèm thông tin đăng nhập của bạn:")
            print("   python3 manage.py import --user <ten_dang_nhap> --pass <mat_khau_cua_ban>")
            print("\n Cách 2: Import trực tiếp qua giao diện Web Grafana (cực nhanh):")
            print("   1. Truy cập trình duyệt: http://localhost:3000 (hoặc http://<IP_MAY_A>:3000)")
            print("   2. Vào mục: Dashboards -> New -> Import")
            print("   3. Bấm 'Upload dashboard JSON file' và chọn:")
            print(f"      {json_path}")
            print("   4. Bấm Import để hoàn tất!")
            print("\n Cách 3: Nếu bạn quên mật khẩu Grafana, đặt lại bằng lệnh:")
            print("   sudo grafana-cli admin reset-admin-password admin")
        else:
            print(f" Lỗi HTTP khi import ({e.code}): {err_body}")
        return False
    except Exception as e:
        print(f" Lỗi khi gửi dữ liệu import: {e}")
        return False

# ==============================================================================
# PHẦN 3: COLLECT ERD METADATA (Thu Thập Metadata PostgreSQL)
# ==============================================================================

def run_psql_query(host, port, user, password, dbname, query):
    env = os.environ.copy()
    if password:
        env["PGPASSWORD"] = password
    cmd = [
        "psql",
        "-h", str(host),
        "-p", str(port),
        "-U", str(user),
        "-d", str(dbname),
        "-t", "-A", "-F", "\t",
        "-c", query
    ]
    res = subprocess.run(cmd, env=env, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"[CẢNH BÁO] Lỗi truy vấn PostgreSQL tại {dbname}: {res.stderr.strip()}", file=sys.stderr)
        return []
    lines = [line.strip() for line in res.stdout.split("\n") if line.strip()]
    return [line.split("\t") for line in lines]

def cmd_collect(args=None):
    base_dir = os.path.dirname(os.path.abspath(__file__))
    cfg_file = args[0] if (args and len(args) > 0) else os.path.join(base_dir, "device.yaml")
    if not os.path.exists(cfg_file):
        for candidate in [
            os.path.join(base_dir, "..", "May_Khac", "device.yaml"),
            "/etc/monitor-agent/device.yaml",
            os.path.join(base_dir, "device.yaml"),
            "device.yaml"
        ]:
            if os.path.exists(candidate):
                cfg_file = candidate
                break

    if not os.path.exists(cfg_file):
        print(f" Không tìm thấy tệp cấu hình: {cfg_file}")
        return

    with open(cfg_file, "r", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)

    device_id = cfg.get("device", {}).get("id", "")
    if not device_id or device_id in ("auto", "THAY_THANH_TEN_MAY_CUA_BAN"):
        device_id = subprocess.run(["hostname", "-s"], capture_output=True, text=True).stdout.strip() or "device"

    # Central Catalog
    central_cfg = cfg.get("central_catalog", {})
    influx_url = cfg.get("influxdb", {}).get("url", "http://localhost:8086")
    import urllib.parse
    parsed = urllib.parse.urlparse(influx_url)
    default_central_host = parsed.hostname or "127.0.0.1"

    central_host = central_cfg.get("host", default_central_host)
    central_port = central_cfg.get("port", 5432)
    central_user = central_cfg.get("user", "grafana_reader")
    central_pass = central_cfg.get("password", "1")
    central_db   = central_cfg.get("database", "monitoring_catalog")

    pg_cfg = cfg.get("postgresql", {})
    if not pg_cfg.get("enabled", True):
        print("ℹ Tính năng giám sát PostgreSQL bị tắt trong device.yaml.")
        return

    instances = pg_cfg.get("instances", [])
    if not instances:
        instances = [{"name": "local", "host": "localhost", "port": 5432, "username": "postgres", "password": "", "databases": ["postgres"]}]

    sql_tables = """
    WITH col_info AS (
        SELECT 
            c.table_schema,
            c.table_name,
            COUNT(c.column_name) as col_count,
            string_agg(
                (CASE 
                    WHEN pk.column_name IS NOT NULL THEN 'PK'
                    WHEN fk.column_name IS NOT NULL THEN 'FK'
                    ELSE '—'
                END)
                || '^' || c.column_name
                || '^' || (CASE 
                    WHEN c.character_maximum_length IS NOT NULL THEN c.data_type || '(' || c.character_maximum_length || ')'
                    ELSE c.data_type
                END)
                || '^' || (CASE WHEN c.is_nullable = 'NO' THEN 'NOT NULL' ELSE 'NULL' END),
                '|||' ORDER BY c.ordinal_position
            ) as columns_detail
        FROM information_schema.columns c
        JOIN information_schema.tables t 
            ON t.table_name = c.table_name 
            AND t.table_schema = c.table_schema 
            AND t.table_type = 'BASE TABLE'
        LEFT JOIN (
            SELECT DISTINCT kcu.table_schema, kcu.table_name, kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name 
                AND tc.table_schema = kcu.table_schema
            WHERE tc.constraint_type = 'PRIMARY KEY'
        ) pk ON pk.table_schema = c.table_schema AND pk.table_name = c.table_name AND pk.column_name = c.column_name
        LEFT JOIN (
            SELECT DISTINCT kcu.table_schema, kcu.table_name, kcu.column_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu 
                ON tc.constraint_name = kcu.constraint_name 
                AND tc.table_schema = kcu.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
        ) fk ON fk.table_schema = c.table_schema AND fk.table_name = c.table_name AND fk.column_name = c.column_name
        WHERE c.table_schema NOT IN ('pg_catalog', 'information_schema')
          AND c.table_name NOT LIKE 'v_grafana_%'
        GROUP BY c.table_schema, c.table_name
    )
    SELECT table_schema, table_name, col_count, columns_detail FROM col_info;
    """

    sql_relations = """
    SELECT 
        tc.table_schema,
        tc.constraint_name,
        tc.table_name as from_table,
        kcu.column_name as from_column,
        ccu.table_name as to_table,
        ccu.column_name as to_column,
        CASE WHEN c.is_nullable = 'YES' THEN '0..1 : 0..N' ELSE '1 : 0..N' END as cardinality
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name 
        AND tc.table_schema = kcu.table_schema
    JOIN information_schema.constraint_column_usage ccu 
        ON ccu.constraint_name = tc.constraint_name 
        AND ccu.table_schema = tc.table_schema
    JOIN information_schema.columns c
        ON c.table_schema = tc.table_schema
        AND c.table_name = tc.table_name
        AND c.column_name = kcu.column_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema NOT IN ('pg_catalog', 'information_schema');
    """

    all_tables = []
    all_relations = []

    for inst in instances:
        i_host = inst.get("host", "localhost")
        i_port = inst.get("port", 5432)
        i_user = inst.get("username", "postgres")
        i_pass = inst.get("password", "")
        inst_device = inst.get("device") or device_id
        raw_dbs = inst.get("databases", [])

        # Auto-discover databases if dbs is auto, all, *, or empty
        if not raw_dbs or raw_dbs in ("auto", "all", "*") or raw_dbs == ["auto"] or raw_dbs == ["*"]:
            print(f" Đang tự động phát hiện danh sách Database trên {i_host}:{i_port}...")
            sql_dbs = "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('monitoring_catalog');"
            found_dbs = run_psql_query(i_host, i_port, i_user, i_pass, "postgres", sql_dbs)
            dbs = [row[0] for row in found_dbs if row] or ["postgres"]
            print(f" Đã phát hiện {len(dbs)} Database: {', '.join(dbs)}")
        else:
            dbs = raw_dbs if isinstance(raw_dbs, list) else [raw_dbs]

        for db in dbs:
            print(f" Đang quét metadata ERD thiết bị '{inst_device}', Database '{db}' tại {i_host}:{i_port}...")
            tbls = run_psql_query(i_host, i_port, i_user, i_pass, db, sql_tables)
            for t in tbls:
                if len(t) >= 4:
                    all_tables.append((inst_device, db, t[0], t[1], int(t[2]), t[3]))

            rels = run_psql_query(i_host, i_port, i_user, i_pass, db, sql_relations)
            for r in rels:
                if len(r) >= 7:
                    all_relations.append((inst_device, db, r[0], r[1], r[2], r[3], r[4], r[5], r[6]))
                elif len(r) >= 6:
                    all_relations.append((inst_device, db, r[0], r[1], r[2], r[3], r[4], r[5], "1 : 0..N"))

    if not all_tables and not all_relations:
        print(" Không có dữ liệu metadata nào được tìm thấy.")
        return

    # Gửi về Central Catalog
    statements = []
    for r in all_tables:
        device, db_name, schema, tbl, count, detail = r
        escaped_detail = detail.replace("'", "''")
        statements.append(f"""
        INSERT INTO db_metadata_tables (device, database_name, schema_name, table_name, column_count, columns_detail, updated_at)
        VALUES ('{device}', '{db_name}', '{schema}', '{tbl}', {count}, '{escaped_detail}', CURRENT_TIMESTAMP)
        ON CONFLICT (device, database_name, schema_name, table_name) 
        DO UPDATE SET column_count = EXCLUDED.column_count, columns_detail = EXCLUDED.columns_detail, updated_at = CURRENT_TIMESTAMP;
        """)

    for r in all_relations:
        device, db_name, schema, c_name, from_tbl, from_col, to_tbl, to_col, card = r
        statements.append(f"""
        INSERT INTO db_metadata_relations (device, database_name, schema_name, constraint_name, from_table, from_column, to_table, to_column, cardinality, updated_at)
        VALUES ('{device}', '{db_name}', '{schema}', '{c_name}', '{from_tbl}', '{from_col}', '{to_tbl}', '{to_col}', '{card}', CURRENT_TIMESTAMP)
        ON CONFLICT (device, database_name, schema_name, constraint_name)
        DO UPDATE SET from_table = EXCLUDED.from_table, from_column = EXCLUDED.from_column, to_table = EXCLUDED.to_table, to_column = EXCLUDED.to_column, cardinality = EXCLUDED.cardinality, updated_at = CURRENT_TIMESTAMP;
        """)

    full_sql = "\n".join(statements)
    env = os.environ.copy()
    if central_pass:
        env["PGPASSWORD"] = central_pass

    cmd = [
        "psql",
        "-h", str(central_host),
        "-p", str(central_port),
        "-U", str(central_user),
        "-d", str(central_db),
        "-c", full_sql
    ]
    res = subprocess.run(cmd, env=env, capture_output=True, text=True)
    if res.returncode == 0:
        print(f" Đã đồng bộ thành công {len(all_tables)} bảng và {len(all_relations)} quan hệ khóa ngoại về Central Catalog ({central_host}:{central_db})")
    else:
        print(f" Lỗi khi gửi dữ liệu về Central Catalog: {res.stderr.strip()}", file=sys.stderr)

# ==============================================================================
# MAIN ENTRYPOINT
# ==============================================================================

def print_help():
    print("""
================================================================================
  manage.py - Công Cụ Quản Lý Hệ Thống Giám Sát & Metadata ERD
================================================================================

Cách sử dụng:
  python3 manage.py <lệnh> [tùy_chọn]

Các lệnh khả dụng:
  generate   : Tự động sinh tệp monitoring-dashboard.json chuẩn mới nhất
  import     : Tự động import tệp dashboard lên Grafana qua HTTP API
  collect    : Thu thập metadata PostgreSQL từ máy này và đẩy về Central Catalog
  help       : Hiển thị hướng dẫn này

Ví dụ:
  python3 manage.py generate
  python3 manage.py import
  python3 manage.py collect device.yaml
================================================================================
""")

def main():
    if len(sys.argv) < 2:
        cmd_generate()
        print("\n Chạy 'python3 manage.py import' để tự động nạp dashboard lên Grafana.")
        return

    cmd = sys.argv[1].lower()
    extra_args = sys.argv[2:]

    if cmd in ["generate", "gen", "build"]:
        cmd_generate(extra_args)
    elif cmd in ["import", "push"]:
        cmd_import(extra_args)
    elif cmd in ["collect", "collect-erd", "sync"]:
        cmd_collect(extra_args)
    elif cmd in ["help", "-h", "--help"]:
        print_help()
    else:
        print(f" Lệnh không hợp lệ: {cmd}")
        print_help()

if __name__ == "__main__":
    main()
