'use client';

import { useState, useEffect, useCallback } from 'react';
import { apiClient } from '@/lib/api-client';

// ─── Types ────────────────────────────────────────────────────────────────────
type ServiceType = 'emergency' | 'schemes' | 'jobs' | 'rti' | 'transport' | 'notices';

interface EmergencyService {
  id: number; name: string; type: string; phone: string;
  alternate_phone?: string; email?: string; address?: string;
  category?: string; is_citywide: boolean; is_24x7: boolean; is_active: boolean;
  latitude?: number; longitude?: number; google_maps_link?: string;
}
interface Scheme {
  id: number; name?: string; title?: string; description: string; category: string;
  eligibility?: string; benefits?: string; required_documents?: string; documents?: string;
  application_url?: string; official_link?: string; deadline?: string; is_active: boolean;
}
interface Job {
  id: number; title: string; organization: string; job_type?: string;
  location?: string; description?: string; eligibility?: string;
  salary_range?: string; application_link?: string; last_date?: string; is_active: boolean;
}
interface RTIInfo {
  id: number; title: string; description?: string; content?: string;
  form_link?: string; portal_link?: string; display_order: number; is_active: boolean;
}
interface Transport {
  id: number; transport_type: string; name: string; route_number?: string;
  source: string; destination: string; via_stops?: string;
  departure_time?: string; arrival_time?: string;
  frequency?: string; fare?: string; map_link?: string; is_active: boolean;
}
interface Notice {
  id: number; title: string; message: string; notice_type: string;
  ward_id?: number; target_role?: string; is_active: boolean;
  expires_at?: string; created_at: string;
}

// ─── Icons (inline SVG, no external deps) ─────────────────────────────────────
const Icon = {
  ambulance: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5"><rect x="1" y="10" width="22" height="12" rx="2"/><path d="M8 22V10"/><path d="M16 22V10"/><path d="M1 14h22"/><path d="M8 6l4-4 4 4"/><path d="M12 2v8"/></svg>,
  hospital: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M9 12h6M12 9v6"/></svg>,
  shield: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5"><path d="M12 2L3 7v5c0 5.25 3.75 10.15 9 11.25C18.25 22.15 22 17.25 22 12V7L12 2z"/></svg>,
  fire: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5"><path d="M8.5 14.5A2.5 2.5 0 0011 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 11-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 002.5 2.5z"/></svg>,
  phone: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07A19.5 19.5 0 013.07 9.81a19.79 19.79 0 01-3.07-8.63A2 2 0 012 1h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L6.91 8.09a16 16 0 006 6l.36-.36a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z"/></svg>,
  mail: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M2 7l10 7 10-7"/></svg>,
  pin: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>,
  calendar: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/></svg>,
  edit: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>,
  trash: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>,
  plus: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5"><circle cx="12" cy="12" r="10"/><path d="M12 8v8M8 12h8"/></svg>,
  close: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5"><path d="M18 6L6 18M6 6l12 12"/></svg>,
  chevron: (open: boolean) => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className={`w-4 h-4 transition-transform ${open ? 'rotate-180' : ''}`}><polyline points="6 9 12 15 18 9"/></svg>,
  search: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>,
  check: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.5} className="w-3.5 h-3.5"><polyline points="20 6 9 17 4 12"/></svg>,
  link: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><path d="M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 00-7.54-.54l-3 3a5 5 0 007.07 7.07l1.71-1.71"/></svg>,
  clock: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>,
  train: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5"><rect x="4" y="3" width="16" height="16" rx="2"/><path d="M4 11h16"/><path d="M12 3v8"/><circle cx="8.5" cy="17" r="1.5"/><circle cx="15.5" cy="17" r="1.5"/><path d="M8.5 19l-1.5 3M15.5 19l1.5 3"/></svg>,
  star: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>,
  briefcase: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 7V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v2"/><line x1="12" y1="12" x2="12" y2="12"/></svg>,
  file: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>,
  bell: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-5 h-5"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>,
  currency: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><line x1="12" y1="1" x2="12" y2="23"/><path d="M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6"/></svg>,
  info: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>,
  powerOff: () => <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2} className="w-4 h-4"><path d="M18.36 6.64a9 9 0 11-12.73 0"/><line x1="12" y1="2" x2="12" y2="12"/></svg>,
};

// ─── Helpers ──────────────────────────────────────────────────────────────────
const EMERGENCY_TYPES = ['Hospital', 'Police Station', 'Fire Brigade', 'Ambulance', 'Disaster Management', 'Helpline', 'Blood Bank', 'Women Helpline'];
const SCHEME_CATEGORIES = ['HEALTH', 'EDUCATION', 'WOMEN', 'SENIOR_CITIZEN', 'YOUTH', 'FARMER', 'HOUSING', 'EMPLOYMENT', 'OTHER'];
const TRANSPORT_TYPES = ['RAILWAY', 'BUS', 'METRO', 'AUTO'];
const NOTICE_TYPES = ['NOTICE', 'ALERT', 'EVENT', 'CIRCULAR', 'UPDATE'];
const JOB_TYPES = ['Government', 'Private', 'Contract', 'Temporary', 'Part-time'];

const emergencyIcon = (type: string) => {
  if (type.includes('Hospital') || type.includes('Medical') || type.includes('Clinic')) return { emoji: '🏥', bg: 'bg-red-50', border: 'border-red-100', badge: 'bg-red-100 text-red-700', dot: 'bg-red-500' };
  if (type.includes('Police')) return { emoji: '👮', bg: 'bg-blue-50', border: 'border-blue-100', badge: 'bg-blue-100 text-blue-700', dot: 'bg-blue-500' };
  if (type.includes('Fire')) return { emoji: '🔥', bg: 'bg-orange-50', border: 'border-orange-100', badge: 'bg-orange-100 text-orange-700', dot: 'bg-orange-500' };
  if (type.includes('Ambulance')) return { emoji: '🚑', bg: 'bg-emerald-50', border: 'border-emerald-100', badge: 'bg-emerald-100 text-emerald-700', dot: 'bg-emerald-500' };
  if (type.includes('Blood')) return { emoji: '🩸', bg: 'bg-rose-50', border: 'border-rose-100', badge: 'bg-rose-100 text-rose-700', dot: 'bg-rose-500' };
  if (type.includes('Women')) return { emoji: '👩', bg: 'bg-pink-50', border: 'border-pink-100', badge: 'bg-pink-100 text-pink-700', dot: 'bg-pink-500' };
  if (type.includes('Disaster')) return { emoji: '⚡', bg: 'bg-amber-50', border: 'border-amber-100', badge: 'bg-amber-100 text-amber-700', dot: 'bg-amber-500' };
  return { emoji: '📞', bg: 'bg-violet-50', border: 'border-violet-100', badge: 'bg-violet-100 text-violet-700', dot: 'bg-violet-500' };
};

