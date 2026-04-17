'use client';

import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';

interface Agency {
  id: string;
  user_id: string;
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

  useEffect(() => {
    fetchAgencies();
  }, []);

  const fetchAgencies = async () => {
    try {
      setLoading(true);
      const response = await apiClient.get('/matrimonial/agencies');
      setAgencies(response.data);
    } catch (error) {
      console.error('Failed to fetch agencies:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (id: string) => {
    try {
      await apiClient.put(`/admin/matrimonial/agencies/${id}/verify`, {
        verification_status: 'verified',
      });
      setAgencies(agencies.map((a) =>
        a.id === id ? { ...a, verification_status: 'verified' } : a
      ));
    } catch (error) {
      console.error('Failed to verify:', error);
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure?')) {
      try {
        await apiClient.delete(`/admin/matrimonial/agencies/${id}`);
        setAgencies(agencies.filter((a) => a.id !== id));
      } catch (error) {
        console.error('Failed to delete:', error);
      }
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Matrimonial Agencies</h1>
        <p className="text-gray-600">Manage matrimonial service agencies</p>
      </div>

      <div className="card space-y-4">
        {loading ? (
          <div className="text-center text-gray-500">Loading...</div>
        ) : (
          <div className="space-y-4">
            {agencies.map((agency) => (
              <div
                key={agency.id}
                className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900">{agency.business_name}</h3>
                    <p className="text-sm text-gray-600 mt-1">
                      Contact: {agency.contact_person}
                    </p>
                    <div className="flex gap-4 mt-2 text-xs text-gray-500">
                      <span>{agency.phone}</span>
                      <span>{agency.email}</span>
                      <span>Reg: {agency.registration_number}</span>
                    </div>
                  </div>
                  <span
                    className={`px-3 py-1 rounded-full text-xs font-semibold ${
                      agency.verification_status === 'verified'
                        ? 'bg-green-50 text-green-600'
                        : 'bg-yellow-50 text-yellow-600'
                    }`}
                  >
                    {agency.verification_status}
                  </span>
                </div>
                <div className="flex items-center justify-end gap-2 mt-4">
                  {agency.verification_status !== 'verified' && (
                    <button
                      onClick={() => handleVerify(agency.id)}
                      className="text-sm text-green-600 hover:text-green-800"
                    >
                      Verify
                    </button>
                  )}
                  <button
                    onClick={() => handleDelete(agency.id)}
                    className="text-sm text-red-600 hover:text-red-800"
                  >
                    Delete
                  </button>
                </div>
              </div>
            ))}
            {agencies.length === 0 && (
              <div className="text-center py-8 text-gray-500">No agencies found</div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
