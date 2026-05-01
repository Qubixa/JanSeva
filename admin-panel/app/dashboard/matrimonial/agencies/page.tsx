'use client';

import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';

interface Agency {
  id: string;
  business_name: string;
  registration_number: string;
  contact_person: string;
  email: string;
  phone: string;
  address: string;
  verification_status: string;
  created_at: string;
}

export default function MatrimonialAgenciesPage() {
  const [agencies, setAgencies] = useState<Agency[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => { fetchAgencies(); }, []);

  const fetchAgencies = async () => {
    try {
      const response = await apiClient.get<Agency[]>('/matrimonial/agencies');
      setAgencies(response);
    } catch (error) {
      console.error('Failed to fetch agencies:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (id: string) => {
    try {
      await apiClient.put(`/admin/matrimonial/agencies/${id}/verify`, { verification_status: 'verified' });
      setAgencies((prev) => prev.map((a) => a.id === id ? { ...a, verification_status: 'verified' } : a));
    } catch (error) {
      console.error('Failed to verify:', error);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this agency?')) return;
    try {
      await apiClient.delete(`/admin/matrimonial/agencies/${id}`);
      setAgencies((prev) => prev.filter((a) => a.id !== id));
    } catch (error) {
      console.error('Failed to delete:', error);
    }
  };

  const filtered = agencies.filter((a) =>
    a.business_name.toLowerCase().includes(search.toLowerCase()) ||
    a.contact_person.toLowerCase().includes(search.toLowerCase())
  );

  const verified = agencies.filter((a) => a.verification_status === 'verified').length;
  const pending  = agencies.length - verified;

  return (
    <div className="space-y-6">
      <div className="page-header">
        <div>
          <h1 className="page-title">Matrimonial Agencies</h1>
          <p className="page-subtitle">{agencies.length} agencies · {verified} verified · {pending} pending</p>
        </div>
      </div>

      {/* Summary pills */}
      <div className="flex gap-3 flex-wrap">
        <span className="badge-green text-sm px-3 py-1.5">✓ {verified} Verified</span>
        <span className="badge-yellow text-sm px-3 py-1.5">⏳ {pending} Pending</span>
      </div>

      <div className="card space-y-5">
        <div className="relative">
          <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 text-sm">🔍</span>
          <input
            type="text"
            placeholder="Search agencies…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-field pl-10"
          />
        </div>

        {loading ? (
          <div className="space-y-3">
            {[...Array(4)].map((_, i) => <div key={i} className="skeleton h-28 rounded-xl" />)}
          </div>
        ) : (
          <div className="space-y-3">
            {filtered.map((agency) => (
              <div key={agency.id} className="border border-slate-100 rounded-xl p-5 hover:border-slate-200 hover:shadow-sm transition-all">
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-bold text-slate-900">{agency.business_name}</h3>
                      <span className={agency.verification_status === 'verified' ? 'badge-green' : 'badge-yellow'}>
                        {agency.verification_status}
                      </span>
                    </div>
                    <p className="text-sm text-slate-500">
                      Contact: <span className="text-slate-700 font-medium">{agency.contact_person}</span>
                    </p>
                    <div className="flex flex-wrap gap-x-4 gap-y-1 mt-2 text-xs text-slate-400">
                      <span>📞 {agency.phone}</span>
                      <span>✉ {agency.email}</span>
                      <span>🪪 Reg: {agency.registration_number}</span>
                    </div>
                  </div>
                </div>
                <div className="flex items-center justify-end gap-2 mt-4 pt-4 border-t border-slate-50">
                  {agency.verification_status !== 'verified' && (
                    <button onClick={() => handleVerify(agency.id)} className="btn-success text-xs">
                      ✓ Verify
                    </button>
                  )}
                  <button onClick={() => handleDelete(agency.id)} className="btn-danger text-xs">
                    Delete
                  </button>
                </div>
              </div>
            ))}
            {filtered.length === 0 && (
              <div className="empty-state">
                <p className="empty-state-icon">🏢</p>
                <p className="empty-state-title">No agencies found</p>
                <p className="empty-state-desc">
                  {search ? 'Try a different search' : 'No agencies registered yet'}
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}