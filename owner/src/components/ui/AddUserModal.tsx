import { useState, FormEvent } from 'react'
import { X } from 'lucide-react'
import { useAppDispatch, useAppSelector } from '../../hooks/redux'
import { createUser, fetchUsers } from '../../features/users/usersSlice'

const emptyForm = {
  full_name: '',
  phone: '',
  email: '',
  password: '',
  role: 'customer',
}

/** super_admin: onboard any account directly from the Users tab. */
export default function AddUserModal({ onClose }: { onClose: () => void }) {
  const dispatch = useAppDispatch()
  const creating = useAppSelector((s) => s.users.creating)
  const [form, setForm] = useState(emptyForm)
  const [formError, setFormError] = useState<string | null>(null)

  const set = (key: keyof typeof emptyForm, value: string) =>
    setForm((f) => ({ ...f, [key]: value }))

  const submit = (e: FormEvent) => {
    e.preventDefault()
    setFormError(null)
    if (!form.full_name || !form.password) {
      setFormError('Full name and password are required')
      return
    }
    if (!form.phone && !form.email) {
      setFormError('Email or phone is required')
      return
    }
    dispatch(
      createUser({
        full_name: form.full_name,
        phone: form.phone || undefined,
        email: form.email || undefined,
        password: form.password,
        role: form.role,
      })
    ).then((res) => {
      if (createUser.fulfilled.match(res)) {
        setForm(emptyForm)
        dispatch(fetchUsers({ limit: 20, offset: 0 }))
        onClose()
      } else {
        setFormError((res.payload as string) || 'Failed to create user')
      }
    })
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-card" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>Add user</h2>
          <button className="btn-icon" onClick={onClose}>
            <X size={18} />
          </button>
        </div>
        <form className="modal-form" onSubmit={submit}>
          {formError && <div className="alert alert-error">{formError}</div>}
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
          <div className="form-row">
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
            <div className="form-group">
              <label>Role</label>
              <select className="input select" value={form.role} onChange={(e) => set('role', e.target.value)}>
                <option value="customer">Customer</option>
                <option value="business_owner">Business owner</option>
                <option value="staff">Staff</option>
                <option value="rider">Rider</option>
                <option value="super_admin">Super admin</option>
              </select>
            </div>
          </div>
          <div className="modal-actions">
            <button type="button" className="btn btn-ghost btn-sm" onClick={onClose}>
              Cancel
            </button>
            <button type="submit" className="btn btn-primary btn-sm" disabled={creating}>
              {creating ? 'Creating…' : 'Create user'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
