"use client";

import { useEffect, useMemo, useRef } from "react";
import * as maptilersdk from "@maptiler/sdk";
import "@maptiler/sdk/dist/maptiler-sdk.css";
import MapPicker from "./MapPicker";

type MarkerInput = {
  center: [number, number];
  label?: string;
};

type Props = {
  center: [number, number]; // [lat, lng]
  radiusM: number;
  onCenterChange: (lat: number, lng: number) => void;
  className?: string;
  markers?: MarkerInput[];
  interactive?: boolean;
};

const MAPTILER_API_KEY = process.env.NEXT_PUBLIC_MAPTILER_API_KEY ?? "";
const RADIUS_SOURCE_ID = "megrum-radius-source";
const RADIUS_FILL_LAYER_ID = "megrum-radius-fill";
const RADIUS_LINE_LAYER_ID = "megrum-radius-line";

function toLngLat(center: [number, number]): [number, number] {
  return [center[1], center[0]];
}

function createPinElement(label?: string): HTMLDivElement {
  const el = document.createElement("div");
  el.className = "megrum-maptiler-pin";
  el.innerHTML = `
    <div style="
      position: relative;
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: #a695d8;
      box-shadow: 0 0 0 5px rgba(255,255,255,0.95), 0 7px 18px rgba(58,50,74,0.24);
      display: flex;
      align-items: center;
      justify-content: center;
      color: #fff;
      font-size: 13px;
      font-weight: 900;
      line-height: 1;
    ">
      ${label ?? '<span style="width:9px;height:9px;border-radius:50%;background:#fff;display:block;"></span>'}
    </div>
  `;
  return el;
}

function buildRadiusPolygon(center: [number, number], radiusM: number) {
  const [lat, lng] = center;
  const points = 64;
  const earthRadius = 6_378_137;
  const latRad = (lat * Math.PI) / 180;
  const lngRad = (lng * Math.PI) / 180;
  const angularDistance = radiusM / earthRadius;
  const coordinates: number[][] = [];

  for (let i = 0; i <= points; i += 1) {
    const bearing = (2 * Math.PI * i) / points;
    const pointLat = Math.asin(
      Math.sin(latRad) * Math.cos(angularDistance) +
        Math.cos(latRad) * Math.sin(angularDistance) * Math.cos(bearing),
    );
    const pointLng =
      lngRad +
      Math.atan2(
        Math.sin(bearing) * Math.sin(angularDistance) * Math.cos(latRad),
        Math.cos(angularDistance) - Math.sin(latRad) * Math.sin(pointLat),
      );
    coordinates.push([(pointLng * 180) / Math.PI, (pointLat * 180) / Math.PI]);
  }

  return {
    type: "Feature" as const,
    properties: {},
    geometry: {
      type: "Polygon" as const,
      coordinates: [coordinates],
    },
  };
}

function setMapInteractivity(map: maptilersdk.Map, interactive: boolean) {
  const method = interactive ? "enable" : "disable";
  map.dragPan[method]();
  map.scrollZoom[method]();
  map.boxZoom[method]();
  map.keyboard[method]();
  map.doubleClickZoom[method]();
  map.touchZoomRotate[method]();
}

function syncRadiusLayer(
  map: maptilersdk.Map,
  center: [number, number],
  radiusM: number,
  visible: boolean,
) {
  if (!map.isStyleLoaded()) return;

  if (!visible) {
    if (map.getLayer(RADIUS_LINE_LAYER_ID)) map.removeLayer(RADIUS_LINE_LAYER_ID);
    if (map.getLayer(RADIUS_FILL_LAYER_ID)) map.removeLayer(RADIUS_FILL_LAYER_ID);
    if (map.getSource(RADIUS_SOURCE_ID)) map.removeSource(RADIUS_SOURCE_ID);
    return;
  }

  const data = buildRadiusPolygon(center, radiusM);
  const source = map.getSource(RADIUS_SOURCE_ID);
  if (source && "setData" in source) {
    (source as { setData: (nextData: typeof data) => void }).setData(data);
    return;
  }

  map.addSource(RADIUS_SOURCE_ID, {
    type: "geojson",
    data,
  });
  map.addLayer({
    id: RADIUS_FILL_LAYER_ID,
    type: "fill",
    source: RADIUS_SOURCE_ID,
    paint: {
      "fill-color": "#a695d8",
      "fill-opacity": 0.14,
    },
  });
  map.addLayer({
    id: RADIUS_LINE_LAYER_ID,
    type: "line",
    source: RADIUS_SOURCE_ID,
    paint: {
      "line-color": "#a695d8",
      "line-opacity": 0.72,
      "line-width": 2,
    },
  });
}

