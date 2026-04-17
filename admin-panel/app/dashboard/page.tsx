'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';

interface Stats {
  total_complaints: number;
  pending_complaints: number;
  resolved_complaints: number;
  in_progress_complaints: number;
  total_citizens: number;
  total_officers: number;
  complaints_today: number;
  complaints_this_week: number;
  category_wise: Record<string, number>;
  status_wise: Record<string, number>;
}

const statCards = (stats: Stats | null) => [
  { title: 'Total Citizens',    value: stats?.total_citizens ?? '—',         icon: '👥', color: 'blue',    href: '/dashboard/users',           desc: 'Registered citizens' },
  { title: 'Total Complaints',  value: stats?.total_complaints ?? '—',       icon: '📋', color: 'purple',  href: '/dashboard/complaints',      desc: 'All complaints' },
  { title: 'Pending',           value: stats?.pending_complaints ?? '—',     icon: '⏳', color: 'amber',   href: '/dashboard/complaints',      desc: 'Awaiting action' },
  { title: 'In Progress',       value: stats?.in_progress_complaints ?? '—', icon: '🔧', color: 'blue',    href: '/dashboard/complaints',      desc: 'Being resolved' },
  { title: 'Resolved',          value: stats?.resolved_complaints ?? '—',    icon: '✅', color: 'emerald', href: '/dashboard/complaints',      desc: 'Completed' },
  { title: 'Field Officers',    value: stats?.total_officers ?? '—',         icon: '🗺️', color: 'red',     href: '/dashboard/field-users',     desc: 'Active officers' },
];

const colorMap: Record<string, string> = {
  blue:    'bg-blue-50   text-blue-600   ring-blue-100',
  pink:    'bg-pink-50   text-pink-600   ring-pink-100',
  purple:  'bg-purple-50 text-purple-600 ring-purple-100',
  emerald: 'bg-emerald-50 text-emerald-600 ring-emerald-100',
  amber:   'bg-amber-50  text-amber-600  ring-amber-100',
  red:     'bg-red-50    text-red-600    ring-red-100',
};

const quickActions = [
  { label: 'Add User',       href: '/dashboard/users/new',        icon: '👤' },
  { label: 'Add Field User', href: '/dashboard/field-users/new',  icon: '🗺️' },
  { label: 'Add Ward Admin', href: '/dashboard/ward-admins/new',  icon: '🏛️' },
  { label: 'Add Content',    href: '/dashboard/home-content/new', icon: '🖼️' },
];

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  useEffect(() => {
  apiClient
    .get<Stats>('/admin/dashboard')
    .then((r) => setStats(r))
    .catch(() => setError(true))
    .finally(() => setLoading(false));
}, []);

  const cards = statCards(stats);

  return (
    <div className="space-y-8">
      {/* Header */}
      <div>
        <h1 className="page-title">Dashboard</h1>
        <p className="page-subtitle">
          {new Date().toLocaleDateString('en-IN', {
            weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
          })}
        </p>
      </div>

      {error && (
        <div className="alert-error">
          <span>⚠</span>
          <span>Failed to load statistics. Please refresh the page.</span>
        </div>
      )}

      {/* Stat grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-5">
        {cards.map((card) => (
          <Link
            key={card.title}
            href={card.href}
            className="card group hover:shadow-md hover:border-slate-200 transition-all duration-200"
          >
            <div className="flex items-start justify-between">
              <div>
                <p className="text-xs font-bold text-slate-500 uppercase tracking-wide">
                  {card.title}
                </p>
                <p className="text-3xl font-extrabold text-slate-900 mt-2 tabular-nums">
                  {loading ? (
                    <span className="skeleton inline-block w-16 h-8 rounded" />
                  ) : (
                    card.value
                  )}
                </p>
                <p className="text-xs text-slate-400 mt-1">{card.desc}</p>
              </div>
              <div className={`w-11 h-11 rounded-xl ring-1 flex items-center justify-center text-xl shrink-0 ${colorMap[card.color]}`}>
                {card.icon}
              </div>
            </div>
          </Link>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="card">
        <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wide mb-4">
          Quick Actions
        </h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          {quickActions.map((a) => (
            <Link
              key={a.href}
              href={a.href}
              className="flex flex-col items-center gap-2 p-4 rounded-xl bg-slate-50 hover:bg-blue-50 hover:text-blue-700 border border-slate-100 hover:border-blue-100 transition-all duration-150 text-slate-700 text-sm font-semibold text-center"
            >
              <span className="text-2xl">{a.icon}</span>
              {a.label}
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}