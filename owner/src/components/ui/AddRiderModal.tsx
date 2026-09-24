import { useState, FormEvent } from 'react'
import { X } from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../../hooks/redux'
import { createRider, fetchRiders } from '../../features/delivery/deliverySlice'

const emptyForm = {
  full_name: '',
  phone: '',
  email: '',
  password: '',
  vehicle_type: 'bike',
  vehicle_number: '',
}

/** Modal to onboard a new rider account. Shared by the Riders and Delivery pages. */
export default function AddRiderModal({ onClose }: { onClose: () => void }) {
  const dispatch = useAppDispatch()
  const creating = useAppSelector((s) => s.delivery.creatingRider)
  const [form, setForm] = useState(emptyForm)

  const set = (key: keyof typeof emptyForm, value: string) =>
    setForm((f) => ({ ...f, [key]: value }))

  const submit = (e: FormEvent) => {
    e.preventDefault()
    if (!form.full_name || !form.password || (!form.phone && !form.email)) return
    dispatch(
      createRider({
        full_name: form.full_name,
        phone: form.phone || undefined,
        email: form.email || undefined,
        password: form.password,
        vehicle_type: form.vehicle_type,
        vehicle_number: form.vehicle_number || undefined,
      })
    ).then((res) => {
      if (res.meta.requestStatus === 'fulfilled') {
        setForm(emptyForm)
        dispatch(fetchRiders())
        onClose()
      }
    })
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Add rider</h2>
          <button className="btn-icon" onClick={onClose}>
            <X size={18} />
          </button>
        </div>
        <form className="modal-form" onSubmit={submit}>
          <div className="form-group">
            <label>Full name</label>
            <input
              className="input"
              value={form.full_name}
              onChange={(e) => set('full_name', e.target.value)}
              required
            />
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
          <div className="form-group">
            <label>Password</label>
            <input
              className="input"
              type="password"
              value={form.password}
              onChange={(e) => set('password', e.target.value)}
              required
            />
          </div>
          <div className="form-row">
            <div className="form-group">
              <label>Vehicle type</label>
              <select
                className="input select"
                value={form.vehicle_type}
                onChange={(e) => set('vehicle_type', e.target.value)}
              >
                <option value="bike">Bike</option>
                <option value="scooter">Scooter</option>
                <option value="bicycle">Bicycle</option>
                <option value="car">Car</option>
              </select>
            </div>
            <div className="form-group">
              <label>Vehicle number</label>
              <input
                className="input"
                value={form.vehicle_number}
                onChange={(e) => set('vehicle_number', e.target.value)}
              />
            </div>
          </div>
          <div className="modal-actions">
            <button type="button" className="btn btn-ghost btn-sm" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary btn-sm" disabled={creating}>
              {creating ? 'Creating…' : 'Create rider'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
