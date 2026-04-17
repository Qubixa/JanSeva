'use client';

import { useEffect, useState } from 'react';
import { apiClient } from '@/lib/api-client';

interface Stats {
  total_users: number;
  total_matrimonial_users: number;
  total_agencies: number;
  total_field_users: number;
  total_ward_admins: number;
  pending_matches: number;
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await apiClient.get('/admin/dashboard-stats');
        setStats(response.data);
      } catch (error) {
        console.error('Failed to fetch stats:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, []);

  if (loading) {
    return <div className="text-center">Loading...</div>;
  }

  const statCards = [
    {
      title: 'Total Users',
      value: stats?.total_users || 0,
      color: 'blue',
      icon: '👥',
    },
    {
      title: 'Matrimonial Users',
      value: stats?.total_matrimonial_users || 0,
      color: 'pink',
      icon: '💍',
    },
    {
      title: 'Matrimonial Agencies',
      value: stats?.total_agencies || 0,
      color: 'purple',
      icon: '🏢',
    },
    {
      title: 'Field Users',
      value: stats?.total_field_users || 0,
      color: 'green',
      icon: '🚶',
    },
    {
      title: 'Ward Admins',
      value: stats?.total_ward_admins || 0,
      color: 'orange',
      icon: '🏛️',
    },
    {
      title: 'Pending Matches',
      value: stats?.pending_matches || 0,
      color: 'red',
      icon: '❤️',
    },
  ];

  const colorClasses = {
    blue: 'bg-blue-50 border-blue-200 text-blue-600',
    pink: 'bg-pink-50 border-pink-200 text-pink-600',
    purple: 'bg-purple-50 border-purple-200 text-purple-600',
    green: 'bg-green-50 border-green-200 text-green-600',
    orange: 'bg-orange-50 border-orange-200 text-orange-600',
    red: 'bg-red-50 border-red-200 text-red-600',
  };

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-600 mt-2">Welcome to the JanSeva Admin Panel</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {statCards.map((card, index) => (
          <div
            key={index}
            className={`card border ${
              colorClasses[card.color as keyof typeof colorClasses]
            }`}
          >
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">{card.title}</p>
                <p className="text-3xl font-bold mt-2">{card.value}</p>
              </div>
              <span className="text-3xl">{card.icon}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="card space-y-4">
        <h2 className="text-xl font-bold">Quick Actions</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <a
            href="/dashboard/users/new"
            className="btn-primary text-center"
          >
            Add User
          </a>
          <a
            href="/dashboard/field-users/new"
            className="btn-primary text-center"
          >
            Add Field User
          </a>
          <a
            href="/dashboard/ward-admins/new"
            className="btn-primary text-center"
          >
            Add Ward Admin
          </a>
          <a
            href="/dashboard/home-content/new"
            className="btn-primary text-center"
          >
            Add Content
          </a>
        </div>
      </div>
    </div>
  );
}
