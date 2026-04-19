'use client';

import { useEffect, useState, useCallback } from 'react';
import { apiClient } from '@/lib/api-client';

// ─── Types ────────────────────────────────────────────────────────────────────
interface Complaint {
  id: number;
  complaint_number: string;
  title: string;
  description: string;
  category: string;
  status: string;
  priority: string;
  address: string;
  ward_id: number;
  ward?: { id: number; name: string };
  user_id: number;
  user?: { id: number; name: string; mobile: string };
  assigned_officer_id?: number;
  assigned_officer?: { id: number; name: string };
  resolution_remarks?: string;
  feedback?: string;
  rating?: number;
  created_at: string;
  updated_at?: string;
  resolved_at?: string;
  media?: { id: number; file_path: string; file_type: string }[];
}

interface Officer { id: number; name: string; mobile: string; ward_id: number; }
interface Ward    { id: number; name: string; }
interface Category{ code: string; name: string; icon?: string; department?: string; }

interface ComplaintListResponse {
  complaints: Complaint[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

// ─── Constants ────────────────────────────────────────────────────────────────
const STATUS_META: Record<string, { label: string; color: string; bg: string; icon: string }> = {
  PENDING:     { label: 'Pending',     color: '#f59e0b', bg: '#fffbeb', icon: '⏳' },
  ASSIGNED:    { label: 'Assigned',    color: '#3b82f6', bg: '#eff6ff', icon: '👤' },
  IN_PROGRESS: { label: 'In Progress', color: '#6366f1', bg: '#eef2ff', icon: '🔧' },
  RESOLVED:    { label: 'Resolved',    color: '#10b981', bg: '#ecfdf5', icon: '✅' },
  REJECTED:    { label: 'Rejected',    color: '#ef4444', bg: '#fef2f2', icon: '❌' },
  CLOSED:      { label: 'Closed',      color: '#6b7280', bg: '#f9fafb', icon: '🔒' },
};

const PRIORITY_META: Record<string, { label: string; color: string }> = {
  LOW:    { label: 'Low',    color: '#10b981' },
  MEDIUM: { label: 'Medium', color: '#f59e0b' },
  HIGH:   { label: 'High',   color: '#ef4444' },
  URGENT: { label: 'Urgent', color: '#dc2626' },
};

const STATUSES = Object.keys(STATUS_META);
const PRIORITIES = Object.keys(PRIORITY_META);

// ─── Helpers ──────────────────────────────────────────────────────────────────
const fmtDate = (d?: string) => {
  if (!d) return '—';
  try { return new Date(d).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }); }
  catch { return '—'; }
};

const fmtShort = (d?: string) => {
  if (!d) return '—';
  try { return new Date(d).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }); }
  catch { return '—'; }
};

// ─── Sub-components ───────────────────────────────────────────────────────────
const inp = "w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400/50 focus:border-indigo-400 bg-white transition-all";
const sel = inp + " cursor-pointer";
const ta  = inp + " resize-none leading-relaxed";

const StatusBadge = ({ status }: { status: string }) => {
  const m = STATUS_META[status] ?? { label: status, color: '#6b7280', bg: '#f3f4f6', icon: '•' };
  return (
    <span className="inline-flex items-center gap-1.5 text-xs font-bold px-2.5 py-1 rounded-full"
      style={{ background: m.bg, color: m.color }}>
      {m.icon} {m.label}
    </span>
  );
};

const PriorityBadge = ({ priority }: { priority: string }) => {
  const m = PRIORITY_META[priority] ?? { label: priority, color: '#6b7280' };
  return (
    <span className="inline-flex items-center text-xs font-bold px-2 py-0.5 rounded-md"
      style={{ background: m.color + '15', color: m.color }}>
      {m.label}
    </span>
  );
};

