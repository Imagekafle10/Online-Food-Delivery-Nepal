import { useState, FormEvent, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAppDispatch, useAppSelector } from "../hooks/redux";
import { login, clearError } from "../features/auth/authSlice";
import { fetchBusinesses } from "../features/business/businessSlice";
import "./login.css";

export default function LoginPage() {
  const [identifier, setIdentifier] = useState("owner@foodie.test");
  const [password, setPassword] = useState("password123");
  const dispatch = useAppDispatch();
  const navigate = useNavigate();
  const { loading, error, isAuthenticated } = useAppSelector((s) => s.auth);

  useEffect(() => {
    if (isAuthenticated) navigate("/", { replace: true });
  }, [isAuthenticated, navigate]);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    dispatch(clearError());
    const result = await dispatch(login({ identifier, password }));
    if (login.fulfilled.match(result)) {
      await dispatch(fetchBusinesses());
      navigate("/");
    }
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-brand">
          <img className="logo-icon" src="/logo.png" alt="Bhansa" />
          <h1>Bhansa</h1>
          <p>Admin Panel</p>
        </div>

        <form onSubmit={handleSubmit} className="login-form">
          <div className="form-group">
            <label>Email or Phone</label>
            <input
              className="input"
              type="text"
              value={identifier}
              onChange={(e) => setIdentifier(e.target.value)}
              placeholder="username"
              // autoComplete="username"
            />
          </div>
          <div className="form-group">
            <label>Password</label>
            <input
              className="input"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              // autoComplete="current-password"
            />
          </div>
          {error && <p className="login-error">{error}</p>}
          <button
            type="submit"
            className="btn btn-primary login-btn"
            disabled={loading}
          >
            {loading ? "Signing in…" : "Sign In"}
          </button>
        </form>
      </div>
    </div>
  );
}
