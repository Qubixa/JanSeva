'use client';

import { useState, useEffect, useCallback } from 'react';
import { apiClient } from '@/lib/api-client';
import {
  Siren, HeartPulse, Shield, Flame, Phone, Droplets, Users,
  AlertTriangle, Briefcase, FileText, Train, Bell, Search,
  Plus, Pencil, Trash2, Power, X, ChevronDown, ChevronUp,
  MapPin, Mail, Clock, Calendar, DollarSign, Globe,
  CheckCircle2, RefreshCw, ArrowRight, FileCheck, Award,
  Megaphone, Bus, Car, Route, Activity, Filter,
  Stethoscope,
} from 'lucide-react';

// ─── Types ────────────────────────────────────────────────────────────────────
type TabId = 'emergency' | 'schemes' | 'jobs' | 'rti' | 'transport' | 'notices';

interface EmergencyService {
  id: number; name: string; type: string; phone: string;
  alternate_phone?: string; email?: string; address?: string;
  category?: string; is_citywide: boolean | string; is_24x7: boolean | string;
  is_active: boolean | string; google_maps_link?: string;
  latitude?: number; longitude?: number;
}
interface Scheme {
  id: number; name?: string; title?: string; description: string;
  category: string; eligibility?: string; benefits?: string;
  documents?: string; required_documents?: string;
  application_url?: string; official_link?: string;
  deadline?: string; is_active: boolean | string;
}
interface Job {
  id: number; title: string; organization: string; job_type?: string;
  location?: string; description?: string; eligibility?: string;
  salary_range?: string; application_link?: string; last_date?: string;
  is_active: boolean | string;
}
interface RTIInfo {
  id: number; title: string; description?: string; content?: string;
  form_link?: string; portal_link?: string; display_order: number;
  is_active: boolean | string;
}
interface Transport {
  id: number; transport_type: string; name: string; route_number?: string;
  source: string; destination: string; via_stops?: string;
  departure_time?: string; arrival_time?: string;
  frequency?: string; fare?: string; map_link?: string;
  is_active: boolean | string;
}
interface Notice {
  id: number; title: string; message: string; notice_type: string;
  ward_id?: number; target_role?: string; is_active: boolean | string;
  expires_at?: string; created_at: string;
}

type AnyItem = EmergencyService | Scheme | Job | RTIInfo | Transport | Notice;

// ─── Helpers ──────────────────────────────────────────────────────────────────
const toBool = (v: boolean | string | number | undefined | null): boolean => {
  if (typeof v === 'boolean') return v;
  if (v === 'Y' || v === 'y' || v === 1 || v === 'true') return true;
  return false;
};

const normalise = (items: any[], tab: TabId): any[] => {
  if (!Array.isArray(items)) return [];
  return items.map(item => ({
    ...item,
    is_active: toBool(item.is_active),
    ...(tab === 'emergency'
      ? { is_citywide: toBool(item.is_citywide), is_24x7: toBool(item.is_24x7) }
      : {}),
  }));
};

const fmtDate = (d?: string) => {
  if (!d) return '';
  try { return new Date(d).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }); }
  catch { return ''; }
};

// ─── Config ───────────────────────────────────────────────────────────────────
const EMERGENCY_TYPES = ['Hospital', 'Police Station', 'Fire Brigade', 'Ambulance', 'Disaster Management', 'Helpline', 'Blood Bank', 'Women Helpline'];
const SCHEME_CATS = ['HEALTH', 'EDUCATION', 'WOMEN', 'SENIOR_CITIZEN', 'YOUTH', 'FARMER', 'HOUSING', 'EMPLOYMENT', 'OTHER'];
const TRANSPORT_TYPES = ['RAILWAY', 'BUS', 'METRO', 'AUTO'];
const NOTICE_TYPES = ['NOTICE', 'ALERT', 'EVENT', 'CIRCULAR', 'UPDATE'];
const JOB_TYPES = ['Government', 'Private', 'Contract', 'Temporary', 'Part-time'];

const ENDPOINTS: Record<TabId, string> = {
  emergency: '/admin/emergency/services',
  schemes:   '/admin/schemes',
  jobs:      '/admin/jobs',
  rti:       '/admin/rti',
  transport: '/admin/transport',
  notices:   '/admin/notices',
};

const TABS = [
  { id: 'emergency' as TabId, label: 'Emergency Services', short: 'Emergency', icon: Siren,    color: '#ef4444', bg: '#fef2f2', grad: 'linear-gradient(135deg,#ef4444,#dc2626)' },
  { id: 'schemes'   as TabId, label: 'Govt Schemes',       short: 'Schemes',   icon: Award,    color: '#10b981', bg: '#ecfdf5', grad: 'linear-gradient(135deg,#10b981,#059669)' },
  { id: 'jobs'      as TabId, label: 'Job Vacancies',      short: 'Jobs',      icon: Briefcase,color: '#3b82f6', bg: '#eff6ff', grad: 'linear-gradient(135deg,#3b82f6,#2563eb)' },
  { id: 'rti'       as TabId, label: 'RTI Info',           short: 'RTI',       icon: FileCheck,color: '#8b5cf6', bg: '#f5f3ff', grad: 'linear-gradient(135deg,#8b5cf6,#7c3aed)' },
  { id: 'transport' as TabId, label: 'Transport',          short: 'Transport', icon: Train,    color: '#f59e0b', bg: '#fffbeb', grad: 'linear-gradient(135deg,#f59e0b,#d97706)' },
  { id: 'notices'   as TabId, label: 'Notices',            short: 'Notices',   icon: Megaphone,color: '#f97316', bg: '#fff7ed', grad: 'linear-gradient(135deg,#f97316,#ea580c)' },
];

const EMERGENCY_META: Record<string, { icon: any; color: string; bg: string; badge: string; label: string }> = {
  Hospital:           { icon: Stethoscope, color: '#ef4444', bg: '#fef2f2', badge: '#fee2e2', label: 'Medical'   },
  'Police Station':   { icon: Shield,      color: '#3b82f6', bg: '#eff6ff', badge: '#dbeafe', label: 'Police'    },
  'Fire Brigade':     { icon: Flame,       color: '#f97316', bg: '#fff7ed', badge: '#fed7aa', label: 'Fire'      },
  Ambulance:          { icon: HeartPulse,  color: '#10b981', bg: '#ecfdf5', badge: '#d1fae5', label: 'Ambulance' },
  'Blood Bank':       { icon: Droplets,    color: '#e11d48', bg: '#fff1f2', badge: '#ffe4e6', label: 'Blood'     },
  'Women Helpline':   { icon: Users,       color: '#ec4899', bg: '#fdf2f8', badge: '#fce7f3', label: 'Women'     },
  'Disaster Management': { icon: AlertTriangle, color: '#f59e0b', bg: '#fffbeb', badge: '#fde68a', label: 'Disaster' },
  Helpline:           { icon: Phone,       color: '#8b5cf6', bg: '#f5f3ff', badge: '#ede9fe', label: 'Helplines' },
};
const FALLBACK_META = { icon: Phone, color: '#6366f1', bg: '#eef2ff', badge: '#e0e7ff', label: 'Services' };

