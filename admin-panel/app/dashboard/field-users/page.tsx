'use client';

import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';

// ─── Types ────────────────────────────────────────────────────────────────────
interface Ward { id: number; name: string; }

interface FieldUser {
  id: number;
  name: string;
  mobile: string;
  email?: string;
  ward_id: number;
  ward?: { id: number; name: string };
  address: string;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
  // field-officer-specific profile fields (if your API returns them nested)
  location?: string;
  area?: string;
  assigned_region?: string;
  contact_info?: string;
  status?: string;
}

interface FormData {
  name: string;
  mobile: string;
  email: string;
  ward_id: string;
  address: string;
  password?: string;
}

const EMPTY_FORM: FormData = {
  name: '', mobile: '', email: '', ward_id: '', address: '', password: '',
};

// ─── Helpers ──────────────────────────────────────────────────────────────────
const toBool = (v: any) => {
  if (typeof v === 'boolean') return v;
  return v === 'Y' || v === 'y' || v === 1 || v === 'true';
};

const fmtDate = (d?: string) => {
  if (!d) return '—';
  try { return new Date(d).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }); }
  catch { return '—'; }
};

// ─── Sub-components ───────────────────────────────────────────────────────────
const Badge = ({ active }: { active: boolean }) => (
  <span className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full ring-1
    ${active ? 'bg-emerald-50 text-emerald-700 ring-emerald-200' : 'bg-gray-100 text-gray-400 ring-gray-200'}`}>
    <span className={`w-1.5 h-1.5 rounded-full ${active ? 'bg-emerald-500' : 'bg-gray-400'}`} />
    {active ? 'Active' : 'Inactive'}
  </span>
);

const Avatar = ({ name }: { name: string }) => {
  const initials = name.split(' ').map(w => w[0]).join('').substring(0, 2).toUpperCase();
  const colors = ['#6366f1','#3b82f6','#10b981','#f59e0b','#ef4444','#8b5cf6','#f97316','#06b6d4'];
  const color = colors[name.charCodeAt(0) % colors.length];
  return (
    <div className="w-10 h-10 rounded-xl flex items-center justify-center text-white text-sm font-bold shrink-0"
      style={{ background: color }}>
      {initials}
    </div>
  );
};

const inp = "w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400/50 focus:border-indigo-400 bg-white transition-all";
const sel = inp + " cursor-pointer";

const FL = ({ label, req, half, children }: { label: string; req?: boolean; half?: boolean; children: React.ReactNode }) => (
  <div className={half ? 'flex-1 min-w-[180px]' : 'w-full'}>
    <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">
      {label}{req && <span className="text-red-400 ml-0.5">*</span>}
    </label>
    {children}
  </div>
);

const Toast = ({ msg, type }: { msg: string; type: 'success' | 'error' }) => (
  <div className="fixed top-5 right-5 z-[100]" style={{ animation: 'slideIn 0.3s cubic-bezier(0.34,1.56,0.64,1) both' }}>
    <div className={`flex items-center gap-3 px-4 py-3 rounded-xl shadow-2xl text-sm font-semibold text-white
      ${type === 'success' ? 'bg-emerald-600' : 'bg-red-600'}`}>
      {type === 'success' ? '✓' : '⚠'} {msg}
    </div>
  </div>
);

// ─── Modal ────────────────────────────────────────────────────────────────────
const Modal = ({
  mode, form, wards, saving, onChange, onClose, onSave,
}: {
  mode: 'add' | 'edit';
  form: FormData;
  wards: Ward[];
  saving: boolean;
  onChange: (k: keyof FormData, v: string) => void;
  onClose: () => void;
  onSave: () => void;
}) => (
  <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4"
    style={{ background: 'rgba(2,6,23,0.65)', backdropFilter: 'blur(6px)' }}>
    <div className="bg-white w-full sm:rounded-2xl shadow-2xl flex flex-col overflow-hidden" style={{ maxWidth: 600, maxHeight: '92vh' }}>
      <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100">
        <h2 className="text-base font-bold text-gray-900">
          {mode === 'add' ? '➕ Add Field Officer' : '✏️ Edit Field Officer'}
        </h2>
        <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400 text-lg">✕</button>
      </div>

      <div className="overflow-y-auto flex-1 px-6 py-5">
        <div className="flex flex-wrap gap-4">
          <FL label="Full Name" req>
            <input className={inp} value={form.name} onChange={e => onChange('name', e.target.value)} placeholder="Ramesh Sharma" />
          </FL>
          <FL label="Mobile Number" req half>
            <input className={inp} type="tel" value={form.mobile} onChange={e => onChange('mobile', e.target.value)} placeholder="9876543210" />
          </FL>
          <FL label="Email" half>
            <input className={inp} type="email" value={form.email} onChange={e => onChange('email', e.target.value)} placeholder="officer@example.com" />
          </FL>
          <FL label="Ward" req half>
            <select className={sel} value={form.ward_id} onChange={e => onChange('ward_id', e.target.value)}>
              <option value="">Select Ward</option>
              {wards.map(w => <option key={w.id} value={w.id}>{w.name}</option>)}
            </select>
          </FL>
          {mode === 'add' && (
            <FL label="Password" req half>
              <input className={inp} type="password" value={form.password ?? ''} onChange={e => onChange('password', e.target.value)} placeholder="Min 8 characters" />
            </FL>
          )}
          <FL label="Address" req>
            <textarea className={inp + ' resize-none'} rows={2} value={form.address} onChange={e => onChange('address', e.target.value)} placeholder="Full residential address" />
          </FL>
        </div>
      </div>

      <div className="flex gap-3 px-6 py-4 border-t border-gray-100 bg-gray-50/50">
        <button onClick={onClose} className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-100 transition">Cancel</button>
        <button onClick={onSave} disabled={saving}
          className="flex-1 py-2.5 rounded-xl text-white text-sm font-semibold transition flex items-center justify-center gap-2 disabled:opacity-60"
          style={{ background: 'linear-gradient(135deg,#6366f1,#4f46e5)', boxShadow: '0 4px 14px rgba(99,102,241,0.4)' }}>
          {saving ? '⏳ Saving…' : mode === 'add' ? 'Create Officer' : 'Save Changes'}
        </button>
      </div>
    </div>
  </div>
);

// ════════════════════════════════════════════════════════════════════════════════
// Main Page
// ════════════════════════════════════════════════════════════════════════════════
export default function FieldUsersPage() {
  const [users, setUsers]       = useState<FieldUser[]>([]);
  const [wards, setWards]       = useState<Ward[]>([]);
  const [loading, setLoading]   = useState(true);
  const [search, setSearch]     = useState('');
  const [filter, setFilter]     = useState<'all' | 'active' | 'inactive'>('all');
  const [modal, setModal]       = useState<{ mode: 'add' | 'edit'; user?: FieldUser } | null>(null);
  const [form, setForm]         = useState<FormData>(EMPTY_FORM);
  const [saving, setSaving]     = useState(false);
  const [toast, setToast]       = useState<{ msg: string; type: 'success' | 'error' } | null>(null);

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3500);
  };

  const fetchUsers = useCallback(async () => {
    setLoading(true);
    try {
      const res = await apiClient.get<FieldUser[]>('/admin/field-users');
      setUsers((res ?? []).map((u: any) => ({ ...u, is_active: toBool(u.is_active) })));
    } catch {
      showToast('Failed to load field officers', 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchUsers();
    apiClient.get<Ward[]>('/wards').then(r => setWards(r ?? [])).catch(() => {});
  }, [fetchUsers]);

  // ── Derived ────────────────────────────────────────────────────────────────
  const afterFilter = filter === 'all' ? users : users.filter(u => u.is_active === (filter === 'active'));
  const q = search.toLowerCase().trim();
  const filtered = q
    ? afterFilter.filter(u =>
        u.name.toLowerCase().includes(q) ||
        u.mobile.includes(q) ||
        (u.email ?? '').toLowerCase().includes(q) ||
        (u.ward?.name ?? '').toLowerCase().includes(q) ||
        u.address.toLowerCase().includes(q)
      )
    : afterFilter;

  const activeCount = users.filter(u => u.is_active).length;

  // ── Handlers ───────────────────────────────────────────────────────────────
  const openAdd = () => { setForm(EMPTY_FORM); setModal({ mode: 'add' }); };

  const openEdit = (user: FieldUser) => {
    setForm({
      name: user.name,
      mobile: user.mobile,
      email: user.email ?? '',
      ward_id: String(user.ward_id ?? user.ward?.id ?? ''),
      address: user.address,
    });
    setModal({ mode: 'edit', user });
  };

  const handleChange = (k: keyof FormData, v: string) => setForm(p => ({ ...p, [k]: v }));

  const handleSave = async () => {
    if (!form.name.trim() || !form.mobile.trim() || !form.ward_id || !form.address.trim()) {
      showToast('Please fill in all required fields', 'error');
      return;
    }
    setSaving(true);
    try {
      const payload: any = {
        name: form.name,
        mobile: form.mobile,
        email: form.email || undefined,
        ward_id: parseInt(form.ward_id),
        address: form.address,
        role: 'FIELD_OFFICER',
      };
      if (modal!.mode === 'add' && form.password) payload.password = form.password;

      if (modal!.mode === 'add') {
        await apiClient.post('/admin/field-users', payload);
        showToast('Field officer created successfully!');
      } else {
        await apiClient.put(`/admin/field-users/${modal!.user!.id}`, payload);
        showToast('Field officer updated successfully!');
      }
      setModal(null);
      fetchUsers();
    } catch (e: any) {
      showToast(e?.response?.data?.detail ?? 'Save failed. Check the fields.', 'error');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (id: number, name: string) => {
    if (!confirm(`Delete "${name}"? This cannot be undone.`)) return;
    try {
      await apiClient.delete(`/admin/field-users/${id}`);
      showToast('Field officer deleted.');
      fetchUsers();
    } catch (e: any) {
      showToast(e?.response?.data?.detail ?? 'Delete failed.', 'error');
    }
  };

  const handleToggle = async (user: FieldUser) => {
    try {
      await apiClient.put(`/admin/field-users/${user.id}`, { is_active: !user.is_active });
      showToast(`${user.is_active ? 'Deactivated' : 'Activated'} successfully.`);
      fetchUsers();
    } catch (e: any) {
      showToast(e?.response?.data?.detail ?? 'Status update failed.', 'error');
    }
  };

  // ── Render ─────────────────────────────────────────────────────────────────
  return (
    <div className="min-h-screen bg-[#f8fafc]" style={{ fontFamily: "'DM Sans','Inter',system-ui,sans-serif" }}>
      {toast && <Toast {...toast} />}

      <div className="w-full max-w-[1400px] mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-6">

        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <div className="flex items-center gap-3 mb-1">
              <div className="w-9 h-9 rounded-xl flex items-center justify-center text-xl"
                style={{ background: 'linear-gradient(135deg,#ef4444,#dc2626)' }}>🗺️</div>
              <h1 className="text-2xl font-extrabold text-gray-900 tracking-tight">Field Officers</h1>
            </div>
            <p className="text-sm text-gray-500 ml-12">
              <strong className="text-gray-700">{users.length}</strong> total &nbsp;·&nbsp;
              <strong className="text-emerald-600">{activeCount}</strong> active
            </p>
          </div>
          <button onClick={openAdd}
            className="inline-flex items-center gap-2 text-white text-sm font-bold px-5 py-2.5 rounded-xl hover:opacity-90 active:scale-95 transition shrink-0"
            style={{ background: 'linear-gradient(135deg,#ef4444,#dc2626)', boxShadow: '0 4px 16px rgba(239,68,68,0.4)' }}>
            ＋ Add Field Officer
          </button>
        </div>

        {/* Toolbar */}
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-sm">🔍</span>
            <input type="text" value={search} onChange={e => setSearch(e.target.value)}
              placeholder="Search by name, mobile, ward, address…"
              className="w-full pl-9 pr-9 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-red-400/40 focus:border-red-400 transition-all"
            />
            {search && (
              <button onClick={() => setSearch('')} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">✕</button>
            )}
          </div>
          <div className="flex gap-2">
            {(['all', 'active', 'inactive'] as const).map(f => (
              <button key={f} onClick={() => setFilter(f)}
                className="px-3.5 py-2.5 rounded-xl text-xs font-bold capitalize border transition-all"
                style={{
                  background: filter === f ? '#ef444415' : 'white',
                  borderColor: filter === f ? '#ef4444' : '#e5e7eb',
                  color: filter === f ? '#ef4444' : '#6b7280',
                }}>
                {f}
              </button>
            ))}
            <button onClick={fetchUsers}
              className="p-2.5 rounded-xl bg-white border border-gray-200 text-gray-500 hover:text-gray-700 transition-all">
              {loading ? '⏳' : '🔄'}
            </button>
          </div>
        </div>

        {/* Stats chips */}
        {(search || filter !== 'all') && (
          <p className="text-sm text-gray-500">
            Showing <strong className="text-gray-800">{filtered.length}</strong> of {users.length} officers
          </p>
        )}

        {/* Table / Cards */}
        {loading ? (
          <div className="space-y-3">
            {[1,2,3,4,5].map(i => (
              <div key={i} className="h-16 rounded-2xl bg-gradient-to-r from-gray-100 to-gray-50 animate-pulse"
                style={{ animationDelay: `${i * 80}ms` }} />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 text-center bg-white rounded-2xl border border-gray-100">
            <div className="text-5xl mb-4">🗺️</div>
            <h3 className="text-base font-bold text-gray-700 mb-1">No Field Officers Found</h3>
            <p className="text-sm text-gray-400 mb-5">Add your first field officer to get started</p>
            <button onClick={openAdd}
              className="inline-flex items-center gap-2 text-white text-sm font-bold px-5 py-2.5 rounded-xl"
              style={{ background: 'linear-gradient(135deg,#ef4444,#dc2626)' }}>
              ＋ Add Officer
            </button>
          </div>
        ) : (
          <>
            {/* Desktop table */}
            <div className="hidden md:block bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 bg-gray-50/60">
                    {['Officer', 'Contact', 'Ward', 'Address', 'Joined', 'Status', 'Actions'].map(h => (
                      <th key={h} className="px-5 py-3.5 text-left text-xs font-bold text-gray-500 uppercase tracking-wide">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {filtered.map(user => (
                    <tr key={user.id} className="hover:bg-gray-50/60 transition-colors">
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <Avatar name={user.name} />
                          <div>
                            <div className="font-semibold text-gray-900">{user.name}</div>
                            <div className="text-xs text-gray-400">ID #{user.id}</div>
                          </div>
                        </div>
                      </td>
                      <td className="px-5 py-4">
                        <div className="font-medium text-gray-800">{user.mobile}</div>
                        {user.email && <div className="text-xs text-gray-400">{user.email}</div>}
                      </td>
                      <td className="px-5 py-4">
                        <span className="text-xs font-semibold px-2.5 py-1 rounded-lg bg-indigo-50 text-indigo-700">
                          {user.ward?.name ?? `Ward #${user.ward_id}`}
                        </span>
                      </td>
                      <td className="px-5 py-4 max-w-[200px]">
                        <span className="text-xs text-gray-500 line-clamp-2">{user.address}</span>
                      </td>
                      <td className="px-5 py-4 text-xs text-gray-400 whitespace-nowrap">{fmtDate(user.created_at)}</td>
                      <td className="px-5 py-4"><Badge active={user.is_active} /></td>
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-1">
                          <button onClick={() => handleToggle(user)} title={user.is_active ? 'Deactivate' : 'Activate'}
                            className={`p-1.5 rounded-lg transition ${user.is_active ? 'text-amber-500 hover:bg-amber-50' : 'text-emerald-500 hover:bg-emerald-50'}`}>
                            ⚡
                          </button>
                          <button onClick={() => openEdit(user)}
                            className="p-1.5 rounded-lg text-indigo-500 hover:bg-indigo-50 transition text-base">✏️</button>
                          <button onClick={() => handleDelete(user.id, user.name)}
                            className="p-1.5 rounded-lg text-red-400 hover:bg-red-50 transition text-base">🗑️</button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Mobile cards */}
            <div className="md:hidden space-y-3">
              {filtered.map(user => (
                <div key={user.id} className="bg-white rounded-2xl border border-gray-100 p-4 shadow-sm">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center gap-3 min-w-0">
                      <Avatar name={user.name} />
                      <div className="min-w-0">
                        <div className="font-bold text-gray-900 truncate">{user.name}</div>
                        <div className="text-xs text-gray-400">{user.mobile}</div>
                      </div>
                    </div>
                    <Badge active={user.is_active} />
                  </div>
                  <div className="mt-3 grid grid-cols-2 gap-2 text-xs text-gray-500">
                    <span>📍 {user.ward?.name ?? `Ward #${user.ward_id}`}</span>
                    <span>📅 {fmtDate(user.created_at)}</span>
                    {user.email && <span className="col-span-2">✉️ {user.email}</span>}
                    <span className="col-span-2 text-gray-400 truncate">🏠 {user.address}</span>
                  </div>
                  <div className="flex gap-2 mt-3 pt-3 border-t border-gray-50">
                    <button onClick={() => handleToggle(user)}
                      className={`flex-1 py-2 rounded-xl text-xs font-bold border transition ${user.is_active ? 'border-amber-200 text-amber-600 bg-amber-50' : 'border-emerald-200 text-emerald-600 bg-emerald-50'}`}>
                      {user.is_active ? 'Deactivate' : 'Activate'}
                    </button>
                    <button onClick={() => openEdit(user)}
                      className="flex-1 py-2 rounded-xl text-xs font-bold border border-indigo-200 text-indigo-600 bg-indigo-50 transition">
                      Edit
                    </button>
                    <button onClick={() => handleDelete(user.id, user.name)}
                      className="flex-1 py-2 rounded-xl text-xs font-bold border border-red-200 text-red-500 bg-red-50 transition">
                      Delete
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {modal && (
        <Modal
          mode={modal.mode}
          form={form}
          wards={wards}
          saving={saving}
          onChange={handleChange}
          onClose={() => setModal(null)}
          onSave={handleSave}
        />
      )}

      <style>{`
        @keyframes slideIn {
          from { transform: translateY(-16px) scale(0.95); opacity: 0; }
          to   { transform: translateY(0) scale(1); opacity: 1; }
        }
      `}</style>
    </div>
  );
}