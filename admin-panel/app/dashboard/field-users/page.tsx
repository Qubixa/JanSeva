'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';

interface FieldUser {
  id: string;
  user_id: string;
  location: string;
  area: string;
  assigned_region: string;
  contact_info: string;
  status: string;
  created_at: string;
}

export default function FieldUsersPage() {
  const [fieldUsers, setFieldUsers] = useState<FieldUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    fetchFieldUsers();
  }, []);

  const fetchFieldUsers = async () => {
    try {
      setLoading(true);
      const response = await apiClient.get('/admin/field-users');
      setFieldUsers(response.data);
    } catch (error) {
      console.error('Failed to fetch field users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure?')) {
      try {
        await apiClient.delete(`/admin/field-users/${id}`);
        setFieldUsers(fieldUsers.filter((u) => u.id !== id));
      } catch (error) {
        console.error('Failed to delete:', error);
      }
    }
  };

  const filteredUsers = fieldUsers.filter(
    (u) =>
      u.area.toLowerCase().includes(search.toLowerCase()) ||
      u.assigned_region.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Field Users</h1>
          <p className="text-gray-600">Manage field staff and area representatives</p>
        </div>
        <Link href="/dashboard/field-users/new" className="btn-primary">
          Add Field User
        </Link>
      </div>

      <div className="card space-y-4">
        <input
          type="text"
          placeholder="Search by area or region..."
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
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Area</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Region</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Location</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Contact</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Status</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredUsers.map((user) => (
                  <tr key={user.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="px-6 py-4">{user.area}</td>
                    <td className="px-6 py-4">{user.assigned_region}</td>
                    <td className="px-6 py-4">{user.location}</td>
                    <td className="px-6 py-4">{user.contact_info}</td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        user.status === 'active' ? 'bg-green-50 text-green-600' : 'bg-gray-50 text-gray-600'
                      }`}>
                        {user.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 space-x-2">
                      <Link href={`/dashboard/field-users/${user.id}`} className="text-blue-600 hover:text-blue-800">
                        Edit
                      </Link>
                      <button onClick={() => handleDelete(user.id)} className="text-red-600 hover:text-red-800">
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filteredUsers.length === 0 && (
              <div className="text-center py-8 text-gray-500">No field users found</div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
