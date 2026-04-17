'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';

interface Ward {
  id: number;
  name: string;
}

export default function NewUserPage() {
  const router = useRouter();
  const [wards, setWards] = useState<Ward[]>([]);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    mobile: '',       // ← backend expects "mobile" not "phone"
    password: '',
    role: 'CITIZEN',  // ← backend enum: CITIZEN | WARD_ADMIN | SUPER_ADMIN | FIELD_OFFICER
    ward_id: '',
    address: '',
    is_active: true,
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    apiClient.get<Ward[]>('/wards').then(setWards).catch(console.error);
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value,
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await apiClient.post('/admin/users', {
        ...formData,
        ward_id: Number(formData.ward_id),
      });
      router.push('/dashboard/users');
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Failed to create user. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <Link
        href="/dashboard/users"
        className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700 font-medium transition-colors"
      >
        ← Back to Users
      </Link>

      <div className="card space-y-6">
        <div>
          <h1 className="text-xl font-bold text-slate-900">Add New User</h1>
          <p className="text-sm text-slate-500 mt-1">Create a new user account in the system.</p>
        </div>

        {error && (
          <div className="alert-error flex gap-2 items-start">
            <span>⚠</span>
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
            {/* Name */}
            <div className="form-group">
              <label className="label">Full Name <span className="text-red-400">*</span></label>
              <input
                type="text" name="name" value={formData.name} onChange={handleChange}
                className="input-field" placeholder="Ravi Kumar" required
              />
            </div>

            {/* Email */}
            <div className="form-group">
              <label className="label">Email Address</label>
              <input
                type="email" name="email" value={formData.email} onChange={handleChange}
                className="input-field" placeholder="ravi@example.com"
              />
            </div>

            {/* Mobile — field name is "mobile" not "phone" */}
            <div className="form-group">
              <label className="label">Mobile Number <span className="text-red-400">*</span></label>
              <input
                type="tel" name="mobile" value={formData.mobile} onChange={handleChange}
                className="input-field" placeholder="9876543210" required maxLength={15}
              />
            </div>

            {/* Password */}
            <div className="form-group">
              <label className="label">Password <span className="text-red-400">*</span></label>
              <input
                type="password" name="password" value={formData.password} onChange={handleChange}
                className="input-field" placeholder="Min. 6 characters" required minLength={6}
              />
            </div>

            {/* Role — uses actual backend enum values */}
            <div className="form-group">
              <label className="label">Role <span className="text-red-400">*</span></label>
              <select name="role" value={formData.role} onChange={handleChange} className="select-field">
                <option value="CITIZEN">Citizen</option>
                <option value="FIELD_OFFICER">Field Officer</option>
                <option value="WARD_ADMIN">Ward Admin</option>
                <option value="SUPER_ADMIN">Super Admin</option>
              </select>
            </div>

            {/* Ward */}
            <div className="form-group">
              <label className="label">Ward <span className="text-red-400">*</span></label>
              <select name="ward_id" value={formData.ward_id} onChange={handleChange} className="select-field" required>
                <option value="">Select ward…</option>
                {wards.map((w) => (
                  <option key={w.id} value={w.id}>{w.name}</option>
                ))}
              </select>
            </div>
          </div>

          {/* Address — full width */}
          <div className="form-group">
            <label className="label">Address <span className="text-red-400">*</span></label>
            <textarea
              name="address" value={formData.address} onChange={handleChange}
              className="input-field resize-none h-20" placeholder="Full residential address" required minLength={10}
            />
          </div>

          {/* Active toggle */}
          <div className="form-group">
            <label className="label">Account Status</label>
            <label className="flex items-center gap-3 cursor-pointer">
              <div className="relative">
                <input
                  type="checkbox" name="is_active" checked={formData.is_active}
                  onChange={handleChange} className="sr-only peer"
                />
                <div className="w-11 h-6 bg-slate-200 peer-checked:bg-blue-500 rounded-full transition-colors duration-200" />
                <div className="absolute top-0.5 left-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200 peer-checked:translate-x-5" />
              </div>
              <span className="text-sm font-medium text-slate-700">
                {formData.is_active ? 'Active' : 'Inactive'}
              </span>
            </label>
          </div>

          <div className="divider" />

          <div className="flex items-center gap-3">
            <button type="submit" disabled={loading} className="btn-primary flex items-center gap-2">
              {loading ? (
                <>
                  <span className="inline-block w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  Creating…
                </>
              ) : (
                'Create User'
              )}
            </button>
            <Link href="/dashboard/users" className="btn-secondary">Cancel</Link>
          </div>
        </form>
      </div>
    </div>
  );
}