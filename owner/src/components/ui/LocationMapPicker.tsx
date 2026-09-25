import { useEffect, useState, useRef } from 'react'
import { MapContainer, TileLayer, Marker, useMapEvents, useMap } from 'react-leaflet'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import { Search, Crosshair, Loader2 } from 'lucide-react'

// Default marker icon assets aren't bundled correctly by Vite unless pointed at a CDN.
const markerIcon = new L.Icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
})

// Nepal's rough center — a sane default before an address/GPS pin narrows it down.
const DEFAULT_CENTER: [number, number] = [28.3949, 84.124]
const DEFAULT_ZOOM = 6
const PINNED_ZOOM = 16

interface GeocodeResult {
  display_name: string
  lat: string
  lon: string
}

function ClickToPin({ onPick }: { onPick: (lat: number, lng: number) => void }) {
  useMapEvents({
    click(e) {
      onPick(e.latlng.lat, e.latlng.lng)
    },
  })
  return null
}

/** Recenters the map imperatively whenever the marker position changes from outside a click (search, GPS). */
function FlyTo({ position }: { position: [number, number] | null }) {
  const map = useMap()
  useEffect(() => {
    if (position) map.flyTo(position, Math.max(map.getZoom(), PINNED_ZOOM), { duration: 0.6 })
  }, [position]) // eslint-disable-line react-hooks/exhaustive-deps
  return null
}

export default function LocationMapPicker({
  latitude,
  longitude,
  address,
  city,
  onChange,
}: {
  latitude: string
  longitude: string
  address: string
  city: string
  onChange: (lat: string, lng: string) => void
}) {
  const [query, setQuery] = useState('')
  const [searching, setSearching] = useState(false)
  const [searchError, setSearchError] = useState<string | null>(null)
  const [locating, setLocating] = useState(false)
  const hasHydratedQuery = useRef(false)

  const lat = latitude ? Number(latitude) : null
  const lng = longitude ? Number(longitude) : null
  const position: [number, number] | null = lat !== null && lng !== null && !Number.isNaN(lat) && !Number.isNaN(lng)
    ? [lat, lng]
    : null

  // Prefill the search box once from the address/city fields already typed above, so the
  // admin doesn't have to retype what they just entered.
  useEffect(() => {
    if (hasHydratedQuery.current) return
    const seed = [address, city].filter(Boolean).join(', ')
    if (seed) {
      setQuery(seed)
      hasHydratedQuery.current = true
    }
  }, [address, city])

  const setPosition = (nextLat: number, nextLng: number) => {
    onChange(nextLat.toFixed(7), nextLng.toFixed(7))
  }

  const runSearch = async () => {
    if (!query.trim()) return
    setSearching(true)
    setSearchError(null)
    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${encodeURIComponent(query)}`,
        { headers: { Accept: 'application/json' } }
      )
      if (!res.ok) throw new Error('Search failed')
      const results: GeocodeResult[] = await res.json()
      if (!results.length) {
        setSearchError('No matching location found')
        return
      }
      setPosition(Number(results[0].lat), Number(results[0].lon))
    } catch {
      setSearchError('Could not search that address, try pinning it manually')
    } finally {
      setSearching(false)
    }
  }

  const useMyLocation = () => {
    if (!navigator.geolocation) {
      setSearchError('Location access is not available in this browser')
      return
    }
    setLocating(true)
    setSearchError(null)
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setPosition(pos.coords.latitude, pos.coords.longitude)
        setLocating(false)
      },
      () => {
        setSearchError('Could not get current location')
        setLocating(false)
      },
      { enableHighAccuracy: true, timeout: 8000 }
    )
  }

  return (
    <div className="location-picker">
      <div className="location-picker-search">
        <div className="location-picker-search-input">
          <Search size={15} />
          <input
            className="input"
            placeholder="Search an address to pin…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault()
                runSearch()
              }
            }}
          />
        </div>
        <button type="button" className="btn btn-ghost btn-sm" onClick={runSearch} disabled={searching}>
          {searching ? <Loader2 size={14} className="spin" /> : 'Search'}
        </button>
        <button
          type="button"
          className="btn btn-ghost btn-sm"
          onClick={useMyLocation}
          disabled={locating}
          title="Use my current location"
        >
          {locating ? <Loader2 size={14} className="spin" /> : <Crosshair size={14} />}
        </button>
      </div>
      {searchError && <div className="location-picker-hint location-picker-error">{searchError}</div>}

      <div className="location-picker-map">
        <MapContainer
          center={position ?? DEFAULT_CENTER}
          zoom={position ? PINNED_ZOOM : DEFAULT_ZOOM}
          style={{ height: '220px', width: '100%' }}
        >
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />
          <ClickToPin onPick={setPosition} />
          <FlyTo position={position} />
          {position && (
            <Marker
              position={position}
              icon={markerIcon}
              draggable
              eventHandlers={{
                dragend: (e) => {
                  const m = e.target as L.Marker
                  const p = m.getLatLng()
                  setPosition(p.lat, p.lng)
                },
              }}
            />
          )}
        </MapContainer>
      </div>

      <div className="location-picker-hint">
        {position
          ? `Pinned at ${position[0].toFixed(6)}, ${position[1].toFixed(6)} — click, drag the marker, or search to adjust`
          : 'Click anywhere on the map, search an address, or use your current location to drop a pin'}
      </div>

      <div className="form-row">
        <div className="form-group">
          <label>Latitude</label>
          <input
            className="input"
            inputMode="decimal"
            placeholder="27.7172"
            value={latitude}
            onChange={(e) => onChange(e.target.value, longitude)}
          />
        </div>
        <div className="form-group">
          <label>Longitude</label>
          <input
            className="input"
            inputMode="decimal"
            placeholder="85.3240"
            value={longitude}
            onChange={(e) => onChange(latitude, e.target.value)}
          />
        </div>
      </div>
    </div>
  )
}