const getEMeta = (type = '') => {
  for (const [k, v] of Object.entries(EMERGENCY_META)) {
    if (type.toLowerCase().includes(k.toLowerCase())) return v;
  }
  return FALLBACK_META;
};

const TRANSPORT_META: Record<string, { icon: any; color: string; bg: string }> = {
  RAILWAY: { icon: Train, color: '#f59e0b', bg: '#fffbeb' },
  BUS:     { icon: Bus,   color: '#f97316', bg: '#fff7ed' },
  METRO:   { icon: Route, color: '#8b5cf6', bg: '#f5f3ff' },
  AUTO:    { icon: Car,   color: '#eab308', bg: '#fefce8' },
};

const NOTICE_META: Record<string, { icon: any; color: string; bg: string }> = {
  NOTICE:   { icon: Bell,          color: '#3b82f6', bg: '#eff6ff' },
  ALERT:    { icon: AlertTriangle, color: '#ef4444', bg: '#fef2f2' },
  EVENT:    { icon: Calendar,      color: '#10b981', bg: '#ecfdf5' },
  CIRCULAR: { icon: FileText,      color: '#6366f1', bg: '#eef2ff' },
  UPDATE:   { icon: Activity,      color: '#f59e0b', bg: '#fffbeb' },
};

const SCHEME_COLORS: Record<string, string> = {
  HEALTH: '#ef4444', EDUCATION: '#3b82f6', WOMEN: '#ec4899',
  SENIOR_CITIZEN: '#8b5cf6', YOUTH: '#f97316', FARMER: '#10b981',
  HOUSING: '#06b6d4', EMPLOYMENT: '#f59e0b', OTHER: '#6366f1',
};

const DEFAULTS: Record<TabId, Record<string, any>> = {
  emergency: { name: '', type: 'Hospital', phone: '', alternate_phone: '', email: '', address: '', category: '', google_maps_link: '', is_citywide: false, is_24x7: false },
  schemes:   { title: '', description: '', category: 'HEALTH', eligibility: '', benefits: '', required_documents: '', official_link: '', deadline: '' },
  jobs:      { title: '', organization: '', job_type: 'Government', location: '', description: '', eligibility: '', salary_range: '', application_link: '', last_date: '' },
  rti:       { title: '', description: '', content: '', form_link: '', portal_link: '', display_order: 0 },
  transport: { transport_type: 'BUS', name: '', route_number: '', source: '', destination: '', via_stops: '', departure_time: '', arrival_time: '', frequency: '', fare: '', map_link: '' },
  notices:   { title: '', message: '', notice_type: 'NOTICE', target_role: '', expires_at: '' },
};

// ─── UI atoms ─────────────────────────────────────────────────────────────────
const inp  = "w-full border border-gray-200 rounded-xl px-3.5 py-2.5 text-sm text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-indigo-400/50 focus:border-indigo-400 bg-white transition-all";
const sel  = inp + " cursor-pointer";
const ta   = inp + " resize-none leading-relaxed";

const FL = ({ label, req, half, children }: { label: string; req?: boolean; half?: boolean; children: React.ReactNode }) => (
  <div style={{ flex: half ? '1 1 calc(50% - 8px)' : '1 1 100%', minWidth: half ? 180 : 'unset' }}>
    <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1.5">
      {label}{req && <span className="text-red-400 ml-0.5">*</span>}
    </label>
    {children}
  </div>
);

const StatusBadge = ({ active }: { active: boolean }) => (
  <span className={`inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-full ring-1 ${active ? 'bg-emerald-50 text-emerald-700 ring-emerald-200' : 'bg-gray-100 text-gray-400 ring-gray-200'}`}>
    <span className={`w-1.5 h-1.5 rounded-full ${active ? 'bg-emerald-500' : 'bg-gray-400'}`} />
    {active ? 'Active' : 'Inactive'}
  </span>
);

const Chip = ({ children, color }: { children: React.ReactNode; color: string }) => (
  <span className="inline-flex items-center text-xs font-semibold px-2 py-0.5 rounded-md"
    style={{ background: color + '18', color }}>
    {children}
  </span>
);

const IR = ({ icon: Ic, text }: { icon: any; text?: string | null }) =>
  !text ? null : (
    <span className="inline-flex items-center gap-1 text-xs text-gray-500">
      <Ic size={11} className="text-gray-400 shrink-0" />{text}
    </span>
  );

const Chk = ({ checked, onChange, label }: { checked: boolean; onChange: () => void; label: string }) => (
  <label className="flex items-center gap-2.5 cursor-pointer select-none" onClick={onChange}>
    <div className="w-5 h-5 rounded-md border-2 flex items-center justify-center transition-all shrink-0"
      style={{ background: checked ? '#6366f1' : 'white', borderColor: checked ? '#6366f1' : '#d1d5db' }}>
      {checked && <svg className="w-3 h-3 text-white" fill="none" viewBox="0 0 12 12" stroke="currentColor" strokeWidth={2.5}><polyline points="2 6 5 9 10 3" /></svg>}
    </div>
    <span className="text-sm font-medium text-gray-700">{label}</span>
  </label>
);

const CardActions = ({ active, onEdit, onDelete, onToggle }: { active: boolean; onEdit: () => void; onDelete: () => void; onToggle: () => void }) => (
  <div className="flex items-center gap-1 shrink-0">
    <button onClick={onToggle} title={active ? 'Deactivate' : 'Activate'}
      className={`p-1.5 rounded-lg transition ${active ? 'text-amber-500 hover:bg-amber-50' : 'text-emerald-500 hover:bg-emerald-50'}`}>
      <Power size={15} />
    </button>
    <button onClick={onEdit} className="p-1.5 rounded-lg text-indigo-500 hover:bg-indigo-50 transition"><Pencil size={15} /></button>
    <button onClick={onDelete} className="p-1.5 rounded-lg text-red-400 hover:bg-red-50 transition"><Trash2 size={15} /></button>
  </div>
);

