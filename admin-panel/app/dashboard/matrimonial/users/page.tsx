'use client';

import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';

interface MatrimonialUser {
  id: string;
  user_id: string;
  gender: string;
  marital_status: string;
  age: number;
  caste: string;
  religion: string;
  location: string;
  status: string;
  created_at: string;
}

export default function MatrimonialUsersPage() {
  const [users, setUsers] = useState<MatrimonialUser[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await apiClient.get<MatrimonialUser[]>('/matrimonial/users');
      setUsers(response);
    } catch (error) {
      console.error('Failed to fetch matrimonial users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure?')) {
      try {
        await apiClient.delete(`/admin/matrimonial/users/${id}`);
        setUsers(users.filter((u) => u.id !== id));
      } catch (error) {
        console.error('Failed to delete:', error);
      }
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Matrimonial Users</h1>
        <p className="text-gray-600">Manage matrimonial service users</p>
      </div>

      <div className="card space-y-4">
        {loading ? (
          <div className="text-center text-gray-500">Loading...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200">
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Age</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Gender</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Religion</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Location</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Status</th>
                  <th className="px-6 py-3 text-left font-semibold text-gray-700">Actions</th>
                </tr>
              </thead>
              <tbody>
                {users.map((user) => (
                  <tr key={user.id} className="border-b border-gray-100 hover:bg-gray-50">
                    <td className="px-6 py-4">{user.age}</td>
                    <td className="px-6 py-4">{user.gender}</td>
                    <td className="px-6 py-4">{user.religion}</td>
                    <td className="px-6 py-4">{user.location}</td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        user.status === 'active' ? 'bg-green-50 text-green-600' : 'bg-gray-50 text-gray-600'
                      }`}>
                        {user.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 space-x-2">
                      <button onClick={() => handleDelete(user.id)} className="text-red-600 hover:text-red-800">
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {users.length === 0 && (
              <div className="text-center py-8 text-gray-500">No matrimonial users found</div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