const categoryGroup = (services: EmergencyService[]) =>
  services.reduce<Record<string, EmergencyService[]>>((acc, s) => {
    const g = s.type.includes('Hospital') || s.type.includes('Clinic') ? 'Medical' :
      s.type.includes('Police') ? 'Police' :
      s.type.includes('Fire') ? 'Fire' :
      s.type.includes('Ambulance') ? 'Ambulance' :
      s.type.includes('Blood') ? 'Blood Bank' :
      s.type.includes('Women') ? 'Women' :
      s.type.includes('Disaster') ? 'Disaster' : 'Helplines';
    if (!acc[g]) acc[g] = [];
    acc[g].push(s);
    return acc;
  }, {});

const fmtDate = (d?: string) => d ? new Date(d).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '—';

// ─── Sub-components ───────────────────────────────────────────────────────────
const StatusPill = ({ active }: { active: boolean }) => (
  <span className={`inline-flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full ${active ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-100 text-gray-500'}`}>
    <span className={`w-1.5 h-1.5 rounded-full ${active ? 'bg-emerald-500' : 'bg-gray-400'}`} />
    {active ? 'Active' : 'Inactive'}
  </span>
);

const Chip = ({ label, color = 'gray' }: { label: string; color?: string }) => {
  const colors: Record<string, string> = {
    gray: 'bg-gray-100 text-gray-600',
    blue: 'bg-blue-100 text-blue-700',
    purple: 'bg-purple-100 text-purple-700',
    amber: 'bg-amber-100 text-amber-700',
    green: 'bg-emerald-100 text-emerald-700',
    red: 'bg-red-100 text-red-700',
  };
  return <span className={`text-xs font-medium px-2 py-0.5 rounded-md ${colors[color] || colors.gray}`}>{label}</span>;
};

const FieldRow = ({ icon, text }: { icon: React.ReactNode; text: string }) => (
  <div className="flex items-center gap-1.5 text-sm text-gray-600">
    <span className="text-gray-400">{icon}</span>
    <span>{text}</span>
  </div>
);

// ─── Form Field Components ────────────────────────────────────────────────────
const FormField = ({ label, required, children }: { label: string; required?: boolean; children: React.ReactNode }) => (
  <div>
    <label className="block text-sm font-semibold text-gray-700 mb-1.5">
      {label} {required && <span className="text-red-500">*</span>}
    </label>
    {children}
  </div>
);

const inputCls = "w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent bg-white transition";
const selectCls = inputCls;
const textareaCls = `${inputCls} resize-none`;

// ─── Modal ────────────────────────────────────────────────────────────────────
const Modal = ({ title, onClose, children, size = 'md' }: {
  title: string; onClose: () => void; children: React.ReactNode; size?: 'sm' | 'md' | 'lg';
}) => {
  const widths = { sm: 'max-w-sm', md: 'max-w-lg', lg: 'max-w-2xl' };
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4" style={{ background: 'rgba(15,23,42,0.55)', backdropFilter: 'blur(4px)' }}>
      <div className={`bg-white rounded-2xl shadow-2xl w-full ${widths[size]} max-h-[90vh] flex flex-col`}>
        <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 shrink-0">
          <h2 className="text-lg font-bold text-gray-900">{title}</h2>
          <button onClick={onClose} className="p-1.5 rounded-lg hover:bg-gray-100 text-gray-500 transition">
            <Icon.close />
          </button>
        </div>
        <div className="overflow-y-auto flex-1 px-6 py-5 space-y-4">{children}</div>
      </div>
    </div>
  );
};

// ─── Service Card ─────────────────────────────────────────────────────────────
const CardActions = ({ onEdit, onDelete, onToggle, active }: {
  onEdit: () => void; onDelete: () => void; onToggle: () => void; active: boolean;
}) => (
  <div className="flex items-center gap-1 shrink-0">
    <button onClick={onToggle} title={active ? 'Disable' : 'Enable'}
      className={`p-1.5 rounded-lg transition text-xs font-medium flex items-center gap-1 ${active ? 'text-amber-600 hover:bg-amber-50' : 'text-emerald-600 hover:bg-emerald-50'}`}>
      <Icon.powerOff />
    </button>
    <button onClick={onEdit} className="p-1.5 rounded-lg hover:bg-indigo-50 text-indigo-600 transition" title="Edit">
      <Icon.edit />
    </button>
    <button onClick={onDelete} className="p-1.5 rounded-lg hover:bg-red-50 text-red-500 transition" title="Delete">
      <Icon.trash />
    </button>
  </div>
);