const Skeleton = () => (
  <div className="space-y-3">
    {[1, 2, 3, 4].map(i => (
      <div key={i} className="h-20 rounded-2xl bg-gradient-to-r from-gray-100 to-gray-50 animate-pulse"
        style={{ animationDelay: `${i * 100}ms` }} />
    ))}
  </div>
);

const EmptyState = ({ tab, onAdd }: { tab: TabId; onAdd: () => void }) => {
  const t = TABS.find(x => x.id === tab)!;
  const Ic = t.icon;
  return (
    <div className="flex flex-col items-center justify-center py-24 text-center">
      <div className="w-20 h-20 rounded-2xl flex items-center justify-center mb-4" style={{ background: t.bg }}>
        <Ic size={36} style={{ color: t.color }} />
      </div>
      <h3 className="text-base font-bold text-gray-700 mb-1">No {t.label} yet</h3>
      <p className="text-sm text-gray-400 mb-5">Add your first entry to get started</p>
      <button onClick={onAdd}
        className="inline-flex items-center gap-2 text-sm font-semibold px-5 py-2.5 rounded-xl text-white"
        style={{ background: t.grad, boxShadow: `0 4px 14px ${t.color}40` }}>
        <Plus size={16} /> Add {t.short}
      </button>
    </div>
  );
};

// ─── Modal ────────────────────────────────────────────────────────────────────
const Modal = ({ title, onClose, onSave, saving, size = 'md', children }: {
  title: string; onClose: () => void; onSave: () => void;
  saving: boolean; size?: 'md' | 'lg'; children: React.ReactNode;
}) => {
  const w = size === 'lg' ? '780px' : '600px';
  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4"
      style={{ background: 'rgba(2,6,23,0.65)', backdropFilter: 'blur(6px)' }}>
      <div className="bg-white w-full sm:rounded-2xl shadow-2xl flex flex-col overflow-hidden"
        style={{ maxWidth: w, maxHeight: '92vh' }}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 shrink-0">
          <h2 className="text-base font-bold text-gray-900">{title}</h2>
          <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-400"><X size={18} /></button>
        </div>
        <div className="overflow-y-auto flex-1 px-6 py-5">
          <div className="flex flex-wrap gap-4">{children}</div>
        </div>
        <div className="flex gap-3 px-6 py-4 border-t border-gray-100 bg-gray-50/50 shrink-0">
          <button onClick={onClose} className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-600 hover:bg-gray-100 transition">Cancel</button>
          <button onClick={onSave} disabled={saving}
            className="flex-1 py-2.5 rounded-xl text-white text-sm font-semibold transition flex items-center justify-center gap-2 disabled:opacity-60"
            style={{ background: 'linear-gradient(135deg,#6366f1,#4f46e5)', boxShadow: '0 4px 14px rgba(99,102,241,0.4)' }}>
            {saving ? <><RefreshCw size={14} className="animate-spin" /> Saving…</> : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  );
};

// ─── Toast ────────────────────────────────────────────────────────────────────
const Toast = ({ msg, type }: { msg: string; type: 'success' | 'error' }) => (
  <div className="fixed top-5 right-5 z-[100]"
    style={{ animation: 'slideIn 0.3s cubic-bezier(0.34,1.56,0.64,1) both' }}>
    <div className={`flex items-center gap-3 px-4 py-3 rounded-xl shadow-2xl text-sm font-semibold text-white ${type === 'success' ? 'bg-emerald-600' : 'bg-red-600'}`}>
      {type === 'success' ? <CheckCircle2 size={17} /> : <AlertTriangle size={17} />}
      {msg}
    </div>
  </div>
);

