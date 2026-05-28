"use client";

import { useEffect, useMemo, useRef } from "react";
import {
  AttributionControl,
  MapContainer,
  TileLayer,
  Marker,
  Circle,
  useMap,
  useMapEvents,
} from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

/**
 * Leaflet ベースの地図ピッカー（クライアント専用）。
 *
 * - OpenStreetMap 標準タイル、または light 系タイルを使用
 * - center / radiusM を props として受け取り、変更を onChange で通知
 * - マーカードラッグ・地図クリックで center 更新
 * - Megrum ブランドカラーの DivIcon ピン
 */

type Props = {
  center: [number, number]; // [lat, lng]
  radiusM: number;
  onCenterChange: (lat: number, lng: number) => void;
  className?: string;
  markers?: Array<{
    center: [number, number];
    label?: string;
  }>;
  interactive?: boolean;
  tileStyle?: "standard" | "light";
};

const TILE_STYLES = {
  standard: {
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    url: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    maxZoom: 19,
  },
  light: {
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> &copy; <a href="https://carto.com/attributions">CARTO</a>',
    url: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
    maxZoom: 20,
  },
};

// Megrum lavender pin（DivIcon で完全カスタム）
const pinIcon = L.divIcon({
  className: "megrum-pin",
  html: `
    <div style="
      position: relative;
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: #a695d8;
      box-shadow: 0 0 0 5px #fff, 0 6px 14px rgba(0,0,0,0.25);
      display: flex;
      align-items: center;
      justify-content: center;
    ">
      <div style="
        width: 9px;
        height: 9px;
        background: #fff;
        border-radius: 50%;
      "></div>
    </div>
  `,
  iconSize: [32, 32],
  iconAnchor: [16, 16],
});

function buildPinIcon(label?: string) {
  if (!label) return pinIcon;
  return L.divIcon({
    className: "megrum-pin",
    html: `
      <div style="
        position: relative;
        width: 32px;
        height: 32px;
        border-radius: 50%;
        background: #a695d8;
        box-shadow: 0 0 0 5px #fff, 0 6px 14px rgba(0,0,0,0.25);
        display: flex;
        align-items: center;
        justify-content: center;
        color: #fff;
        font-size: 13px;
        font-weight: 900;
        line-height: 1;
      ">${label}</div>
    `,
    iconSize: [32, 32],
    iconAnchor: [16, 16],
  });
}

/**
 * 地図クリック・地図ドラッグ後の center 通知用の inner component。
 * react-leaflet の hooks は MapContainer の中でしか使えない。
 */
function MapEventHandler({
  onCenterChange,
}: {
  onCenterChange: (lat: number, lng: number) => void;
}) {
  useMapEvents({
    click(e) {
      onCenterChange(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

/**
 * 外部から center が変わった時にビューを追従させる。
 */
function FlyToCenter({ center }: { center: [number, number] }) {
  const map = useMap();
  useEffect(() => {
    map.setView(center, map.getZoom(), { animate: true });
  }, [map, center]);
  return null;
}

function FitMarkers({
  markers,
  center,
}: {
  markers: Array<{ center: [number, number] }>;
  center: [number, number];
}) {
  const map = useMap();
  useEffect(() => {
    if (markers.length <= 1) {
      map.setView(markers[0]?.center ?? center, map.getZoom(), {
        animate: true,
      });
      return;
    }
    const bounds = L.latLngBounds(
      markers.map((marker) => [marker.center[0], marker.center[1]]),
    );
    map.fitBounds(bounds, {
      padding: [36, 36],
      maxZoom: 16,
      animate: true,
    });
  }, [center, map, markers]);
  return null;
}

export default function MapPicker({
  center,
  radiusM,
  onCenterChange,
  className,
  markers,
  interactive = true,
  tileStyle = "standard",
}: Props) {
  const markerRef = useRef<L.Marker | null>(null);
  const displayMarkers =
    markers && markers.length > 0 ? markers : [{ center }];
  const tile = TILE_STYLES[tileStyle];

  // Marker drag end handler
  const eventHandlers = useMemo(
    () => ({
      dragend() {
        const m = markerRef.current;
        if (m) {
          const p = m.getLatLng();
          onCenterChange(p.lat, p.lng);
        }
      },
    }),
    [onCenterChange],
  );

  return (
    <div className={`megrum-map-picker ${className ?? ""}`}>
      <style>{`
        .megrum-map-picker .leaflet-control-attribution {
          margin: 0 4px 3px 0;
          padding: 1px 4px;
          border-radius: 999px;
          background: rgba(255, 255, 255, 0.66);
          color: rgba(58, 50, 74, 0.52);
          font-size: 7px;
          font-weight: 600;
          line-height: 1.15;
          max-width: 148px;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
          box-shadow: 0 1px 4px rgba(58, 50, 74, 0.08);
        }
        .megrum-map-picker .leaflet-control-attribution a {
          color: inherit;
          text-decoration: none;
        }
      `}</style>
      <MapContainer
        center={center}
        zoom={15}
        style={{ width: "100%", height: "100%" }}
        dragging={interactive}
        doubleClickZoom={interactive}
        scrollWheelZoom={interactive}
        zoomControl={false}
        attributionControl={false}
      >
        <AttributionControl position="bottomright" prefix={false} />
        <TileLayer
          attribution={tile.attribution}
          url={tile.url}
          maxZoom={tile.maxZoom}
        />
        {(!markers || markers.length <= 1) && (
          <Circle
            center={center}
            radius={radiusM}
            pathOptions={{
              color: "#a695d8",
              fillColor: "#a695d8",
              fillOpacity: 0.15,
              weight: 2,
            }}
          />
        )}
        {displayMarkers.map((marker, index) => (
          <Marker
            key={`${marker.center[0]}-${marker.center[1]}-${index}`}
            position={marker.center}
            draggable={interactive && (!markers || markers.length <= 1)}
            icon={buildPinIcon(marker.label)}
            eventHandlers={
              interactive && (!markers || markers.length <= 1)
                ? eventHandlers
                : undefined
            }
            ref={index === 0 ? markerRef : undefined}
          />
        ))}
        {interactive && <MapEventHandler onCenterChange={onCenterChange} />}
        {markers && markers.length > 0 ? (
          <FitMarkers markers={markers} center={center} />
        ) : (
          <FlyToCenter center={center} />
        )}
      </MapContainer>
    </div>
  );
}