export default function MapTilerPicker({
  center,
  radiusM,
  onCenterChange,
  className,
  markers,
  interactive = true,
}: Props) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mapRef = useRef<maptilersdk.Map | null>(null);
  const markerRefs = useRef<maptilersdk.Marker[]>([]);
  const initialCenterRef = useRef(center);
  const interactiveRef = useRef(interactive);
  const onCenterChangeRef = useRef(onCenterChange);
  const displayMarkers = useMemo(
    () => (markers && markers.length > 0 ? markers : [{ center }]),
    [center, markers],
  );

  useEffect(() => {
    interactiveRef.current = interactive;
  }, [interactive]);

  useEffect(() => {
    onCenterChangeRef.current = onCenterChange;
  }, [onCenterChange]);

  useEffect(() => {
    if (!MAPTILER_API_KEY || !containerRef.current || mapRef.current) return;

    const initialCenter = initialCenterRef.current;
    const map = new maptilersdk.Map({
      container: containerRef.current,
      style: maptilersdk.MapStyle.STREETS,
      language: maptilersdk.Language.JAPANESE,
      apiKey: MAPTILER_API_KEY,
      center: toLngLat(initialCenter),
      zoom: 15,
      navigationControl: false,
      geolocateControl: false,
      scaleControl: false,
      terrain: false,
      maptilerLogo: false,
      attributionControl: { compact: true },
    });

    mapRef.current = map;
    setMapInteractivity(map, interactiveRef.current);
    map.on("click", (event) => {
      if (!interactiveRef.current) return;
      onCenterChangeRef.current(event.lngLat.lat, event.lngLat.lng);
    });

    return () => {
      markerRefs.current.forEach((marker) => marker.remove());
      markerRefs.current = [];
      map.remove();
      mapRef.current = null;
    };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    setMapInteractivity(map, interactive);
  }, [interactive]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    markerRefs.current.forEach((marker) => marker.remove());
    markerRefs.current = displayMarkers.map((marker, index) => {
      const draggable = interactive && (!markers || markers.length <= 1);
      const pin = new maptilersdk.Marker({
        element: createPinElement(marker.label),
        draggable,
      })
        .setLngLat(toLngLat(marker.center))
        .addTo(map);

      if (draggable && index === 0) {
        pin.on("dragend", () => {
          const lngLat = pin.getLngLat();
          onCenterChange(lngLat.lat, lngLat.lng);
        });
      }
      return pin;
    });
  }, [displayMarkers, interactive, markers, onCenterChange]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    if (displayMarkers.length > 1) {
      const bounds = new maptilersdk.LngLatBounds();
      displayMarkers.forEach((marker) => bounds.extend(toLngLat(marker.center)));
      map.fitBounds(bounds, {
        padding: 36,
        maxZoom: 16,
        duration: 420,
      });
    } else {
      map.easeTo({
        center: toLngLat(displayMarkers[0]?.center ?? center),
        duration: 420,
      });
    }

    const updateRadius = () => {
      syncRadiusLayer(
        map,
        center,
        radiusM,
        !markers || markers.length <= 1,
      );
    };
    if (map.isStyleLoaded()) {
      updateRadius();
    } else {
      map.once("load", updateRadius);
    }
  }, [center, displayMarkers, markers, radiusM]);

  if (!MAPTILER_API_KEY) {
    return (
      <div className={`relative ${className ?? ""}`}>
        <MapPicker
          center={center}
          radiusM={radiusM}
          markers={markers}
          interactive={interactive}
          tileStyle="light"
          onCenterChange={onCenterChange}
          className="h-full w-full"
        />
        <div className="pointer-events-none absolute bottom-2 left-2 rounded-full bg-white/90 px-2 py-1 text-[9.5px] font-bold text-[#3a324a8c] shadow-[0_2px_8px_rgba(58,50,74,0.12)]">
          MapTiler APIキー未設定
        </div>
      </div>
    );
  }

  return (
    <div
      className={`megrum-maptiler-picker relative overflow-hidden ${className ?? ""}`}
    >
      <style>{`
        .megrum-maptiler-picker .maplibregl-ctrl-attrib,
        .megrum-maptiler-picker .maplibregl-ctrl-attrib.maplibregl-compact {
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
        .megrum-maptiler-picker .maplibregl-ctrl-attrib a {
          color: inherit;
          text-decoration: none;
        }
      `}</style>
      <div ref={containerRef} className="h-full w-full" />
    </div>
  );
}
