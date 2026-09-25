import { useRef, useState, FormEvent, ChangeEvent } from 'react'
import { X, ImagePlus, MapPin, ChevronDown, ChevronUp } from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../../hooks/redux'
import { createBusiness } from '../../features/business/businessSlice'
import LocationMapPicker from './LocationMapPicker'

const emptyForm = {
  name: '',
  type: 'restaurant',
  phone: '',
  email: '',
  address: '',
  city: '',
  latitude: '',
  longitude: '',
  owner_full_name: '',
  owner_phone: '',
  owner_email: '',
  owner_password: '',
}

/** super_admin: onboard a restaurant/hotel/cafe + its owner account, live immediately, from the Restaurants tab. */
export default function AddRestaurantModal({ onClose }: { onClose: () => void }) {
  const dispatch = useAppDispatch()
  const creating = useAppSelector((s) => s.business.creating)
  const [form, setForm] = useState(emptyForm)
  const [formError, setFormError] = useState<string | null>(null)
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const [showLocation, setShowLocation] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const set = (key: keyof typeof emptyForm, value: string) =>
    setForm((f) => ({ ...f, [key]: value }))

  const handleImageChange = (e: ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] || null
    setImageFile(file)
    setImagePreview(file ? URL.createObjectURL(file) : null)
  }

  const clearImage = () => {
    setImageFile(null)
    setImagePreview(null)
    if (fileInputRef.current) fileInputRef.current.value = ''
  }

  const submit = (e: FormEvent) => {
    e.preventDefault()
    setFormError(null)
    if (!form.name || !form.type) {
      setFormError('Restaurant name and type are required')
      return
    }
    if (!form.owner_full_name || !form.owner_password) {
      setFormError('Owner name and password are required')
      return
    }
    if (!form.owner_phone && !form.owner_email) {
      setFormError('Owner email or phone is required')
      return
    }
    const latitude = form.latitude ? Number(form.latitude) : undefined
    const longitude = form.longitude ? Number(form.longitude) : undefined
    if ((latitude !== undefined && Number.isNaN(latitude)) || (longitude !== undefined && Number.isNaN(longitude))) {
      setFormError('Location pin looks invalid, try picking it on the map again')
      return
    }
    dispatch(
      createBusiness({
        name: form.name,
        type: form.type,
        phone: form.phone || undefined,
        email: form.email || undefined,
        address: form.address || undefined,
        city: form.city || undefined,
        latitude,
        longitude,
        owner_full_name: form.owner_full_name,
        owner_phone: form.owner_phone || undefined,
        owner_email: form.owner_email || undefined,
        owner_password: form.owner_password,
        image: imageFile,
      })
    ).then((res) => {
      if (createBusiness.fulfilled.match(res)) {
        setForm(emptyForm)
        clearImage()
        onClose()
      } else {
        setFormError((res.payload as string) || 'Failed to create restaurant')
      }
    })
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card modal-card-wide" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Add restaurant</h2>
          <button className="btn-icon" onClick={onClose}>
            <X size={18} />
          </button>
        </div>
        <form className="modal-form" onSubmit={submit}>
          {formError && <div className="alert alert-error">{formError}</div>}

          <div className="form-row">
            <div className="form-group">
              <label>Restaurant name</label>
              <input className="input" value={form.name} onChange={(e) => set('name', e.target.value)} required />
            </div>
            <div className="form-group">
              <label>Type</label>
              <select className="input select" value={form.type} onChange={(e) => set('type', e.target.value)}>
                <option value="restaurant">Restaurant</option>
                <option value="cafe">Cafe</option>
                <option value="hotel">Hotel</option>
                <option value="guest_house">Guest house</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label>Logo / image</label>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              {imagePreview ? (
                <div style={{ position: 'relative' }}>
                  <img
                    src={imagePreview}
                    alt="Restaurant preview"
                    style={{
                      width: 64,
                      height: 64,
                      objectFit: 'cover',
                      borderRadius: 8,
                      border: '1px solid var(--border, #333)',
                    }}
                  />
                  <button
                    type="button"
                    className="btn-icon"
                    title="Remove image"
                    onClick={clearImage}
                    style={{
                      position: 'absolute',
                      top: -8,
                      right: -8,
                      background: 'var(--danger)',
                      borderRadius: '50%',
                    }}
                  >
                    <X size={12} color="#fff" />
                  </button>
                </div>
              ) : (
                <button
                  type="button"
                  className="btn btn-ghost btn-sm"
                  onClick={() => fileInputRef.current?.click()}
                >
                  <ImagePlus size={16} /> Upload image
                </button>
              )}
              <input
                ref={fileInputRef}
                type="file"
                accept="image/*"
                style={{ display: 'none' }}
                onChange={handleImageChange}
              />
              {imagePreview && (
                <button
                  type="button"
                  className="btn btn-ghost btn-sm"
                  onClick={() => fileInputRef.current?.click()}
                >
                  Change
                </button>
              )}
            </div>
          </div>

          <div className="form-row">
            <div className="form-group">
              <label>Phone</label>
              <input className="input" value={form.phone} onChange={(e) => set('phone', e.target.value)} />
            </div>
            <div className="form-group">
              <label>Email</label>
              <input
                className="input"
                type="email"
                value={form.email}
                onChange={(e) => set('email', e.target.value)}
              />
            </div>
          </div>
          <div className="form-row">
            <div className="form-group">
              <label>Address</label>
              <input className="input" value={form.address} onChange={(e) => set('address', e.target.value)} />
            </div>
            <div className="form-group">
              <label>City</label>
              <input className="input" value={form.city} onChange={(e) => set('city', e.target.value)} />
            </div>
          </div>

          <div className="form-group">
            <button
              type="button"
              className="btn btn-ghost btn-sm"
              onClick={() => setShowLocation((v) => !v)}
              style={{ display: 'flex', alignItems: 'center', gap: 6 }}
            >
              <MapPin size={14} />
              {showLocation ? 'Hide location on map' : 'Show location on map'}
              {showLocation ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
              {!showLocation && form.latitude && form.longitude && (
                <span style={{ color: 'var(--text-muted, #999)', fontWeight: 400 }}>
                  ({Number(form.latitude).toFixed(4)}, {Number(form.longitude).toFixed(4)})
                </span>
              )}
            </button>
            {showLocation && (
              <div style={{ marginTop: 10 }}>
                <LocationMapPicker
                  latitude={form.latitude}
                  longitude={form.longitude}
                  address={form.address}
                  city={form.city}
                  onChange={(lat, lng) => setForm((f) => ({ ...f, latitude: lat, longitude: lng }))}
                />
              </div>
            )}
          </div>

          <div className="form-group" style={{ borderTop: '1px solid var(--border)', paddingTop: 14 }}>
            <label style={{ fontWeight: 600 }}>Owner account</label>
          </div>
          <div className="form-group">
            <label>Owner full name</label>
            <input
              className="input"
              value={form.owner_full_name}
              onChange={(e) => set('owner_full_name', e.target.value)}
              required
            />
          </div>
          <div className="form-row">
            <div className="form-group">
              <label>Owner phone</label>
              <input
                className="input"
                value={form.owner_phone}
                onChange={(e) => set('owner_phone', e.target.value)}
              />
            </div>
            <div className="form-group">
              <label>Owner email</label>
              <input
                className="input"
                type="email"
                value={form.owner_email}
                onChange={(e) => set('owner_email', e.target.value)}
              />
            </div>
          </div>
          <div className="form-group">
            <label>Owner password</label>
            <input
              className="input"
              type="password"
              value={form.owner_password}
              onChange={(e) => set('owner_password', e.target.value)}
              required
            />
          </div>

          <div className="modal-actions">
            <button type="button" className="btn btn-ghost btn-sm" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary btn-sm" disabled={creating}>
              {creating ? 'Creating…' : 'Create restaurant'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
