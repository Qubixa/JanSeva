'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';

// Change User interface to match backend UserResponse
interface User {
  id: number;           // int not string
  name: string;
  email: string | null;
  mobile: string;       // not phone
  role: string;
  ward_id: number | null;
  ward_name: string | null;
  address: string;
  profile_image: string | null;
  is_active: boolean;
  is_verified: boolean;
}

interface UserListResponse {
  users: User[];
  total: number;
  page: number;
  page_size: number;
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [deleting, setDeleting] = useState<string | null>(null);

  useEffect(() => { fetchUsers(); }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await apiClient.get<UserListResponse>('/admin/users');
      setUsers(response.users);
    } catch (error) {
      console.error('Failed to fetch users:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this user? This action cannot be undone.')) return;
    setDeleting(id);
    try {
      await apiClient.delete(`/admin/users/${id}`);
      setUsers((u) => u.filter((x) => x.id !== id));
    } catch (error) {
      console.error('Failed to delete user:', error);
    } finally {
      setDeleting(null);
    }
  };

  const filtered = users.filter(
  (u) =>
    u.name.toLowerCase().includes(search.toLowerCase()) ||
    (u.email ?? '').toLowerCase().includes(search.toLowerCase()) ||
    u.mobile?.includes(search)
);

  return (
    <div className="space-y-6">
      <div className="page-header">
        <div>
          <h1 className="page-title">Users</h1>
          <p className="page-subtitle">
            {loading ? 'Loading…' : `${users.length} registered users`}
          </p>
        </div>
        <Link href="/dashboard/users/new" className="btn-primary">
          + Add User
        </Link>
      </div>

      <div className="card space-y-5">
        {/* Search */}
        <div className="relative">
          <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 text-sm">🔍</span>
          <input
            type="text"
            placeholder="Search by name, email or phone…"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-field pl-10"
          />
        </div>

        {/* Table */}
        {loading ? (
          <div className="space-y-3">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="skeleton h-14 rounded-xl" />
            ))}
          </div>
        ) : (
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr>
                  <th>User</th>
                  <th>Phone</th>
                  <th>Role</th>
                  <th>Status</th>
                  <th>Joined</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map((user) => (
                  <tr key={user.id}>
                    <td>
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center text-xs font-bold shrink-0">
                          {user.name?.[0]?.toUpperCase() ?? '?'}
                        </div>
                        <div>
                          <p className="font-semibold text-slate-900 text-sm">{user.name}</p>
                          <p className="text-xs text-slate-400">{user.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="text-slate-500">{user.mobile}</td>
                    <td>
                      <span className="badge-blue capitalize">{user.role}</span>
                    </td>
                    <td>
                      <span className={user.is_active ? 'badge-green' : 'badge-red'}>
                        {user.is_active ? 'Active' : 'Inactive'}
                      </span>
                    </td>
                    <td className="text-slate-400 text-xs">
                      {new Date(user.created_at).toLocaleDateString('en-IN')}
                    </td>
                    <td>
                      <div className="flex items-center gap-2">
                        <Link
                          href={`/dashboard/users/${user.id}`}
                          className="btn-ghost text-xs px-2.5 py-1.5"
                        >
                          Edit
                        </Link>
                        <button
                          onClick={() => handleDelete(user.id)}
                          disabled={deleting === user.id}
                          className="btn-danger text-xs px-2.5 py-1.5"
                        >
                          {deleting === user.id ? '…' : 'Delete'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {filtered.length === 0 && (
              <div className="empty-state">
                <p className="empty-state-icon">👤</p>
                <p className="empty-state-title">No users found</p>
                <p className="empty-state-desc">
                  {search ? 'Try a different search term' : 'Add your first user to get started'}
                </p>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}