const Toast = ({ msg, type }: { msg: string; type: 'success' | 'error' }) => (
  <div className="fixed top-5 right-5 z-[100]" style={{ animation: 'slideIn 0.3s cubic-bezier(0.34,1.56,0.64,1) both' }}>
    <div className={`flex items-center gap-3 px-4 py-3 rounded-xl shadow-2xl text-sm font-semibold text-white
      ${type === 'success' ? 'bg-emerald-600' : 'bg-red-600'}`}>
      {type === 'success' ? '✓' : '⚠'} {msg}
    </div>
  </div>
);

// ─── Detail / Action Modal ────────────────────────────────────────────────────
const DetailModal = ({
  complaint, officers, onClose, onUpdate,
}: {
  complaint: Complaint;
  officers: Officer[];
  onClose: () => void;
  onUpdate: (id: number, data: any) => Promise<void>;
}) => {
  const [status, setStatus]       = useState(complaint.status);
  const [priority, setPriority]   = useState(complaint.priority);
  const [officerId, setOfficerId] = useState(String(complaint.assigned_officer_id ?? ''));
  const [remarks, setRemarks]     = useState(complaint.resolution_remarks ?? '');
  const [saving, setSaving]       = useState(false);

  const handleUpdate = async () => {
    setSaving(true);
    try {
      await onUpdate(complaint.id, {
        status,
        priority,
        assigned_officer_id: officerId ? parseInt(officerId) : null,
        resolution_remarks: remarks || null,
      });
      onClose();
    } finally {
      setSaving(false);
    }
  };

  const sm = STATUS_META[complaint.status] ?? STATUS_META.PENDING;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4"
      style={{ background: 'rgba(2,6,23,0.70)', backdropFilter: 'blur(6px)' }}>
      <div className="bg-white w-full sm:rounded-2xl shadow-2xl flex flex-col overflow-hidden" style={{ maxWidth: 700, maxHeight: '94vh' }}>

        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100"
          style={{ background: sm.bg }}>
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="text-xs font-bold px-2.5 py-1 rounded-full bg-white shadow-sm text-gray-600">
                #{complaint.complaint_number}
              </span>
              <StatusBadge status={complaint.status} />
              <PriorityBadge priority={complaint.priority} />
            </div>
            <h2 className="text-base font-bold text-gray-900 line-clamp-1">{complaint.title}</h2>
          </div>
          <button onClick={onClose} className="p-2 rounded-xl hover:bg-white/80 text-gray-500 text-lg ml-3 shrink-0">✕</button>
        </div>

        <div className="overflow-y-auto flex-1 px-6 py-5 space-y-5">

          {/* Info grid */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {[
              { label: 'Submitted By', value: complaint.user?.name ?? `User #${complaint.user_id}` },
              { label: 'Contact', value: complaint.user?.mobile ?? '—' },
              { label: 'Ward', value: complaint.ward?.name ?? `Ward #${complaint.ward_id}` },
              { label: 'Category', value: complaint.category.replace(/_/g, ' ') },
              { label: 'Filed On', value: fmtShort(complaint.created_at) },
              { label: 'Last Updated', value: fmtShort(complaint.updated_at) },
            ].map(({ label, value }) => (
              <div key={label} className="bg-gray-50 rounded-xl px-4 py-3">
                <div className="text-xs text-gray-400 font-semibold uppercase tracking-wide mb-0.5">{label}</div>
                <div className="text-sm font-semibold text-gray-800 truncate">{value}</div>
              </div>
            ))}
          </div>

          {/* Description */}
          <div>
            <div className="text-xs font-bold text-gray-500 uppercase tracking-wide mb-2">📝 Description</div>
            <p className="text-sm text-gray-700 bg-gray-50 rounded-xl px-4 py-3 leading-relaxed">{complaint.description}</p>
          </div>

          {/* Address */}
          <div>
            <div className="text-xs font-bold text-gray-500 uppercase tracking-wide mb-2">📍 Location</div>
            <p className="text-sm text-gray-700 bg-gray-50 rounded-xl px-4 py-3">{complaint.address}</p>
          </div>

          {/* Media */}
          {complaint.media && complaint.media.length > 0 && (
            <div>
              <div className="text-xs font-bold text-gray-500 uppercase tracking-wide mb-2">📎 Attachments</div>
              <div className="flex flex-wrap gap-2">
                {complaint.media.map(m => (
                  <a key={m.id} href={m.file_path} target="_blank" rel="noopener noreferrer"
                    className="px-3 py-2 bg-indigo-50 text-indigo-600 rounded-xl text-xs font-semibold hover:bg-indigo-100 transition">
                    {m.file_type === 'IMAGE' ? '🖼' : '📹'} View {m.file_type}
                  </a>
                ))}
              </div>
            </div>
          )}

          {/* Feedback / Rating */}
          {(complaint.feedback || complaint.rating) && (
            <div className="bg-amber-50 rounded-xl px-4 py-3 border border-amber-100">
              <div className="text-xs font-bold text-amber-700 uppercase tracking-wide mb-1">⭐ Citizen Feedback</div>
              {complaint.rating && (
                <div className="flex gap-1 mb-1">
                  {[1,2,3,4,5].map(s => (
                    <span key={s} className={`text-lg ${s <= complaint.rating! ? 'text-amber-400' : 'text-gray-200'}`}>★</span>
                  ))}
                </div>
              )}
              {complaint.feedback && <p className="text-sm text-amber-800">{complaint.feedback}</p>}
            </div>
          )}

          {/* ─ Admin Actions ─ */}
          <div className="border-t border-gray-100 pt-4 space-y-4">
            <div className="text-xs font-bold text-gray-500 uppercase tracking-wide">🛠 Admin Actions</div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Status</label>
                <select className={sel} value={status} onChange={e => setStatus(e.target.value)}>
                  {STATUSES.map(s => <option key={s} value={s}>{STATUS_META[s].label}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Priority</label>
                <select className={sel} value={priority} onChange={e => setPriority(e.target.value)}>
                  {PRIORITIES.map(p => <option key={p} value={p}>{PRIORITY_META[p].label}</option>)}
                </select>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Assign Officer</label>
              <select className={sel} value={officerId} onChange={e => setOfficerId(e.target.value)}>
                <option value="">— Unassigned —</option>
                {officers.map(o => <option key={o.id} value={o.id}>{o.name} ({o.mobile})</option>)}
              </select>
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">Resolution Remarks</label>
              <textarea className={ta} rows={3} value={remarks} onChange={e => setRemarks(e.target.value)}
                placeholder="Add internal notes or resolution details…" />
            </div>
          </div>
        </div>

        <div className="flex gap-3 px-6 py-4 border-t border-gray-100 bg-gray-50/50">
          <button onClick={onClose} className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-100 transition">Close</button>
          <button onClick={handleUpdate} disabled={saving}
            className="flex-1 py-2.5 rounded-xl text-white text-sm font-semibold transition flex items-center justify-center gap-2 disabled:opacity-60"
            style={{ background: 'linear-gradient(135deg,#6366f1,#4f46e5)', boxShadow: '0 4px 14px rgba(99,102,241,0.4)' }}>
            {saving ? '⏳ Saving…' : '💾 Save Changes'}
          </button>
        </div>
      </div>
    </div>
  );
};

// ════════════════════════════════════════════════════════════════════════════════
// Main Page
// ════════════════════════════════════════════════════════════════════════════════
export default function ComplaintsPage() {
  const [complaints, setComplaints] = useState<Complaint[]>([]);
  const [officers, setOfficers]     = useState<Officer[]>([]);
  const [wards, setWards]           = useState<Ward[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading]       = useState(true);
  const [selected, setSelected]     = useState<Complaint | null>(null);
  const [toast, setToast]           = useState<{ msg: string; type: 'success' | 'error' } | null>(null);

  // Filters
  const [search, setSearch]         = useState('');
  const [statusF, setStatusF]       = useState('all');
  const [priorityF, setPriorityF]   = useState('all');
  const [wardF, setWardF]           = useState('all');
  const [categoryF, setCategoryF]   = useState('all');

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3500);
  };

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      // Fetch complaints from admin endpoint
      const complaintsResponse = await apiClient.get<ComplaintListResponse>('/admin/complaints', {
        params: {
          page: 1,
          page_size: 100
        }
      });
      
      const [off, ward, cat] = await Promise.all([
        apiClient.get<Officer[]>('/admin/field-users'),
        apiClient.get<Ward[]>('/wards'),
        apiClient.get<Category[]>('/complaints/categories'),
      ]);
      
      setComplaints(complaintsResponse.complaints || []);
      if (off) setOfficers(off);
      if (ward) setWards(ward);
      if (cat) setCategories(cat);
    } catch (error) {
      console.error('Failed to load complaints:', error);
      showToast('Failed to load complaints', 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchData(); }, [fetchData]);

  // ── Derived ────────────────────────────────────────────────────────────────
  let filtered = complaints;
  if (statusF   !== 'all') filtered = filtered.filter(c => c.status   === statusF);
  if (priorityF !== 'all') filtered = filtered.filter(c => c.priority  === priorityF);
  if (wardF     !== 'all') filtered = filtered.filter(c => String(c.ward_id) === wardF);
  if (categoryF !== 'all') filtered = filtered.filter(c => c.category === categoryF);
  const q = search.toLowerCase().trim();
  if (q) filtered = filtered.filter(c =>
    c.complaint_number.toLowerCase().includes(q) ||
    c.title.toLowerCase().includes(q) ||
    (c.user?.name ?? '').toLowerCase().includes(q) ||
    c.address.toLowerCase().includes(q)
  );

  // Stat summary - FIXED: Use complaints array directly
  const stats = STATUSES.reduce((acc, s) => {
    acc[s] = complaints.filter(c => c.status === s).length;
    return acc;
  }, {} as Record<string, number>);

  // ── Update handler ─────────────────────────────────────────────────────────
  const handleUpdate = async (id: number, data: any) => {
    try {
      await apiClient.put(`/admin/complaints/${id}`, data);
      showToast('Complaint updated successfully!');
      fetchData();
    } catch (e: any) {
      showToast(e?.response?.data?.detail ?? 'Update failed.', 'error');
      throw e;
    }
  };

  // ── Render ─────────────────────────────────────────────────────────────────
  return (
    <div className="min-h-screen bg-[#f8fafc]" style={{ fontFamily: "'DM Sans','Inter',system-ui,sans-serif" }}>
      {toast && <Toast {...toast} />}

      <div className="w-full max-w-[1600px] mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-6">

        {/* Header */}
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl flex items-center justify-center text-xl"
            style={{ background: 'linear-gradient(135deg,#6366f1,#4f46e5)' }}>📋</div>
          <div>
            <h1 className="text-2xl font-extrabold text-gray-900 tracking-tight">Complaints</h1>
            <p className="text-sm text-gray-500">
              <strong className="text-gray-700">{complaints.length}</strong> total &nbsp;·&nbsp;
              <strong className="text-amber-600">{stats.PENDING ?? 0}</strong> pending &nbsp;·&nbsp;
              <strong className="text-indigo-600">{stats.IN_PROGRESS ?? 0}</strong> in progress
            </p>
          </div>
        </div>

        {/* Status stat cards */}
        <div className="grid grid-cols-3 sm:grid-cols-6 gap-3">
          {STATUSES.map(s => {
            const m = STATUS_META[s];
            const isActive = statusF === s;
            return (
              <button key={s} onClick={() => setStatusF(isActive ? 'all' : s)}
                className="flex flex-col items-center gap-1 py-4 px-2 rounded-2xl border-2 transition-all text-center hover:scale-[1.02]"
                style={{
                  background: isActive ? m.color + '10' : 'white',
                  borderColor: isActive ? m.color : '#e5e7eb',
                  boxShadow: isActive ? `0 4px 20px ${m.color}25` : 'none',
                }}>
                <span className="text-xl">{m.icon}</span>
                <span className="text-[11px] font-bold leading-tight" style={{ color: isActive ? m.color : '#374151' }}>{m.label}</span>
                <span className="text-lg font-extrabold" style={{ color: isActive ? m.color : '#111827' }}>{stats[s] ?? 0}</span>
              </button>
            );
          })}
        </div>

        {/* Filters */}
        <div className="flex flex-col sm:flex-row gap-3 flex-wrap">
          <div className="relative flex-1 min-w-[200px]">
            <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 text-sm">🔍</span>
            <input type="text" value={search} onChange={e => setSearch(e.target.value)}
              placeholder="Search complaint number, title, citizen…"
              className="w-full pl-9 pr-9 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/40 focus:border-indigo-400 transition-all"
            />
            {search && (
              <button onClick={() => setSearch('')} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">✕</button>
            )}
          </div>
          <select className="py-2.5 px-3.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/40 cursor-pointer min-w-[140px]"
            value={priorityF} onChange={e => setPriorityF(e.target.value)}>
            <option value="all">All Priorities</option>
            {PRIORITIES.map(p => <option key={p} value={p}>{PRIORITY_META[p].label}</option>)}
          </select>
          <select className="py-2.5 px-3.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/40 cursor-pointer min-w-[140px]"
            value={wardF} onChange={e => setWardF(e.target.value)}>
            <option value="all">All Wards</option>
            {wards.map(w => <option key={w.id} value={String(w.id)}>{w.name}</option>)}
          </select>
          <select className="py-2.5 px-3.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/40 cursor-pointer min-w-[140px]"
            value={categoryF} onChange={e => setCategoryF(e.target.value)}>
            <option value="all">All Categories</option>
            {categories.map(c => <option key={c.code} value={c.code}>{c.name}</option>)}
          </select>
          <button onClick={fetchData} className="p-2.5 rounded-xl bg-white border border-gray-200 text-gray-500 hover:text-gray-700 transition-all">
            {loading ? '⏳' : '🔄'}
          </button>
        </div>

        {/* Result count */}
        {(search || statusF !== 'all' || priorityF !== 'all' || wardF !== 'all' || categoryF !== 'all') && (
          <p className="text-sm text-gray-500">
            Showing <strong className="text-gray-800">{filtered.length}</strong> of {complaints.length} complaints
          </p>
        )}

        {/* Complaint list */}
        {loading ? (
          <div className="space-y-3">
            {[1,2,3,4,5,6].map(i => (
              <div key={i} className="h-20 rounded-2xl bg-gradient-to-r from-gray-100 to-gray-50 animate-pulse"
                style={{ animationDelay: `${i * 80}ms` }} />
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 text-center bg-white rounded-2xl border border-gray-100">
            <div className="text-5xl mb-4">📋</div>
            <h3 className="text-base font-bold text-gray-700 mb-1">No Complaints Found</h3>
            <p className="text-sm text-gray-400">Try adjusting the filters above</p>
          </div>
        ) : (
          <>
            {/* Desktop table */}
            <div className="hidden lg:block bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 bg-gray-50/60">
                    {['#', 'Complaint', 'Citizen', 'Ward', 'Category', 'Priority', 'Status', 'Officer', 'Filed', ''].map(h => (
                      <th key={h} className="px-4 py-3.5 text-left text-xs font-bold text-gray-500 uppercase tracking-wide">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {filtered.map(c => (
                    <tr key={c.id} className="hover:bg-gray-50/60 transition-colors cursor-pointer"
                      onClick={() => setSelected(c)}>
                      <td className="px-4 py-4">
                        <span className="text-xs font-mono font-bold text-gray-400">{c.complaint_number}</span>
                      </td>
                      <td className="px-4 py-4 max-w-[220px]">
                        <div className="font-semibold text-gray-900 truncate text-sm">{c.title}</div>
                        <div className="text-xs text-gray-400 truncate mt-0.5">{c.address}</div>
                      </td>
                      <td className="px-4 py-4">
                        <div className="font-medium text-gray-800 text-xs">{c.user?.name ?? `#${c.user_id}`}</div>
                        <div className="text-xs text-gray-400">{c.user?.mobile}</div>
                      </td>
                      <td className="px-4 py-4">
                        <span className="text-xs font-semibold px-2 py-1 rounded-lg bg-indigo-50 text-indigo-700">
                          {c.ward?.name ?? `W${c.ward_id}`}
                        </span>
                      </td>
                      <td className="px-4 py-4">
                        <span className="text-xs text-gray-600 bg-gray-100 px-2 py-1 rounded-lg">
                          {c.category.replace(/_/g, ' ')}
                        </span>
                      </td>
                      <td className="px-4 py-4"><PriorityBadge priority={c.priority} /></td>
                      <td className="px-4 py-4"><StatusBadge status={c.status} /></td>
                      <td className="px-4 py-4">
                        {c.assigned_officer
                          ? <span className="text-xs text-gray-700 font-medium">{c.assigned_officer.name}</span>
                          : <span className="text-xs text-gray-400 italic">Unassigned</span>}
                      </td>
                      <td className="px-4 py-4 text-xs text-gray-400 whitespace-nowrap">{fmtShort(c.created_at)}</td>
                      <td className="px-4 py-4" onClick={e => e.stopPropagation()}>
                        <button onClick={() => setSelected(c)}
                          className="px-3 py-1.5 rounded-xl text-xs font-bold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 transition">
                          Manage
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Mobile cards */}
            <div className="lg:hidden space-y-3">
              {filtered.map(c => (
                <div key={c.id} className="bg-white rounded-2xl border border-gray-100 p-4 shadow-sm cursor-pointer"
                  onClick={() => setSelected(c)}>
                  <div className="flex items-start justify-between gap-3 mb-3">
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-xs font-mono text-gray-400">{c.complaint_number}</span>
                        <PriorityBadge priority={c.priority} />
                      </div>
                      <div className="font-bold text-gray-900 text-sm truncate">{c.title}</div>
                      <div className="text-xs text-gray-400 mt-0.5 truncate">{c.address}</div>
                    </div>
                    <StatusBadge status={c.status} />
                  </div>
                  <div className="flex flex-wrap gap-2 text-xs">
                    <span className="px-2 py-1 rounded-lg bg-indigo-50 text-indigo-700 font-semibold">
                      {c.ward?.name ?? `Ward #${c.ward_id}`}
                    </span>
                    <span className="px-2 py-1 rounded-lg bg-gray-100 text-gray-600">
                      {c.category.replace(/_/g, ' ')}
                    </span>
                    <span className="px-2 py-1 rounded-lg bg-gray-50 text-gray-500">
                      📅 {fmtShort(c.created_at)}
                    </span>
                  </div>
                  <div className="mt-3 pt-3 border-t border-gray-50 flex justify-between items-center">
                    <span className="text-xs text-gray-500">
                      {c.assigned_officer ? `👤 ${c.assigned_officer.name}` : '👤 Unassigned'}
                    </span>
                    <button className="px-3 py-1.5 rounded-xl text-xs font-bold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 transition">
                      Manage →
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {/* Detail modal */}
      {selected && (
        <DetailModal
          complaint={selected}
          officers={officers}
          onClose={() => setSelected(null)}
          onUpdate={handleUpdate}
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