// ════════════════════════════════════════════════════════════════════════════════
// Main Page
// ════════════════════════════════════════════════════════════════════════════════
export default function ServicesManagementPage() {
  const [activeTab, setActiveTab] = useState<TabId>('emergency');
  const [data, setData] = useState<Record<TabId, any[]>>({
    emergency: [], schemes: [], jobs: [], rti: [], transport: [], notices: [],
  });
  const [loading, setLoading]   = useState(false);
  const [search, setSearch]     = useState('');
  const [filter, setFilter]     = useState<'all' | 'active' | 'inactive'>('all');
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({});
  const [modal, setModal]       = useState<{ mode: 'add' | 'edit'; item?: any } | null>(null);
  const [form, setForm]         = useState<Record<string, any>>({});
  const [saving, setSaving]     = useState(false);
  const [toast, setToast]       = useState<{ msg: string; type: 'success' | 'error' } | null>(null);

  const showToast = (msg: string, type: 'success' | 'error' = 'success') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  // ── Fetch ────────────────────────────────────────────────────────────────────
  const fetchTab = useCallback(async (tab: TabId) => {
    setLoading(true);
    try {
      const res = await apiClient.get<any[]>(ENDPOINTS[tab]);
      setData(prev => ({ ...prev, [tab]: normalise(res ?? [], tab) }));
    } catch (e: any) {
      showToast(e?.response?.data?.detail ?? 'Failed to load data', 'error');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchTab(activeTab); setSearch(''); setFilter('all'); }, [activeTab, fetchTab]);

  // ── Helpers ──────────────────────────────────────────────────────────────────
  const sf = (key: string) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) =>
    setForm(p => ({ ...p, [key]: e.target.value }));
  const sfn = (key: string) => (e: React.ChangeEvent<HTMLInputElement>) =>
    setForm(p => ({ ...p, [key]: parseInt(e.target.value) || 0 }));
  const sfb = (key: string) => () => setForm(p => ({ ...p, [key]: !p[key] }));

  // ── Derived ──────────────────────────────────────────────────────────────────
  const base = data[activeTab] ?? [];
  const afterFilter = filter === 'all' ? base : base.filter((i: any) => i.is_active === (filter === 'active'));
  const q = search.toLowerCase().trim();
  const filtered = q
    ? afterFilter.filter((item: any) => Object.values(item).filter(v => typeof v === 'string').join(' ').toLowerCase().includes(q))
    : afterFilter;
  const counts = Object.fromEntries(TABS.map(t => [t.id, data[t.id]?.length ?? 0])) as Record<TabId, number>;
  const activeCounts = Object.fromEntries(TABS.map(t => [t.id, data[t.id]?.filter((i: any) => i.is_active).length ?? 0])) as Record<TabId, number>;
  const currentTab = TABS.find(t => t.id === activeTab)!;

  // ── Open modal ───────────────────────────────────────────────────────────────
  const openAdd = () => { setForm({ ...DEFAULTS[activeTab] }); setModal({ mode: 'add' }); };

  const openEdit = (item: any) => {
    const get = (keys: string[], fallback = '') => { for (const k of keys) if (item[k] != null) return item[k]; return fallback; };
    const date = (keys: string[]) => { const v = get(keys); return v ? String(v).substring(0, 10) : ''; };

    const formMap: Record<TabId, Record<string, any>> = {
      emergency: {
        name: get(['name']), type: get(['type'], 'Hospital'), phone: get(['phone']),
        alternate_phone: get(['alternate_phone']), email: get(['email']),
        address: get(['address']), category: get(['category']),
        google_maps_link: get(['google_maps_link']),
        is_citywide: toBool(item.is_citywide), is_24x7: toBool(item.is_24x7),
      },
      schemes: {
        title: get(['title', 'name']), description: get(['description']),
        category: get(['category'], 'HEALTH'), eligibility: get(['eligibility']),
        benefits: get(['benefits']),
        required_documents: get(['required_documents', 'documents']),
        official_link: get(['official_link', 'application_url']),
        deadline: date(['deadline']),
      },
      jobs: {
        title: get(['title']), organization: get(['organization']),
        job_type: get(['job_type'], 'Government'), location: get(['location']),
        description: get(['description']), eligibility: get(['eligibility']),
        salary_range: get(['salary_range']),
        application_link: get(['application_link']),
        last_date: date(['last_date']),
      },
      rti: {
        title: get(['title']), description: get(['description']),
        content: get(['content']), form_link: get(['form_link']),
        portal_link: get(['portal_link']), display_order: item.display_order ?? 0,
      },
      transport: {
        transport_type: get(['transport_type'], 'BUS'), name: get(['name']),
        route_number: get(['route_number']), source: get(['source']),
        destination: get(['destination']), via_stops: get(['via_stops']),
        departure_time: get(['departure_time']), arrival_time: get(['arrival_time']),
        frequency: get(['frequency']), fare: get(['fare']), map_link: get(['map_link']),
      },
      notices: {
        title: get(['title']), message: get(['message']),
        notice_type: get(['notice_type'], 'NOTICE'),
        target_role: get(['target_role']),
        expires_at: date(['expires_at']),
      },
    };
    setForm(formMap[activeTab]);
    setModal({ mode: 'edit', item });
  };

  // ── Save ─────────────────────────────────────────────────────────────────────
  const handleSave = async () => {
  setSaving(true);
  try {
    const url = modal!.mode === 'edit'
      ? `${ENDPOINTS[activeTab]}/${modal!.item.id}`
      : ENDPOINTS[activeTab];

    // Strip empty strings → null for all optional fields before sending
    const payload = Object.fromEntries(
      Object.entries(form).map(([k, v]) => [k, v === '' ? null : v])
    );

    if (modal!.mode === 'edit') await apiClient.put(url, payload);
    else await apiClient.post(url, payload);

    setModal(null);
    fetchTab(activeTab);
    showToast(modal!.mode === 'edit' ? 'Updated successfully!' : 'Created successfully!');
  } catch (e: any) {
    showToast(e?.response?.data?.detail ?? 'Save failed. Check required fields.', 'error');
  } finally {
    setSaving(false);
  }
};

  // ── Delete ───────────────────────────────────────────────────────────────────
  const handleDelete = async (id: number) => {
    if (!confirm('Delete this item?')) return;
    try {
      await apiClient.delete(`${ENDPOINTS[activeTab]}/${id}`);
      fetchTab(activeTab);
      showToast('Deleted successfully.');
    } catch (e: any) {
      showToast(e?.response?.data?.detail ?? 'Delete failed.', 'error');
    }
  };

  // ── Toggle active ────────────────────────────────────────────────────────────
  const handleToggle = async (id: number, current: boolean) => {
    try {
      await apiClient.put(`${ENDPOINTS[activeTab]}/${id}`, { is_active: !current });
      fetchTab(activeTab);
      showToast(`${current ? 'Deactivated' : 'Activated'} successfully.`);
    } catch (e: any) {
      showToast(e?.response?.data?.detail ?? 'Status update failed.', 'error');
    }
  };

  // ════════════════════════════════════════════════════════════════════════════
  // Form renderers
  // ════════════════════════════════════════════════════════════════════════════
  const renderForm = () => {
    switch (activeTab) {
      case 'emergency': return <>
        <FL label="Service Name" req><input className={inp} value={form.name ?? ''} onChange={sf('name')} placeholder="e.g. Sassoon General Hospital" /></FL>
        <FL label="Service Type" req half><select className={sel} value={form.type ?? 'Hospital'} onChange={sf('type')}>{EMERGENCY_TYPES.map(t => <option key={t}>{t}</option>)}</select></FL>
        <FL label="Category" half><input className={inp} value={form.category ?? ''} onChange={sf('category')} placeholder="e.g. Government, Private" /></FL>
        <FL label="Primary Phone" req half><input className={inp} type="tel" value={form.phone ?? ''} onChange={sf('phone')} placeholder="022-XXXX-XXXX" /></FL>
        <FL label="Alternate Phone" half><input className={inp} type="tel" value={form.alternate_phone ?? ''} onChange={sf('alternate_phone')} /></FL>
        <FL label="Email"><input className={inp} type="email" value={form.email ?? ''} onChange={sf('email')} /></FL>
        <FL label="Address"><textarea className={ta} rows={2} value={form.address ?? ''} onChange={sf('address')} placeholder="Full address with landmark" /></FL>
        <FL label="Google Maps Link"><input className={inp} type="url" value={form.google_maps_link ?? ''} onChange={sf('google_maps_link')} placeholder="https://maps.google.com/..." /></FL>
        <div className="w-full flex flex-wrap gap-6 pt-2 border-t border-gray-50">
          <Chk checked={!!form.is_citywide} onChange={sfb('is_citywide')} label="Citywide Service" />
          <Chk checked={!!form.is_24x7}    onChange={sfb('is_24x7')}    label="24×7 Available"  />
        </div>
      </>;

      case 'schemes': return <>
        <FL label="Scheme Title" req><input className={inp} value={form.title ?? ''} onChange={sf('title')} placeholder="e.g. PM Awas Yojana" /></FL>
        <FL label="Category" req half><select className={sel} value={form.category ?? 'HEALTH'} onChange={sf('category')}>{SCHEME_CATS.map(c => <option key={c}>{c}</option>)}</select></FL>
        <FL label="Deadline" half><input className={inp} type="date" value={form.deadline ?? ''} onChange={sf('deadline')} /></FL>
        <FL label="Description" req><textarea className={ta} rows={3} value={form.description ?? ''} onChange={sf('description')} placeholder="What is this scheme about?" /></FL>
        <FL label="Eligibility Criteria"><textarea className={ta} rows={2} value={form.eligibility ?? ''} onChange={sf('eligibility')} placeholder="Who can apply?" /></FL>
        <FL label="Benefits Provided"><textarea className={ta} rows={2} value={form.benefits ?? ''} onChange={sf('benefits')} placeholder="What does this scheme offer?" /></FL>
        <FL label="Required Documents"><textarea className={ta} rows={2} value={form.required_documents ?? ''} onChange={sf('required_documents')} placeholder="Aadhaar, PAN, Income Certificate..." /></FL>
        <FL label="Official / Apply Link"><input className={inp} type="url" value={form.official_link ?? ''} onChange={sf('official_link')} placeholder="https://..." /></FL>
      </>;

      case 'jobs': return <>
        <FL label="Job Title" req><input className={inp} value={form.title ?? ''} onChange={sf('title')} placeholder="e.g. Junior Engineer" /></FL>
        <FL label="Organization" req half><input className={inp} value={form.organization ?? ''} onChange={sf('organization')} placeholder="e.g. PMC, NHB" /></FL>
        <FL label="Job Type" half><select className={sel} value={form.job_type ?? 'Government'} onChange={sf('job_type')}>{JOB_TYPES.map(t => <option key={t}>{t}</option>)}</select></FL>
        <FL label="Location" half><input className={inp} value={form.location ?? ''} onChange={sf('location')} placeholder="Pune, Maharashtra" /></FL>
        <FL label="Salary Range" half><input className={inp} value={form.salary_range ?? ''} onChange={sf('salary_range')} placeholder="₹25,000 – ₹40,000 /month" /></FL>
        <FL label="Description"><textarea className={ta} rows={2} value={form.description ?? ''} onChange={sf('description')} /></FL>
        <FL label="Eligibility Criteria"><textarea className={ta} rows={2} value={form.eligibility ?? ''} onChange={sf('eligibility')} /></FL>
        <FL label="Application Link" half><input className={inp} type="url" value={form.application_link ?? ''} onChange={sf('application_link')} placeholder="https://..." /></FL>
        <FL label="Last Date to Apply" half><input className={inp} type="date" value={form.last_date ?? ''} onChange={sf('last_date')} /></FL>
      </>;

      case 'rti': return <>
        <FL label="Title" req><input className={inp} value={form.title ?? ''} onChange={sf('title')} placeholder="e.g. How to File an RTI Application" /></FL>
        <FL label="Short Description"><textarea className={ta} rows={2} value={form.description ?? ''} onChange={sf('description')} /></FL>
        <FL label="Detailed Content / Steps"><textarea className={ta} rows={5} value={form.content ?? ''} onChange={sf('content')} placeholder="Step-by-step instructions, full content..." /></FL>
        <FL label="RTI Form Link" half><input className={inp} type="url" value={form.form_link ?? ''} onChange={sf('form_link')} placeholder="https://..." /></FL>
        <FL label="Government Portal Link" half><input className={inp} type="url" value={form.portal_link ?? ''} onChange={sf('portal_link')} placeholder="https://rtionline.gov.in" /></FL>
        <FL label="Display Order" half><input className={inp} type="number" min={0} value={form.display_order ?? 0} onChange={sfn('display_order')} /></FL>
      </>;

      case 'transport': return <>
        <FL label="Transport Type" req half><select className={sel} value={form.transport_type ?? 'BUS'} onChange={sf('transport_type')}>{TRANSPORT_TYPES.map(t => <option key={t}>{t}</option>)}</select></FL>
        <FL label="Route Number" half><input className={inp} value={form.route_number ?? ''} onChange={sf('route_number')} placeholder="e.g. 155, 12A" /></FL>
        <FL label="Route / Service Name" req><input className={inp} value={form.name ?? ''} onChange={sf('name')} placeholder="e.g. Shivajinagar – Hadapsar Express" /></FL>
        <FL label="From (Source)" req half><input className={inp} value={form.source ?? ''} onChange={sf('source')} placeholder="Shivajinagar" /></FL>
        <FL label="To (Destination)" req half><input className={inp} value={form.destination ?? ''} onChange={sf('destination')} placeholder="Hadapsar" /></FL>
        <FL label="Via Stops"><input className={inp} value={form.via_stops ?? ''} onChange={sf('via_stops')} placeholder="Deccan, FC Road, Pune Station..." /></FL>
        <FL label="Departure Time" half><input className={inp} type="time" value={form.departure_time ?? ''} onChange={sf('departure_time')} /></FL>
        <FL label="Arrival Time" half><input className={inp} type="time" value={form.arrival_time ?? ''} onChange={sf('arrival_time')} /></FL>
        <FL label="Frequency" half><input className={inp} value={form.frequency ?? ''} onChange={sf('frequency')} placeholder="Every 15 mins" /></FL>
        <FL label="Fare" half><input className={inp} value={form.fare ?? ''} onChange={sf('fare')} placeholder="₹20 – ₹60" /></FL>
        <FL label="Map / Route Link"><input className={inp} type="url" value={form.map_link ?? ''} onChange={sf('map_link')} placeholder="https://..." /></FL>
      </>;

      case 'notices': return <>
        <FL label="Notice Title" req><input className={inp} value={form.title ?? ''} onChange={sf('title')} placeholder="e.g. Water Supply Disruption – Ward 12" /></FL>
        <FL label="Notice Type" req half>
          <select className={sel} value={form.notice_type ?? 'NOTICE'} onChange={sf('notice_type')}>
            {NOTICE_TYPES.map(t => <option key={t}>{t}</option>)}
          </select>
        </FL>
        <FL label="Target Role" half>
          <select className={sel} value={form.target_role ?? ''} onChange={sf('target_role')}>
            <option value="">All Users</option>
            <option value="CITIZEN">Citizens</option>
            <option value="FIELD_OFFICER">Field Officers</option>
            <option value="WARD_ADMIN">Ward Admins</option>
          </select>
        </FL>
<FL label="Message" req>
  <textarea
    className={ta}
    rows={10}
    value={form.message ?? ''}
    onChange={sf('message')}
    placeholder="Full notice content..."
    style={{ whiteSpace: 'pre-wrap', fontFamily: 'monospace', fontSize: '13px', lineHeight: '1.6' }}
  />
</FL>        
<FL label="Expires On"><input className={inp} type="date" value={form.expires_at ?? ''} onChange={sf('expires_at')} /></FL>
      </>;

      default: return null;
    }
  };

  // ════════════════════════════════════════════════════════════════════════════
  // Content renderers
  // ════════════════════════════════════════════════════════════════════════════
  const renderEmergency = () => {
    if (!filtered.length) return <EmptyState tab={activeTab} onAdd={openAdd} />;
    const groups: Record<string, { items: EmergencyService[]; meta: typeof FALLBACK_META }> = {};
    for (const s of filtered as EmergencyService[]) {
      const meta = getEMeta(s.type);
      if (!groups[meta.label]) groups[meta.label] = { items: [], meta };
      groups[meta.label].items.push(s);
    }
    return (
      <div className="space-y-4">
        {Object.entries(groups).map(([grp, { items, meta }]) => {
          const GIc = meta.icon;
          const open = collapsed[grp] !== true;
          return (
            <div key={grp} className="rounded-2xl overflow-hidden border" style={{ borderColor: meta.color + '28' }}>
              <button onClick={() => setCollapsed(p => ({ ...p, [grp]: open }))}
                className="w-full flex items-center justify-between px-5 py-3.5 transition-colors"
                style={{ background: meta.bg }}>
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-xl flex items-center justify-center" style={{ background: meta.color + '20' }}>
                    <GIc size={17} style={{ color: meta.color }} />
                  </div>
                  <span className="font-bold text-gray-800 text-sm">{grp}</span>
                  <span className="text-xs font-bold px-2 py-0.5 rounded-full" style={{ background: meta.badge, color: meta.color }}>{items.length}</span>
                  <span className="text-xs text-gray-400">{items.filter(i => i.is_active).length} active</span>
                </div>
                {open ? <ChevronUp size={16} className="text-gray-400" /> : <ChevronDown size={16} className="text-gray-400" />}
              </button>
              {open && (
                <div className="divide-y divide-gray-50 bg-white">
                  {items.map(s => {
                    const m = getEMeta(s.type);
                    const SIc = m.icon;
                    return (
                      <div key={s.id} className="px-5 py-4 flex items-start gap-4 hover:bg-gray-50/60 transition-colors">
                        <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ background: m.bg }}>
                          <SIc size={19} style={{ color: m.color }} />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="flex flex-wrap items-center gap-2 mb-1.5">
                            <span className="font-semibold text-gray-900 text-sm">{s.name}</span>
                            <Chip color={m.color}>{s.type}</Chip>
                            {s.is_citywide && <Chip color="#6366f1">Citywide</Chip>}
                            {s.is_24x7    && <Chip color="#10b981">24×7</Chip>}
                            <StatusBadge active={!!s.is_active} />
                          </div>
                          <div className="flex flex-wrap gap-x-5 gap-y-1">
                            <IR icon={Phone} text={s.phone} />
                            {s.alternate_phone && <IR icon={Phone} text={`Alt: ${s.alternate_phone}`} />}
                            {s.email   && <IR icon={Mail}   text={s.email} />}
                            {s.address && <IR icon={MapPin} text={s.address} />}
                            {s.google_maps_link && (
                              <a href={s.google_maps_link} target="_blank" rel="noopener noreferrer"
                                className="inline-flex items-center gap-1 text-xs text-indigo-500 hover:underline">
                                <Globe size={11} /> Maps
                              </a>
                            )}
                          </div>
                        </div>
                        <CardActions active={!!s.is_active} onEdit={() => openEdit(s)} onDelete={() => handleDelete(s.id)} onToggle={() => handleToggle(s.id, !!s.is_active)} />
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          );
        })}
      </div>
    );
  };

  const renderSchemes = () => {
    if (!filtered.length) return <EmptyState tab={activeTab} onAdd={openAdd} />;
    return (
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-3">
        {(filtered as Scheme[]).map(s => {
          const cat = s.category || 'OTHER';
          const color = SCHEME_COLORS[cat] || '#6366f1';
          return (
            <div key={s.id} className="bg-white rounded-2xl border border-gray-100 p-5 hover:shadow-md transition-shadow">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ background: color + '15' }}>
                  <Award size={20} style={{ color }} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex flex-wrap items-center gap-2 mb-1">
                    <span className="font-bold text-gray-900 text-sm">{s.title || s.name}</span>
                    <Chip color={color}>{cat.replace(/_/g, ' ')}</Chip>
                    <StatusBadge active={!!s.is_active} />
                  </div>
                  <p className="text-xs text-gray-500 line-clamp-2 mb-2">{s.description}</p>
                  <div className="flex flex-wrap gap-2">
                    {s.benefits && <span className="text-xs text-emerald-600 bg-emerald-50 px-2 py-1 rounded-lg line-clamp-1">✦ {String(s.benefits).substring(0, 80)}</span>}
                    {s.deadline && <IR icon={Calendar} text={`Due ${fmtDate(s.deadline)}`} />}
                    {(s.official_link || s.application_url) && (
                      <a href={(s.official_link || s.application_url)!} target="_blank" rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-xs text-indigo-500 hover:underline">
                        <Globe size={11} /> Apply
                      </a>
                    )}
                  </div>
                </div>
                <CardActions active={!!s.is_active} onEdit={() => openEdit(s)} onDelete={() => handleDelete(s.id)} onToggle={() => handleToggle(s.id, !!s.is_active)} />
              </div>
            </div>
          );
        })}
      </div>
    );
  };

  const renderJobs = () => {
    if (!filtered.length) return <EmptyState tab={activeTab} onAdd={openAdd} />;
    const tc: Record<string, string> = { Government: '#3b82f6', Private: '#8b5cf6', Contract: '#f59e0b', Temporary: '#f97316', 'Part-time': '#10b981' };
    return (
      <div className="space-y-3">
        {(filtered as Job[]).map(j => {
          const color = tc[j.job_type ?? ''] ?? '#6366f1';
          return (
            <div key={j.id} className="bg-white rounded-2xl border border-gray-100 p-5 hover:shadow-sm transition-shadow">
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ background: color + '15' }}>
                  <Briefcase size={19} style={{ color }} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex flex-wrap items-center gap-2 mb-2">
                    <span className="font-bold text-gray-900 text-sm">{j.title}</span>
                    <Chip color="#374151">{j.organization}</Chip>
                    {j.job_type && <Chip color={color}>{j.job_type}</Chip>}
                    <StatusBadge active={!!j.is_active} />
                  </div>
                  <div className="flex flex-wrap gap-x-5 gap-y-1">
                    <IR icon={MapPin} text={j.location} />
                    <IR icon={DollarSign} text={j.salary_range} />
                    <IR icon={Calendar} text={j.last_date ? `Apply by ${fmtDate(j.last_date)}` : ''} />
                    {j.application_link && (
                      <a href={j.application_link} target="_blank" rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-xs text-indigo-500 hover:underline">
                        <Globe size={11} /> Apply
                      </a>
                    )}
                  </div>
                  {j.description && <p className="text-xs text-gray-400 mt-1.5 line-clamp-1">{j.description}</p>}
                </div>
                <CardActions active={!!j.is_active} onEdit={() => openEdit(j)} onDelete={() => handleDelete(j.id)} onToggle={() => handleToggle(j.id, !!j.is_active)} />
              </div>
            </div>
          );
        })}
      </div>
    );
  };

  const renderRTI = () => {
    if (!filtered.length) return <EmptyState tab={activeTab} onAdd={openAdd} />;
    return (
      <div className="space-y-3">
        {[...(filtered as RTIInfo[])].sort((a, b) => (a.display_order ?? 0) - (b.display_order ?? 0)).map(r => (
          <div key={r.id} className="bg-white rounded-2xl border border-gray-100 p-5 hover:shadow-sm transition-shadow">
            <div className="flex items-start gap-4">
              <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0 bg-violet-50">
                <FileCheck size={19} className="text-violet-600" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex flex-wrap items-center gap-2 mb-1.5">
                  <span className="font-bold text-gray-900 text-sm">{r.title}</span>
                  <Chip color="#7c3aed">#{r.display_order}</Chip>
                  <StatusBadge active={!!r.is_active} />
                </div>
                {r.description && <p className="text-sm text-gray-500 mb-2">{r.description}</p>}
                {r.content && <p className="text-xs text-gray-400 line-clamp-2">{r.content}</p>}
                <div className="flex flex-wrap gap-2 mt-2">
                  {r.form_link && (
                    <a href={r.form_link} target="_blank" rel="noopener noreferrer"
                      className="inline-flex items-center gap-1.5 text-xs font-semibold text-violet-600 bg-violet-50 px-3 py-1.5 rounded-lg hover:bg-violet-100 transition">
                      <FileText size={12} /> Download Form
                    </a>
                  )}
                  {r.portal_link && (
                    <a href={r.portal_link} target="_blank" rel="noopener noreferrer"
                      className="inline-flex items-center gap-1.5 text-xs font-semibold text-indigo-600 bg-indigo-50 px-3 py-1.5 rounded-lg hover:bg-indigo-100 transition">
                      <Globe size={12} /> RTI Portal
                    </a>
                  )}
                </div>
              </div>
              <CardActions active={!!r.is_active} onEdit={() => openEdit(r)} onDelete={() => handleDelete(r.id)} onToggle={() => handleToggle(r.id, !!r.is_active)} />
            </div>
          </div>
        ))}
      </div>
    );
  };

  const renderTransport = () => {
    if (!filtered.length) return <EmptyState tab={activeTab} onAdd={openAdd} />;
    return (
      <div className="space-y-3">
        {(filtered as Transport[]).map(t => {
          const m = TRANSPORT_META[t.transport_type] ?? TRANSPORT_META.BUS;
          const TIc = m.icon;
          return (
            <div key={t.id} className="bg-white rounded-2xl border border-gray-100 p-5 hover:shadow-sm transition-shadow">
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ background: m.bg }}>
                  <TIc size={19} style={{ color: m.color }} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex flex-wrap items-center gap-2 mb-2">
                    <span className="font-bold text-gray-900 text-sm">{t.name}</span>
                    <Chip color={m.color}>{t.transport_type}</Chip>
                    {t.route_number && <Chip color="#374151">Route {t.route_number}</Chip>}
                    <StatusBadge active={!!t.is_active} />
                  </div>
                  <div className="flex flex-wrap gap-x-5 gap-y-1.5">
                    <span className="inline-flex items-center gap-1.5 text-xs font-medium text-gray-600 bg-gray-50 px-2.5 py-1 rounded-lg">
                      <MapPin size={11} className="text-gray-400" />
                      {t.source} <ArrowRight size={10} className="text-gray-400 mx-0.5" /> {t.destination}
                    </span>
                    <IR icon={Clock} text={t.frequency ?? ''} />
                    <IR icon={DollarSign} text={t.fare ? `Fare: ${t.fare}` : ''} />
                    {t.departure_time && t.arrival_time && <IR icon={Clock} text={`${t.departure_time} – ${t.arrival_time}`} />}
                    {t.map_link && (
                      <a href={t.map_link} target="_blank" rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-xs text-indigo-500 hover:underline">
                        <Globe size={11} /> Route Map
                      </a>
                    )}
                  </div>
                  {t.via_stops && <p className="text-xs text-gray-400 mt-1">Via: {t.via_stops}</p>}
                </div>
                <CardActions active={!!t.is_active} onEdit={() => openEdit(t)} onDelete={() => handleDelete(t.id)} onToggle={() => handleToggle(t.id, !!t.is_active)} />
              </div>
            </div>
          );
        })}
      </div>
    );
  };

  const renderNotices = () => {
    if (!filtered.length) return <EmptyState tab={activeTab} onAdd={openAdd} />;
    return (
      <div className="space-y-3">
        {(filtered as Notice[]).map(n => {
          const m = NOTICE_META[n.notice_type] ?? NOTICE_META.NOTICE;
          const NIc = m.icon;
          const expired = n.expires_at ? new Date(n.expires_at) < new Date() : false;
          return (
            <div key={n.id} className="bg-white rounded-2xl border border-gray-100 p-5 hover:shadow-sm transition-shadow">
              <div className="flex items-start gap-4">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center shrink-0" style={{ background: m.bg }}>
                  <NIc size={19} style={{ color: m.color }} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex flex-wrap items-center gap-2 mb-1.5">
                    <span className="font-bold text-gray-900 text-sm">{n.title}</span>
                    <Chip color={m.color}>{n.notice_type}</Chip>
                    {n.target_role && <Chip color="#6366f1">→ {n.target_role}</Chip>}
                    <StatusBadge active={!!n.is_active} />
                    {expired && <span className="text-xs font-semibold text-red-500 bg-red-50 px-2 py-0.5 rounded-full ring-1 ring-red-200">Expired</span>}
                  </div>
                  <p
  className="text-sm text-gray-600 mb-2"
  style={{
    whiteSpace: 'pre-wrap',
    wordBreak: 'break-word',
    display: '-webkit-box',
    WebkitLineClamp: 5,
    WebkitBoxOrient: 'vertical',
    overflow: 'hidden',
  }}
>
  {n.message}
</p>
                  <div className="flex flex-wrap gap-4">
                    <IR icon={Calendar} text={`Posted ${fmtDate(n.created_at)}`} />
                    {n.expires_at && <IR icon={Clock} text={`Expires ${fmtDate(n.expires_at)}`} />}
                  </div>
                </div>
                <CardActions active={!!n.is_active} onEdit={() => openEdit(n)} onDelete={() => handleDelete(n.id)} onToggle={() => handleToggle(n.id, !!n.is_active)} />
              </div>
            </div>
          );
        })}
      </div>
    );
  };

  const renderContent = () => {
    if (loading) return <Skeleton />;
    switch (activeTab) {
      case 'emergency': return renderEmergency();
      case 'schemes':   return renderSchemes();
      case 'jobs':      return renderJobs();
      case 'rti':       return renderRTI();
      case 'transport': return renderTransport();
      case 'notices':   return renderNotices();
    }
  };

  const TabIc = currentTab.icon;

  // ════════════════════════════════════════════════════════════════════════════
  // RENDER
  // ════════════════════════════════════════════════════════════════════════════
  return (
    <div className="min-h-screen bg-[#f8fafc]" style={{ fontFamily: "'DM Sans','Inter',system-ui,sans-serif" }}>

      {toast && <Toast {...toast} />}

      <div className="w-full max-w-[1600px] mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-6">

        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <div className="flex items-center gap-3 mb-1">
              <div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: currentTab.grad }}>
                <TabIc size={18} className="text-white" />
              </div>
              <h1 className="text-2xl font-extrabold text-gray-900 tracking-tight">Services Management</h1>
            </div>
            <p className="text-sm text-gray-500 ml-12">
              {currentTab.label} &nbsp;·&nbsp;
              <strong className="text-gray-700">{counts[activeTab]}</strong> total &nbsp;·&nbsp;
              <strong style={{ color: currentTab.color }}>{activeCounts[activeTab]}</strong> active
            </p>
          </div>
          <button onClick={openAdd}
            className="inline-flex items-center gap-2 text-white text-sm font-bold px-5 py-2.5 rounded-xl transition-all hover:opacity-90 active:scale-95 shrink-0"
            style={{ background: currentTab.grad, boxShadow: `0 4px 16px ${currentTab.color}40` }}>
            <Plus size={18} /> Add {currentTab.short}
          </button>
        </div>

        {/* Stats cards */}
        <div className="grid grid-cols-3 sm:grid-cols-6 gap-3">
          {TABS.map(tab => {
            const TIc = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button key={tab.id} onClick={() => setActiveTab(tab.id)}
                className="relative flex flex-col items-center gap-1 py-4 px-2 rounded-2xl border-2 transition-all duration-200 text-center hover:scale-[1.02]"
                style={{
                  background: isActive ? tab.color + '10' : 'white',
                  borderColor: isActive ? tab.color : '#e5e7eb',
                  boxShadow: isActive ? `0 4px 20px ${tab.color}25` : 'none',
                }}>
                <TIc size={22} style={{ color: tab.color }} />
                <span className="text-[11px] font-bold leading-tight" style={{ color: isActive ? tab.color : '#374151' }}>{tab.short}</span>
                <span className="text-lg font-extrabold" style={{ color: isActive ? tab.color : '#111827' }}>{counts[tab.id]}</span>
                {isActive && <span className="absolute -top-1 -right-1 w-3 h-3 rounded-full border-2 border-white" style={{ background: tab.color }} />}
              </button>
            );
          })}
        </div>

        {/* Toolbar */}
        <div className="flex flex-col sm:flex-row gap-3">
          <div className="relative flex-1">
            <Search size={15} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400" />
            <input type="text" value={search} onChange={e => setSearch(e.target.value)}
              placeholder={`Search ${currentTab.label.toLowerCase()}…`}
              className="w-full pl-10 pr-10 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400/50 focus:border-indigo-400 transition-all"
            />
            {search && (
              <button onClick={() => setSearch('')} className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                <X size={15} />
              </button>
            )}
          </div>
          <div className="flex gap-2">
            {(['all', 'active', 'inactive'] as const).map(f => (
              <button key={f} onClick={() => setFilter(f)}
                className="px-3.5 py-2.5 rounded-xl text-xs font-bold capitalize border transition-all"
                style={{
                  background: filter === f ? currentTab.color + '12' : 'white',
                  borderColor: filter === f ? currentTab.color : '#e5e7eb',
                  color: filter === f ? currentTab.color : '#6b7280',
                }}>
                {f}
              </button>
            ))}
            <button onClick={() => fetchTab(activeTab)}
              className="p-2.5 rounded-xl bg-white border border-gray-200 text-gray-500 hover:text-gray-700 hover:border-gray-300 transition-all">
              <RefreshCw size={15} className={loading ? 'animate-spin' : ''} />
            </button>
          </div>
        </div>

        {/* Result count */}
        {(search || filter !== 'all') && (
          <div className="flex items-center gap-2 text-sm text-gray-500">
            <Filter size={14} />
            Showing <strong className="text-gray-800 mx-1">{filtered.length}</strong> of {base.length} results
            {search && <Chip color="#6366f1">"{search}"</Chip>}
            {filter !== 'all' && <Chip color={currentTab.color}>{filter}</Chip>}
          </div>
        )}

        {/* Content */}
        <div className="min-h-[400px]">{renderContent()}</div>
      </div>

      {/* Modal */}
      {modal && (
        <Modal
          title={`${modal.mode === 'add' ? 'Add New' : 'Edit'} ${currentTab.label}`}
          onClose={() => setModal(null)}
          onSave={handleSave}
          saving={saving}
          size={['transport', 'schemes'].includes(activeTab) ? 'lg' : 'md'}
        >
          {renderForm()}
        </Modal>
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