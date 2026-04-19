'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { apiClient } from '@/lib/api-client';
import { useAuthStore, Admin } from '@/lib/auth-store';

interface LoginResponse {
  user: Admin;
  access_token: string;
}

export default function LoginPage() {
  const router = useRouter();
  const { setAdmin, setToken } = useAuthStore();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const response = await apiClient.post<LoginResponse>('/auth/admin-login', {
        email,
        password,
      });
      setAdmin(response.user);
      setToken(response.access_token);
      router.push('/dashboard');
    } catch (err: any) {
      const detail = err.response?.data?.detail;
      if (Array.isArray(detail)) {
        setError(detail.map((e: any) => e.msg).join(', '));
      } else if (typeof detail === 'string') {
        setError(detail);
      } else {
        setError('Invalid credentials. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex bg-slate-50">
      {/* Left panel – decorative */}
      <div className="hidden lg:flex flex-col justify-between w-[480px] shrink-0 bg-slate-900 p-12">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-blue-500 flex items-center justify-center text-xl font-black text-white shadow-lg shadow-blue-500/40">
            J
          </div>
          <div>
            <p className="text-white font-bold">JanSeva</p>
            <p className="text-slate-400 text-xs tracking-widest font-medium">ADMIN PORTAL</p>
          </div>
        </div>

        <div>
          <div className="grid grid-cols-2 gap-3 mb-10">
            {[
              { label: 'Active Users',    value: '12,400+', icon: '👥' },
              { label: 'Complaints',      value: '3,200+',  icon: '📋' },
              { label: 'Wards Managed',   value: '48',      icon: '🏛️' },
              { label: 'Pending Matches', value: '140',     icon: '💍' },
            ].map((s) => (
              <div key={s.label} className="bg-white/5 border border-white/10 rounded-xl p-4">
                <p className="text-xl mb-1">{s.icon}</p>
                <p className="text-2xl font-extrabold text-white">{s.value}</p>
                <p className="text-xs text-slate-400 mt-0.5">{s.label}</p>
              </div>
            ))}
          </div>

          <blockquote className="border-l-2 border-blue-500 pl-4">
            <p className="text-slate-300 text-sm leading-relaxed">
              "Empowering communities through transparent and efficient civic services."
            </p>
            <p className="text-slate-500 text-xs mt-2">— JanSeva Mission</p>
          </blockquote>
        </div>

        <p className="text-slate-600 text-xs">
          © {new Date().getFullYear()} JanSeva. All rights reserved.
        </p>
      </div>

      {/* Right panel – form */}
      <div className="flex-1 flex items-center justify-center px-6 py-12">
        <div className="w-full max-w-[400px]">
          {/* Mobile brand */}
          <div className="flex items-center gap-3 mb-10 lg:hidden">
            <div className="w-10 h-10 rounded-xl bg-blue-600 flex items-center justify-center text-xl font-black text-white">
              J
            </div>
            <div>
              <p className="font-bold text-slate-900">JanSeva</p>
              <p className="text-xs text-slate-400 tracking-wider">ADMIN PORTAL</p>
            </div>
          </div>

          <div className="mb-8">
            <h1 className="text-2xl font-extrabold text-slate-900">Welcome back</h1>
            <p className="text-slate-500 text-sm mt-1.5">
              Sign in to your admin account to continue.
            </p>
          </div>

          {error && (
            <div className="alert-error mb-6">
              <span>⚠</span>
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-5">
            <div className="form-group">
              <label className="label">Email address</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="input-field"
                placeholder="admin@janseva.gov.in"
                required
                autoComplete="email"
              />
            </div>

            <div className="form-group">
              <label className="label">Password</label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="input-field pr-12"
                  placeholder="••••••••"
                  required
                  autoComplete="current-password"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 text-sm px-1"
                  tabIndex={-1}
                >
                  {showPassword ? '🙈' : '👁'}
                </button>
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="btn-primary w-full mt-2 py-3 text-base"
            >
              {loading ? (
                <>
                  <span className="inline-block w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  Signing in…
                </>
              ) : (
                'Sign in'
              )}
            </button>
          </form>

          <p className="text-center text-xs text-slate-400 mt-8">
            Restricted access · Authorised personnel only
          </p>
        </div>
      </div>
    </div>
  );
}