// ─── Main Page ────────────────────────────────────────────────────────────────
export default function ServicesManagementPage() {
  const [activeTab, setActiveTab] = useState<ServiceType>('emergency');
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [showModal, setShowModal] = useState(false);
  const [modalMode, setModalMode] = useState<'add' | 'edit'>('add');
  const [selectedItem, setSelectedItem] = useState<any>(null);
  const [collapsedGroups, setCollapsedGroups] = useState<Record<string, boolean>>({});
  const [saving, setSaving] = useState(false);

  const [emergencyServices, setEmergencyServices] = useState<EmergencyService[]>([]);
  const [schemes, setSchemes] = useState<Scheme[]>([]);
  const [jobs, setJobs] = useState<Job[]>([]);
  const [rtiList, setRtiList] = useState<RTIInfo[]>([]);
  const [transportList, setTransportList] = useState<Transport[]>([]);
  const [notices, setNotices] = useState<Notice[]>([]);

  // ─── Form defaults ─────────────────────────────────────────────────────────
  const defaultEmergency = { name: '', type: 'Hospital', phone: '', alternate_phone: '', email: '', address: '', category: '', google_maps_link: '', is_citywide: false, is_24x7: false };
  const defaultScheme = { title: '', description: '', category: 'HEALTH', eligibility: '', benefits: '', required_documents: '', official_link: '', deadline: '' };
  const defaultJob = { title: '', organization: '', job_type: 'Government', location: '', description: '', eligibility: '', salary_range: '', application_link: '', last_date: '' };
  const defaultRTI = { title: '', description: '', content: '', form_link: '', portal_link: '', display_order: 0 };
  const defaultTransport = { transport_type: 'BUS', name: '', route_number: '', source: '', destination: '', via_stops: '', departure_time: '', arrival_time: '', frequency: '', fare: '', map_link: '' };
  const defaultNotice = { title: '', message: '', notice_type: 'NOTICE', target_role: '', expires_at: '' };

  const [emergencyForm, setEmergencyForm] = useState({ ...defaultEmergency });
  const [schemeForm, setSchemeForm] = useState({ ...defaultScheme });
  const [jobForm, setJobForm] = useState({ ...defaultJob });
  const [rtiForm, setRTIForm] = useState({ ...defaultRTI });
  const [transportForm, setTransportForm] = useState({ ...defaultTransport });
  const [noticeForm, setNoticeForm] = useState({ ...defaultNotice });

  const setF = (tab: ServiceType) => ({
    emergency: setEmergencyForm, schemes: setSchemeForm, jobs: setJobForm,
    rti: setRTIForm, transport: setTransportForm, notices: setNoticeForm,
  }[tab]);

  useEffect(() => { fetchData(); }, [activeTab]);
  useEffect(() => { setSearch(''); }, [activeTab]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const endpoints: Record<ServiceType, string> = {
        emergency: '/admin/emergency/services', schemes: '/admin/schemes',
        jobs: '/admin/jobs', rti: '/admin/rti',
        transport: '/admin/transport', notices: '/admin/notices',
      };
      const res = await apiClient.get<any[]>(endpoints[activeTab]);
      const setters: Record<ServiceType, (v: any) => void> = {
        emergency: setEmergencyServices, schemes: setSchemes, jobs: setJobs,
        rti: setRtiList, transport: setTransportList, notices: setNotices,
      };
      setters[activeTab](res || []);
    } catch (e) { console.error(e); } finally { setLoading(false); }
  };

  const openAdd = () => {
    setModalMode('add'); setSelectedItem(null);
    setEmergencyForm({ ...defaultEmergency });
    setSchemeForm({ ...defaultScheme });
    setJobForm({ ...defaultJob });
    setRTIForm({ ...defaultRTI });
    setTransportForm({ ...defaultTransport });
    setNoticeForm({ ...defaultNotice });
    setShowModal(true);
  };

  const openEdit = (item: any) => {
    setModalMode('edit'); setSelectedItem(item);
    if (activeTab === 'emergency') setEmergencyForm({ name: item.name, type: item.type, phone: item.phone, alternate_phone: item.alternate_phone || '', email: item.email || '', address: item.address || '', category: item.category || '', google_maps_link: item.google_maps_link || '', is_citywide: item.is_citywide, is_24x7: item.is_24x7 });
    else if (activeTab === 'schemes') setSchemeForm({ title: item.title || item.name || '', description: item.description, category: item.category, eligibility: item.eligibility || '', benefits: item.benefits || '', required_documents: item.required_documents || item.documents || '', official_link: item.official_link || item.application_url || '', deadline: item.deadline ? item.deadline.substring(0, 10) : '' });
    else if (activeTab === 'jobs') setJobForm({ title: item.title, organization: item.organization, job_type: item.job_type || 'Government', location: item.location || '', description: item.description || '', eligibility: item.eligibility || '', salary_range: item.salary_range || '', application_link: item.application_link || '', last_date: item.last_date ? item.last_date.substring(0, 10) : '' });
    else if (activeTab === 'rti') setRTIForm({ title: item.title, description: item.description || '', content: item.content || '', form_link: item.form_link || '', portal_link: item.portal_link || '', display_order: item.display_order });
    else if (activeTab === 'transport') setTransportForm({ transport_type: item.transport_type, name: item.name, route_number: item.route_number || '', source: item.source, destination: item.destination, via_stops: item.via_stops || '', departure_time: item.departure_time || '', arrival_time: item.arrival_time || '', frequency: item.frequency || '', fare: item.fare || '', map_link: item.map_link || '' });
    else if (activeTab === 'notices') setNoticeForm({ title: item.title, message: item.message, notice_type: item.notice_type, target_role: item.target_role || '', expires_at: item.expires_at ? item.expires_at.substring(0, 10) : '' });
    setShowModal(true);
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Delete this item? This action cannot be undone.')) return;
    const endpoints: Record<ServiceType, string> = {
      emergency: `/admin/emergency/services/${id}`, schemes: `/admin/schemes/${id}`,
      jobs: `/admin/jobs/${id}`, rti: `/admin/rti/${id}`,
      transport: `/admin/transport/${id}`, notices: `/admin/notices/${id}`,
    };
    try {
      await apiClient.delete(endpoints[activeTab]);
      fetchData();
    } catch { alert('Failed to delete'); }
  };

  const handleToggle = async (id: number, current: boolean) => {
    const endpoints: Record<ServiceType, string> = {
      emergency: `/admin/emergency/services/${id}`, schemes: `/admin/schemes/${id}`,
      jobs: `/admin/jobs/${id}`, rti: `/admin/rti/${id}`,
      transport: `/admin/transport/${id}`, notices: `/admin/notices/${id}`,
    };
    try {
      await apiClient.put(endpoints[activeTab], { is_active: !current });
      fetchData();
    } catch { alert('Failed to update status'); }
  };

  const handleSubmit = async () => {
    setSaving(true);
    const isEdit = modalMode === 'edit';
    const baseUrl: Record<ServiceType, string> = {
      emergency: '/admin/emergency/services', schemes: '/admin/schemes',
      jobs: '/admin/jobs', rti: '/admin/rti',
      transport: '/admin/transport', notices: '/admin/notices',
    };
    const payloads: Record<ServiceType, any> = {
      emergency: emergencyForm,
      schemes: schemeForm,
      jobs: jobForm,
      rti: rtiForm,
      transport: transportForm,
      notices: noticeForm,
    };
    try {
      const url = isEdit ? `${baseUrl[activeTab]}/${selectedItem.id}` : baseUrl[activeTab];
      if (isEdit) await apiClient.put(url, payloads[activeTab]);
      else await apiClient.post(url, payloads[activeTab]);
      setShowModal(false);
      fetchData();
    } catch { alert('Failed to save'); } finally { setSaving(false); }
  };

  // ─── Filtered data ─────────────────────────────────────────────────────────
  const q = search.toLowerCase();
  const filtered = {
    emergency: emergencyServices.filter(s => !q || s.name.toLowerCase().includes(q) || s.type.toLowerCase().includes(q) || (s.phone && s.phone.includes(q))),
    schemes: schemes.filter(s => !q || (s.name || s.title || '').toLowerCase().includes(q) || s.category.toLowerCase().includes(q)),
    jobs: jobs.filter(j => !q || j.title.toLowerCase().includes(q) || j.organization.toLowerCase().includes(q)),
    rti: rtiList.filter(r => !q || r.title.toLowerCase().includes(q)),
    transport: transportList.filter(t => !q || t.name.toLowerCase().includes(q) || t.source.toLowerCase().includes(q) || t.destination.toLowerCase().includes(q)),
    notices: notices.filter(n => !q || n.title.toLowerCase().includes(q) || n.message.toLowerCase().includes(q)),
  };

  const counts: Record<ServiceType, number> = {
    emergency: emergencyServices.length, schemes: schemes.length, jobs: jobs.length,
    rti: rtiList.length, transport: transportList.length, notices: notices.length,
  };

  // ─── Tabs config ───────────────────────────────────────────────────────────
  const TABS: Array<{ id: ServiceType; label: string; emoji: string; active: string; inactive: string }> = [
    { id: 'emergency', label: 'Emergency', emoji: '🚑', active: 'bg-red-600 text-white shadow-red-200 shadow-md', inactive: 'bg-white text-gray-600 hover:bg-red-50 hover:text-red-600 border border-gray-200' },
    { id: 'schemes', label: 'Schemes', emoji: '🎯', active: 'bg-emerald-600 text-white shadow-emerald-200 shadow-md', inactive: 'bg-white text-gray-600 hover:bg-emerald-50 hover:text-emerald-600 border border-gray-200' },
    { id: 'jobs', label: 'Jobs', emoji: '💼', active: 'bg-blue-600 text-white shadow-blue-200 shadow-md', inactive: 'bg-white text-gray-600 hover:bg-blue-50 hover:text-blue-600 border border-gray-200' },
    { id: 'rti', label: 'RTI', emoji: '📋', active: 'bg-violet-600 text-white shadow-violet-200 shadow-md', inactive: 'bg-white text-gray-600 hover:bg-violet-50 hover:text-violet-600 border border-gray-200' },
    { id: 'transport', label: 'Transport', emoji: '🚆', active: 'bg-amber-500 text-white shadow-amber-200 shadow-md', inactive: 'bg-white text-gray-600 hover:bg-amber-50 hover:text-amber-600 border border-gray-200' },
    { id: 'notices', label: 'Notices', emoji: '📢', active: 'bg-orange-500 text-white shadow-orange-200 shadow-md', inactive: 'bg-white text-gray-600 hover:bg-orange-50 hover:text-orange-600 border border-gray-200' },
  ];

  const modaLabel = modalMode === 'add' ? 'Add' : 'Edit';
  const tabLabel = TABS.find(t => t.id === activeTab)?.label ?? '';

  // ─── Render content ────────────────────────────────────────────────────────
  const renderEmptyState = (msg: string) => (
    <div className="flex flex-col items-center justify-center py-20 text-gray-400">
      <div className="text-5xl mb-4 opacity-40">📭</div>
      <p className="font-medium text-gray-500">{msg}</p>
      <p className="text-sm mt-1">Click <strong className="text-gray-600">+ Add New</strong> to get started</p>
    </div>
  );

  const renderContent = () => {
    if (loading) return (
      <div className="space-y-3">
        {[1, 2, 3].map(i => (
          <div key={i} className="h-24 rounded-xl bg-gradient-to-r from-gray-100 via-gray-50 to-gray-100 animate-pulse" />
        ))}
      </div>
    );

    switch (activeTab) {
      // ── Emergency ──────────────────────────────────────────────────────────
      case 'emergency': {
        const grouped = categoryGroup(filtered.emergency);
        if (!filtered.emergency.length) return renderEmptyState('No emergency services found');
        return (
          <div className="space-y-4">
            {Object.entries(grouped).map(([grp, svcs]) => {
              const { emoji, bg, border, badge } = emergencyIcon(svcs[0]?.type || '');
              const open = collapsedGroups[grp] !== true;
              return (
                <div key={grp} className={`rounded-xl border-2 ${border} overflow-hidden`}>
                  <button
                    className={`w-full flex items-center justify-between px-4 py-3 ${bg} transition`}
                    onClick={() => setCollapsedGroups(p => ({ ...p, [grp]: open }))}
                  >
                    <div className="flex items-center gap-2.5">
                      <span className="text-2xl">{emoji}</span>
                      <span className="font-bold text-gray-800 text-sm">{grp}</span>
                      <span className={`text-xs font-bold px-2 py-0.5 rounded-full ${badge}`}>{svcs.length}</span>
                    </div>
                    {Icon.chevron(open)}
                  </button>
                  {open && (
                    <div className="divide-y divide-gray-50">
                      {svcs.map(s => (
                        <div key={s.id} className="px-4 py-3.5 bg-white hover:bg-gray-50/60 transition flex items-start gap-3">
                          <div className={`w-9 h-9 rounded-xl ${bg} flex items-center justify-center shrink-0 mt-0.5 text-lg`}>
                            {emoji}
                          </div>
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2 flex-wrap mb-1.5">
                              <h3 className="font-semibold text-gray-900 text-sm">{s.name}</h3>
                              <Chip label={s.type} color="gray" />
                              {s.is_citywide && <Chip label="Citywide" color="blue" />}
                              {s.is_24x7 && <Chip label="24×7" color="green" />}
                              <StatusPill active={s.is_active} />
                            </div>
                            <div className="flex flex-wrap gap-x-4 gap-y-1">
                              <FieldRow icon={<Icon.phone />} text={s.phone} />
                              {s.alternate_phone && <FieldRow icon={<Icon.phone />} text={`Alt: ${s.alternate_phone}`} />}
                              {s.email && <FieldRow icon={<Icon.mail />} text={s.email} />}
                              {s.address && <FieldRow icon={<Icon.pin />} text={s.address} />}
                            </div>
                          </div>
                          <CardActions active={s.is_active} onEdit={() => openEdit(s)} onDelete={() => handleDelete(s.id)} onToggle={() => handleToggle(s.id, s.is_active)} />
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        );
      }

      // ── Schemes ────────────────────────────────────────────────────────────
      case 'schemes':
        if (!filtered.schemes.length) return renderEmptyState('No government schemes found');
        return (
          <div className="space-y-3">
            {filtered.schemes.map(s => (
              <div key={s.id} className="border border-gray-100 rounded-xl p-4 hover:shadow-sm transition bg-white">
                <div className="flex items-start gap-3">
                  <div className="w-9 h-9 rounded-xl bg-emerald-50 flex items-center justify-center shrink-0 text-emerald-600">
                    <Icon.star />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap mb-1.5">
                      <h3 className="font-semibold text-gray-900 text-sm">{s.title || s.name}</h3>
                      <Chip label={s.category} color="green" />
                      <StatusPill active={s.is_active} />
                    </div>
                    <p className="text-sm text-gray-600 line-clamp-2 mb-1.5">{s.description}</p>
                    {(s.benefits) && <p className="text-xs text-emerald-600 font-medium">✦ {(s.benefits).substring(0, 120)}</p>}
                    {s.deadline && <div className="mt-1"><FieldRow icon={<Icon.calendar />} text={`Deadline: ${fmtDate(s.deadline)}`} /></div>}
                  </div>
                  <CardActions active={s.is_active} onEdit={() => openEdit(s)} onDelete={() => handleDelete(s.id)} onToggle={() => handleToggle(s.id, s.is_active)} />
                </div>
              </div>
            ))}
          </div>
        );

      // ── Jobs ───────────────────────────────────────────────────────────────
      case 'jobs':
        if (!filtered.jobs.length) return renderEmptyState('No job vacancies found');
        return (
          <div className="space-y-3">
            {filtered.jobs.map(j => (
              <div key={j.id} className="border border-gray-100 rounded-xl p-4 hover:shadow-sm transition bg-white">
                <div className="flex items-start gap-3">
                  <div className="w-9 h-9 rounded-xl bg-blue-50 flex items-center justify-center shrink-0 text-blue-600">
                    <Icon.briefcase />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap mb-1.5">
                      <h3 className="font-semibold text-gray-900 text-sm">{j.title}</h3>
                      <Chip label={j.organization} color="blue" />
                      {j.job_type && <Chip label={j.job_type} color="purple" />}
                      <StatusPill active={j.is_active} />
                    </div>
                    <div className="flex flex-wrap gap-x-4 gap-y-1">
                      {j.location && <FieldRow icon={<Icon.pin />} text={j.location} />}
                      {j.salary_range && <FieldRow icon={<Icon.currency />} text={j.salary_range} />}
                      {j.last_date && <FieldRow icon={<Icon.calendar />} text={`Apply by: ${fmtDate(j.last_date)}`} />}
                    </div>
                  </div>
                  <CardActions active={j.is_active} onEdit={() => openEdit(j)} onDelete={() => handleDelete(j.id)} onToggle={() => handleToggle(j.id, j.is_active)} />
                </div>
              </div>
            ))}
          </div>
        );

      // ── RTI ────────────────────────────────────────────────────────────────
      case 'rti':
        if (!filtered.rti.length) return renderEmptyState('No RTI information found');
        return (
          <div className="space-y-3">
            {filtered.rti.map(r => (
              <div key={r.id} className="border border-gray-100 rounded-xl p-4 hover:shadow-sm transition bg-white">
                <div className="flex items-start gap-3">
                  <div className="w-9 h-9 rounded-xl bg-violet-50 flex items-center justify-center shrink-0 text-violet-600">
                    <Icon.file />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap mb-1.5">
                      <h3 className="font-semibold text-gray-900 text-sm">{r.title}</h3>
                      <Chip label={`Order: ${r.display_order}`} color="gray" />
                      <StatusPill active={r.is_active} />
                    </div>
                    {r.description && <p className="text-sm text-gray-600 mb-1.5">{r.description}</p>}
                    <div className="flex gap-3 flex-wrap">
                      {r.form_link && <a href={r.form_link} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-xs text-violet-600 hover:underline"><Icon.link /> Form</a>}
                      {r.portal_link && <a href={r.portal_link} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-xs text-indigo-600 hover:underline"><Icon.link /> Portal</a>}
                    </div>
                  </div>
                  <CardActions active={r.is_active} onEdit={() => openEdit(r)} onDelete={() => handleDelete(r.id)} onToggle={() => handleToggle(r.id, r.is_active)} />
                </div>
              </div>
            ))}
          </div>
        );

      // ── Transport ──────────────────────────────────────────────────────────
      case 'transport': {
        const tIcon: Record<string, { emoji: string; color: string }> = {
          RAILWAY: { emoji: '🚆', color: 'bg-amber-50 text-amber-600' },
          BUS: { emoji: '🚌', color: 'bg-orange-50 text-orange-600' },
          METRO: { emoji: '🚇', color: 'bg-purple-50 text-purple-600' },
          AUTO: { emoji: '🛺', color: 'bg-yellow-50 text-yellow-600' },
        };
        if (!filtered.transport.length) return renderEmptyState('No transport information found');
        return (
          <div className="space-y-3">
            {filtered.transport.map(t => {
              const ti = tIcon[t.transport_type] || { emoji: '🚌', color: 'bg-gray-50 text-gray-600' };
              return (
                <div key={t.id} className="border border-gray-100 rounded-xl p-4 hover:shadow-sm transition bg-white">
                  <div className="flex items-start gap-3">
                    <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 text-xl ${ti.color}`}>{ti.emoji}</div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 flex-wrap mb-1.5">
                        <h3 className="font-semibold text-gray-900 text-sm">{t.name}</h3>
                        <Chip label={t.transport_type} color="amber" />
                        {t.route_number && <Chip label={`Route ${t.route_number}`} color="purple" />}
                        <StatusPill active={t.is_active} />
                      </div>
                      <div className="flex flex-wrap gap-x-4 gap-y-1">
                        <FieldRow icon={<Icon.pin />} text={`${t.source} → ${t.destination}`} />
                        {t.frequency && <FieldRow icon={<Icon.clock />} text={t.frequency} />}
                        {t.fare && <FieldRow icon={<Icon.currency />} text={`Fare: ${t.fare}`} />}
                        {t.departure_time && t.arrival_time && <FieldRow icon={<Icon.clock />} text={`${t.departure_time} – ${t.arrival_time}`} />}
                      </div>
                    </div>
                    <CardActions active={t.is_active} onEdit={() => openEdit(t)} onDelete={() => handleDelete(t.id)} onToggle={() => handleToggle(t.id, t.is_active)} />
                  </div>
                </div>
              );
            })}
          </div>
        );
      }

      // ── Notices ────────────────────────────────────────────────────────────
      case 'notices': {
        const noticeColor: Record<string, string> = {
          NOTICE: 'bg-blue-50 text-blue-600', ALERT: 'bg-red-50 text-red-600',
          EVENT: 'bg-emerald-50 text-emerald-600', CIRCULAR: 'bg-indigo-50 text-indigo-600',
          UPDATE: 'bg-amber-50 text-amber-600',
        };
        if (!filtered.notices.length) return renderEmptyState('No notices found');
        return (
          <div className="space-y-3">
            {filtered.notices.map(n => (
              <div key={n.id} className="border border-gray-100 rounded-xl p-4 hover:shadow-sm transition bg-white">
                <div className="flex items-start gap-3">
                  <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${noticeColor[n.notice_type] || 'bg-gray-50 text-gray-600'}`}>
                    <Icon.bell />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap mb-1.5">
                      <h3 className="font-semibold text-gray-900 text-sm">{n.title}</h3>
                      <Chip label={n.notice_type} color="gray" />
                      {n.target_role && <Chip label={`→ ${n.target_role}`} color="purple" />}
                      <StatusPill active={n.is_active} />
                    </div>
                    <p className="text-sm text-gray-600 mb-1.5">{n.message}</p>
                    <div className="flex gap-4 text-xs text-gray-400">
                      <FieldRow icon={<Icon.calendar />} text={`Created ${fmtDate(n.created_at)}`} />
                      {n.expires_at && <FieldRow icon={<Icon.calendar />} text={`Expires ${fmtDate(n.expires_at)}`} />}
                    </div>
                  </div>
                  <CardActions active={n.is_active} onEdit={() => openEdit(n)} onDelete={() => handleDelete(n.id)} onToggle={() => handleToggle(n.id, n.is_active)} />
                </div>
              </div>
            ))}
          </div>
        );
      }
    }
  };

  // ─── Modal content per tab ──────────────────────────────────────────────────
  const renderModalContent = () => {
    switch (activeTab) {
      case 'emergency':
        return (
          <>
            <FormField label="Service Name" required>
              <input type="text" className={inputCls} value={emergencyForm.name} onChange={e => setEmergencyForm(p => ({ ...p, name: e.target.value }))} placeholder="e.g. Sassoon General Hospital" required />
            </FormField>
            <FormField label="Service Type" required>
              <select className={selectCls} value={emergencyForm.type} onChange={e => setEmergencyForm(p => ({ ...p, type: e.target.value }))}>
                {EMERGENCY_TYPES.map(t => <option key={t}>{t}</option>)}
              </select>
            </FormField>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Phone Number" required>
                <input type="tel" className={inputCls} value={emergencyForm.phone} onChange={e => setEmergencyForm(p => ({ ...p, phone: e.target.value }))} placeholder="022-XXXX-XXXX" />
              </FormField>
              <FormField label="Alternate Phone">
                <input type="tel" className={inputCls} value={emergencyForm.alternate_phone} onChange={e => setEmergencyForm(p => ({ ...p, alternate_phone: e.target.value }))} />
              </FormField>
            </div>
            <FormField label="Email">
              <input type="email" className={inputCls} value={emergencyForm.email} onChange={e => setEmergencyForm(p => ({ ...p, email: e.target.value }))} />
            </FormField>
            <FormField label="Address">
              <textarea className={textareaCls} rows={2} value={emergencyForm.address} onChange={e => setEmergencyForm(p => ({ ...p, address: e.target.value }))} placeholder="Full address with landmark" />
            </FormField>
            <FormField label="Google Maps Link">
              <input type="url" className={inputCls} value={emergencyForm.google_maps_link} onChange={e => setEmergencyForm(p => ({ ...p, google_maps_link: e.target.value }))} placeholder="https://maps.google.com/..." />
            </FormField>
            <FormField label="Category">
              <input type="text" className={inputCls} value={emergencyForm.category} onChange={e => setEmergencyForm(p => ({ ...p, category: e.target.value }))} placeholder="e.g. Government Hospital, Private" />
            </FormField>
            <div className="flex gap-6 pt-1">
              {[['is_citywide', 'Citywide Service'], ['is_24x7', '24×7 Available']].map(([key, label]) => (
                <label key={key} className="flex items-center gap-2 cursor-pointer group">
                  <div className={`w-5 h-5 rounded border-2 flex items-center justify-center transition ${(emergencyForm as any)[key] ? 'bg-indigo-600 border-indigo-600' : 'border-gray-300 group-hover:border-indigo-400'}`}
                    onClick={() => setEmergencyForm(p => ({ ...p, [key]: !(p as any)[key] }))}>
                    {(emergencyForm as any)[key] && <span className="text-white"><Icon.check /></span>}
                  </div>
                  <span className="text-sm font-medium text-gray-700">{label}</span>
                </label>
              ))}
            </div>
          </>
        );

      case 'schemes':
        return (
          <>
            <FormField label="Scheme Title" required>
              <input type="text" className={inputCls} value={schemeForm.title} onChange={e => setSchemeForm(p => ({ ...p, title: e.target.value }))} placeholder="e.g. PM Awas Yojana" />
            </FormField>
            <FormField label="Category" required>
              <select className={selectCls} value={schemeForm.category} onChange={e => setSchemeForm(p => ({ ...p, category: e.target.value }))}>
                {SCHEME_CATEGORIES.map(c => <option key={c}>{c}</option>)}
              </select>
            </FormField>
            <FormField label="Description" required>
              <textarea className={textareaCls} rows={3} value={schemeForm.description} onChange={e => setSchemeForm(p => ({ ...p, description: e.target.value }))} placeholder="What is this scheme about?" />
            </FormField>
            <FormField label="Eligibility Criteria">
              <textarea className={textareaCls} rows={2} value={schemeForm.eligibility} onChange={e => setSchemeForm(p => ({ ...p, eligibility: e.target.value }))} placeholder="Who can apply?" />
            </FormField>
            <FormField label="Benefits">
              <textarea className={textareaCls} rows={2} value={schemeForm.benefits} onChange={e => setSchemeForm(p => ({ ...p, benefits: e.target.value }))} placeholder="What benefits does it provide?" />
            </FormField>
            <FormField label="Required Documents">
              <textarea className={textareaCls} rows={2} value={schemeForm.required_documents} onChange={e => setSchemeForm(p => ({ ...p, required_documents: e.target.value }))} placeholder="Aadhar, PAN, Ration Card..." />
            </FormField>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Official Link">
                <input type="url" className={inputCls} value={schemeForm.official_link} onChange={e => setSchemeForm(p => ({ ...p, official_link: e.target.value }))} placeholder="https://..." />
              </FormField>
              <FormField label="Deadline">
                <input type="date" className={inputCls} value={schemeForm.deadline} onChange={e => setSchemeForm(p => ({ ...p, deadline: e.target.value }))} />
              </FormField>
            </div>
          </>
        );

      case 'jobs':
        return (
          <>
            <FormField label="Job Title" required>
              <input type="text" className={inputCls} value={jobForm.title} onChange={e => setJobForm(p => ({ ...p, title: e.target.value }))} placeholder="e.g. Junior Engineer" />
            </FormField>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Organization" required>
                <input type="text" className={inputCls} value={jobForm.organization} onChange={e => setJobForm(p => ({ ...p, organization: e.target.value }))} placeholder="e.g. PMC" />
              </FormField>
              <FormField label="Job Type">
                <select className={selectCls} value={jobForm.job_type} onChange={e => setJobForm(p => ({ ...p, job_type: e.target.value }))}>
                  {JOB_TYPES.map(t => <option key={t}>{t}</option>)}
                </select>
              </FormField>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Location">
                <input type="text" className={inputCls} value={jobForm.location} onChange={e => setJobForm(p => ({ ...p, location: e.target.value }))} placeholder="Pune, Maharashtra" />
              </FormField>
              <FormField label="Salary Range">
                <input type="text" className={inputCls} value={jobForm.salary_range} onChange={e => setJobForm(p => ({ ...p, salary_range: e.target.value }))} placeholder="₹25,000 – ₹40,000" />
              </FormField>
            </div>
            <FormField label="Description">
              <textarea className={textareaCls} rows={2} value={jobForm.description} onChange={e => setJobForm(p => ({ ...p, description: e.target.value }))} />
            </FormField>
            <FormField label="Eligibility">
              <textarea className={textareaCls} rows={2} value={jobForm.eligibility} onChange={e => setJobForm(p => ({ ...p, eligibility: e.target.value }))} />
            </FormField>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Application Link">
                <input type="url" className={inputCls} value={jobForm.application_link} onChange={e => setJobForm(p => ({ ...p, application_link: e.target.value }))} placeholder="https://..." />
              </FormField>
              <FormField label="Last Date to Apply">
                <input type="date" className={inputCls} value={jobForm.last_date} onChange={e => setJobForm(p => ({ ...p, last_date: e.target.value }))} />
              </FormField>
            </div>
          </>
        );

      case 'rti':
        return (
          <>
            <FormField label="Title" required>
              <input type="text" className={inputCls} value={rtiForm.title} onChange={e => setRTIForm(p => ({ ...p, title: e.target.value }))} placeholder="e.g. How to file an RTI Application" />
            </FormField>
            <FormField label="Description">
              <textarea className={textareaCls} rows={2} value={rtiForm.description} onChange={e => setRTIForm(p => ({ ...p, description: e.target.value }))} />
            </FormField>
            <FormField label="Content / Steps">
              <textarea className={textareaCls} rows={4} value={rtiForm.content} onChange={e => setRTIForm(p => ({ ...p, content: e.target.value }))} placeholder="Detailed steps or content..." />
            </FormField>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Form Link">
                <input type="url" className={inputCls} value={rtiForm.form_link} onChange={e => setRTIForm(p => ({ ...p, form_link: e.target.value }))} placeholder="https://..." />
              </FormField>
              <FormField label="Portal Link">
                <input type="url" className={inputCls} value={rtiForm.portal_link} onChange={e => setRTIForm(p => ({ ...p, portal_link: e.target.value }))} placeholder="https://rtionline.gov.in" />
              </FormField>
            </div>
            <FormField label="Display Order">
              <input type="number" className={inputCls} value={rtiForm.display_order} onChange={e => setRTIForm(p => ({ ...p, display_order: parseInt(e.target.value) || 0 }))} min={0} />
            </FormField>
          </>
        );

      case 'transport':
        return (
          <>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Transport Type" required>
                <select className={selectCls} value={transportForm.transport_type} onChange={e => setTransportForm(p => ({ ...p, transport_type: e.target.value }))}>
                  {TRANSPORT_TYPES.map(t => <option key={t}>{t}</option>)}
                </select>
              </FormField>
              <FormField label="Route Number">
                <input type="text" className={inputCls} value={transportForm.route_number} onChange={e => setTransportForm(p => ({ ...p, route_number: e.target.value }))} placeholder="e.g. 155" />
              </FormField>
            </div>
            <FormField label="Route / Service Name" required>
              <input type="text" className={inputCls} value={transportForm.name} onChange={e => setTransportForm(p => ({ ...p, name: e.target.value }))} placeholder="e.g. Shivajinagar – Hadapsar Express" />
            </FormField>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="From (Source)" required>
                <input type="text" className={inputCls} value={transportForm.source} onChange={e => setTransportForm(p => ({ ...p, source: e.target.value }))} placeholder="Shivajinagar" />
              </FormField>
              <FormField label="To (Destination)" required>
                <input type="text" className={inputCls} value={transportForm.destination} onChange={e => setTransportForm(p => ({ ...p, destination: e.target.value }))} placeholder="Hadapsar" />
              </FormField>
            </div>
            <FormField label="Via Stops">
              <input type="text" className={inputCls} value={transportForm.via_stops} onChange={e => setTransportForm(p => ({ ...p, via_stops: e.target.value }))} placeholder="Deccan, FC Road, Pune Station..." />
            </FormField>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Departure Time">
                <input type="time" className={inputCls} value={transportForm.departure_time} onChange={e => setTransportForm(p => ({ ...p, departure_time: e.target.value }))} />
              </FormField>
              <FormField label="Arrival Time">
                <input type="time" className={inputCls} value={transportForm.arrival_time} onChange={e => setTransportForm(p => ({ ...p, arrival_time: e.target.value }))} />
              </FormField>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Frequency">
                <input type="text" className={inputCls} value={transportForm.frequency} onChange={e => setTransportForm(p => ({ ...p, frequency: e.target.value }))} placeholder="Every 15 mins" />
              </FormField>
              <FormField label="Fare">
                <input type="text" className={inputCls} value={transportForm.fare} onChange={e => setTransportForm(p => ({ ...p, fare: e.target.value }))} placeholder="₹20 – ₹60" />
              </FormField>
            </div>
            <FormField label="Map / Route Link">
              <input type="url" className={inputCls} value={transportForm.map_link} onChange={e => setTransportForm(p => ({ ...p, map_link: e.target.value }))} placeholder="https://..." />
            </FormField>
          </>
        );

      case 'notices':
        return (
          <>
            <FormField label="Notice Title" required>
              <input type="text" className={inputCls} value={noticeForm.title} onChange={e => setNoticeForm(p => ({ ...p, title: e.target.value }))} placeholder="e.g. Water Supply Disruption – Ward 12" />
            </FormField>
            <FormField label="Notice Type" required>
              <select className={selectCls} value={noticeForm.notice_type} onChange={e => setNoticeForm(p => ({ ...p, notice_type: e.target.value }))}>
                {NOTICE_TYPES.map(t => <option key={t}>{t}</option>)}
              </select>
            </FormField>
            <FormField label="Message" required>
              <textarea className={textareaCls} rows={4} value={noticeForm.message} onChange={e => setNoticeForm(p => ({ ...p, message: e.target.value }))} placeholder="Full notice content..." />
            </FormField>
            <div className="grid grid-cols-2 gap-3">
              <FormField label="Target Role">
                <select className={selectCls} value={noticeForm.target_role} onChange={e => setNoticeForm(p => ({ ...p, target_role: e.target.value }))}>
                  <option value="">All Users</option>
                  <option value="CITIZEN">Citizens</option>
                  <option value="FIELD_OFFICER">Field Officers</option>
                  <option value="WARD_ADMIN">Ward Admins</option>
                </select>
              </FormField>
              <FormField label="Expires On">
                <input type="date" className={inputCls} value={noticeForm.expires_at} onChange={e => setNoticeForm(p => ({ ...p, expires_at: e.target.value }))} />
              </FormField>
            </div>
          </>
        );
    }
  };

  const currentTab = TABS.find(t => t.id === activeTab)!;

  return (
    <div className="min-h-screen bg-gray-50/60">
      <div className="max-w-5xl mx-auto px-4 py-6 space-y-5">

        {/* ── Header ─────────────────────────────────────────────────────────── */}
        <div className="flex items-center justify-between flex-wrap gap-3">
          <div>
            <h1 className="text-2xl font-extrabold text-gray-900 tracking-tight">Services Management</h1>
            <p className="text-sm text-gray-500 mt-0.5">Manage emergency services, schemes, jobs, transport & more</p>
          </div>
          <button
            onClick={openAdd}
            className="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white font-semibold text-sm px-4 py-2.5 rounded-xl shadow-sm shadow-indigo-200 transition"
          >
            <Icon.plus />
            Add {currentTab.label}
          </button>
        </div>

        {/* ── Tabs ───────────────────────────────────────────────────────────── */}
        <div className="flex flex-wrap gap-2">
          {TABS.map(tab => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-sm font-semibold transition ${activeTab === tab.id ? tab.active : tab.inactive}`}
            >
              <span>{tab.emoji}</span>
              <span>{tab.label}</span>
              <span className={`text-xs font-bold px-1.5 py-0.5 rounded-full ${activeTab === tab.id ? 'bg-white/25 text-white' : 'bg-gray-100 text-gray-500'}`}>
                {counts[tab.id]}
              </span>
            </button>
          ))}
        </div>

        {/* ── Search bar ─────────────────────────────────────────────────────── */}
        <div className="relative">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"><Icon.search /></span>
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder={`Search ${tabLabel.toLowerCase()}…`}
            className="w-full pl-9 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:border-transparent transition"
          />
          {search && (
            <button onClick={() => setSearch('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
              <Icon.close />
            </button>
          )}
        </div>

        {/* ── Content card ───────────────────────────────────────────────────── */}
        <div className="bg-white rounded-2xl border border-gray-100 shadow-sm p-4">
          {renderContent()}
        </div>
      </div>

      {/* ── Modal ──────────────────────────────────────────────────────────────── */}
      {showModal && (
        <Modal title={`${modaLabel} ${tabLabel}`} onClose={() => setShowModal(false)} size={activeTab === 'transport' || activeTab === 'schemes' ? 'lg' : 'md'}>
          {renderModalContent()}

          {/* Modal Footer */}
          <div className="flex gap-3 pt-2 border-t border-gray-100 mt-2">
            <button onClick={() => setShowModal(false)} className="flex-1 py-2.5 rounded-xl border border-gray-200 text-sm font-semibold text-gray-700 hover:bg-gray-50 transition">
              Cancel
            </button>
            <button
              onClick={handleSubmit}
              disabled={saving}
              className="flex-1 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-60 text-white text-sm font-semibold transition flex items-center justify-center gap-2"
            >
              {saving ? (
                <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"/>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"/>
                </svg>
              ) : null}
              {saving ? 'Saving…' : modalMode === 'add' ? `Add ${tabLabel}` : 'Save Changes'}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}