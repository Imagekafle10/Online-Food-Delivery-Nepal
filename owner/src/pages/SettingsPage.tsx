import { useAppSelector } from '../hooks/redux'

export default function SettingsPage() {
  const user = useAppSelector((s) => s.auth.user)
  const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:5000/api'

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Settings</h1>
          <p>Account & API connection</p>
        </div>
      </div>

      <div className="card" style={{ maxWidth: 520, marginBottom: 20 }}>
        <h3 style={{ marginBottom: 16, fontSize: 16 }}>Profile (from /api/auth/me)</h3>
        <div style={{ display: 'grid', gap: 12, fontSize: 14 }}>
          <div>
            <span className="muted">Name</span>
            <div>
              <strong>{user?.full_name}</strong>
            </div>
          </div>
          <div>
            <span className="muted">Email</span>
            <div>{user?.email || '—'}</div>
          </div>
          <div>
            <span className="muted">Phone</span>
            <div>{user?.phone || '—'}</div>
          </div>
          <div>
            <span className="muted">Role</span>
            <div>
              <span className="badge badge-gold">{user?.role}</span>
            </div>
          </div>
          <div>
            <span className="muted">User ID</span>
            <div>{user?.id}</div>
          </div>
        </div>
      </div>

      <div className="card" style={{ maxWidth: 520 }}>
        <h3 style={{ marginBottom: 12, fontSize: 16 }}>API</h3>
        <p className="muted" style={{ fontSize: 13, marginBottom: 8 }}>
          Base URL
        </p>
        <code
          style={{
            display: 'block',
            padding: 12,
            background: 'var(--bg-elevated)',
            borderRadius: 6,
            fontSize: 13,
            color: 'var(--gold)',
          }}
        >
          {apiUrl}
        </code>
        <p className="muted" style={{ fontSize: 12, marginTop: 12 }}>
          Set <code>VITE_API_URL</code> in <code>.env</code>. On the API, set{' '}
          <code>CLIENT_URL=http://localhost:5173</code> (or <code>*</code>) for CORS.
        </p>
      </div>
    </div>
  )
}
