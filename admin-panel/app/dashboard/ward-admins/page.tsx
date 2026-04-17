'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';

interface WardAdmin {
  id: string;
  admin_id: string;
  ward_id: string;
  ward_name: string;
  jurisdiction_area: string;
  status: string;
  created_at: string;
}

export default function WardAdminsPage() {
  const [wardAdmins, setWardAdmins] = useState<WardAdmin[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchWardAdmins();
  }, []);

  const fetchWardAdmins = async () => {
    try {
      setLoading(true);
      const response = await apiClient.get<WardAdmin[]>('/admin/ward-admins');
      setWardAdmins(response);
    } catch (error) {
      console.error('Failed to fetch ward admins:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure?')) {
      try {
        await apiClient.delete(`/admin/ward-admins/${id}`);
        setWardAdmins(wardAdmins.filter((a) => a.id !== id));
      } catch (error) {
        console.error('Failed to delete:', error);
      }
    }
  };

  const filteredAdmins = wardAdmins.filter(
    (a) =>
      a.ward_name.toLowerCase().includes(search.toLowerCase()) ||
      a.jurisdiction_area.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Ward Admins</h1>
          <p className="text-gray-600">Manage ward administrators and jurisdictions</p>
        </div>
        <Link href="/dashboard/ward-admins/new" className="btn-primary">
          Add Ward Admin
        </Link>
      </div>

      <div className="card space-y-4">
        <input
          type="text"
          placeholder="Search by ward name or area..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="input-field"
        />

        {loading ? (
          <div className="text-center text-gray-500">Loading...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Ward Name</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Ward ID</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Jurisdiction Area</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Status</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredAdmins.map((admin) => (
                  <tr key={admin.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="px-6 py-4">{admin.ward_name}</td>
                    <td className="px-6 py-4">{admin.ward_id}</td>
                    <td className="px-6 py-4">{admin.jurisdiction_area}</td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        admin.status === 'active' ? 'bg-green-50 text-green-600' : 'bg-gray-50 text-gray-600'
                      }`}>
                        {admin.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 space-x-2">
                      <Link href={`/dashboard/ward-admins/${admin.id}`} className="text-blue-600 hover:text-blue-800">
                        Edit
                      </Link>
                      <button onClick={() => handleDelete(admin.id)} className="text-red-600 hover:text-red-800">
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filteredAdmins.length === 0 && (
              <div className="text-center py-8 text-gray-500">No ward admins found</div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
