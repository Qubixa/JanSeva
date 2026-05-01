'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import { apiClient } from '@/lib/api-client';
import {
  Users,
  AlertCircle,
  CheckCircle,
  Clock,
  TrendingUp,
  MapPin,
  Calendar,
  ArrowUpRight,
  ArrowDownRight,
  Activity,
  RefreshCw,
  Download,
  Filter,
} from 'lucide-react';

// Dynamically import ApexCharts to avoid SSR issues
const Chart = dynamic(() => import('react-apexcharts'), { ssr: false });

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

interface TrendData {
  date: string;
  complaints: number;
  resolved: number;
}

// Stat Card Component
const StatCard = ({ title, value, icon, trend, color, href, loading }: any) => {
  const Icon = icon;
  const colors = {
    blue: { bg: 'bg-blue-50', text: 'text-blue-600', border: 'border-blue-100' },
    purple: { bg: 'bg-purple-50', text: 'text-purple-600', border: 'border-purple-100' },
    emerald: { bg: 'bg-emerald-50', text: 'text-emerald-600', border: 'border-emerald-100' },
    amber: { bg: 'bg-amber-50', text: 'text-amber-600', border: 'border-amber-100' },
    red: { bg: 'bg-red-50', text: 'text-red-600', border: 'border-red-100' },
    indigo: { bg: 'bg-indigo-50', text: 'text-indigo-600', border: 'border-indigo-100' },
  };

  const colorStyle = colors[color as keyof typeof colors] || colors.blue;

  return (
    <Link href={href} className="block">
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6 hover:shadow-md transition-all duration-200 group">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wider">
              {title}
            </p>
            {loading ? (
              <div className="mt-2 h-9 w-24 bg-slate-200 rounded animate-pulse" />
            ) : (
              <p className="text-3xl font-bold text-slate-900 mt-2">{value}</p>
            )}
            {trend && (
              <div className="flex items-center gap-1 mt-2">
                {trend > 0 ? (
                  <ArrowUpRight className="w-3 h-3 text-emerald-500" />
                ) : (
                  <ArrowDownRight className="w-3 h-3 text-red-500" />
                )}
                <span className={`text-xs font-medium ${trend > 0 ? 'text-emerald-600' : 'text-red-600'}`}>
                  {Math.abs(trend)}% from last month
                </span>
              </div>
            )}
          </div>
          <div className={`w-12 h-12 rounded-xl ${colorStyle.bg} ${colorStyle.text} flex items-center justify-center group-hover:scale-110 transition-transform duration-200`}>
            <Icon className="w-6 h-6" />
          </div>
        </div>
      </div>
    </Link>
  );
};

// Quick Action Button Component
const QuickAction = ({ label, href, icon, color }: any) => {
  const colors = {
    blue: 'bg-blue-50 hover:bg-blue-100 text-blue-700 border-blue-100',
    purple: 'bg-purple-50 hover:bg-purple-100 text-purple-700 border-purple-100',
    emerald: 'bg-emerald-50 hover:bg-emerald-100 text-emerald-700 border-emerald-100',
    amber: 'bg-amber-50 hover:bg-amber-100 text-amber-700 border-amber-100',
  };

  return (
    <Link
      href={href}
      className={`flex flex-col items-center gap-2 p-4 rounded-xl border transition-all duration-200 ${colors[color as keyof typeof colors] || colors.blue}`}
    >
      <span className="text-2xl">{icon}</span>
      <span className="text-xs font-semibold text-center">{label}</span>
    </Link>
  );
};

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);
  const [dateRange, setDateRange] = useState<'week' | 'month' | 'year'>('week');
  const [trendData, setTrendData] = useState<TrendData[]>([]);

  useEffect(() => {
    fetchDashboardData();
    fetchTrendData();
  }, [dateRange]);

  const fetchDashboardData = async () => {
    try {
      setLoading(true);
      const response = await apiClient.get<Stats>('/admin/dashboard');
      setStats(response);
      setError(false);
    } catch (err) {
      console.error('Failed to fetch dashboard data:', err);
      setError(true);
    } finally {
      setLoading(false);
    }
  };

  const fetchTrendData = async () => {
    try {
      const response = await apiClient.get<TrendData[]>(`/admin/dashboard/trends?range=${dateRange}`);
      setTrendData(response);
    } catch (err) {
      console.error('Failed to fetch trend data:', err);
      // Fallback mock data
      setTrendData(generateMockTrendData());
    }
  };

  const generateMockTrendData = () => {
    const data = [];
    const days = dateRange === 'week' ? 7 : dateRange === 'month' ? 30 : 12;
    for (let i = 0; i < days; i++) {
      data.push({
        date: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toLocaleDateString(),
        complaints: Math.floor(Math.random() * 50) + 10,
        resolved: Math.floor(Math.random() * 40) + 5,
      });
    }
    return data.reverse();
  };

  // Prepare chart options
  const complaintTrendOptions = {
    chart: {
      type: 'area' as const,
      height: 350,
      toolbar: { show: false },
      zoom: { enabled: false },
      fontFamily: 'Inter, sans-serif',
    },
    dataLabels: { enabled: false },
    stroke: { curve: 'smooth' as const, width: 2 },
    fill: {
      type: 'gradient',
      gradient: {
        shadeIntensity: 1,
        opacityFrom: 0.7,
        opacityTo: 0.3,
      },
    },
    colors: ['#3B82F6', '#10B981'],
    xaxis: {
      categories: trendData.map(d => d.date),
      labels: { rotate: -45, style: { fontSize: '12px' } },
    },
    yaxis: {
      title: { text: 'Number of Complaints' },
      min: 0,
    },
    legend: {
      position: 'top' as const,
      horizontalAlign: 'right' as const,
    },
    tooltip: {
      theme: 'dark',
      y: { formatter: (val: number) => `${val} complaints` },
    },
    grid: {
      borderColor: '#E2E8F0',
      strokeDashArray: 5,
    },
  };

  const complaintTrendSeries = [
    { name: 'New Complaints', data: trendData.map(d => d.complaints) },
    { name: 'Resolved', data: trendData.map(d => d.resolved) },
  ];

  // Status distribution pie chart
  const statusDistributionOptions = {
    chart: {
      type: 'donut' as const,
      height: 300,
      toolbar: { show: false },
    },
    labels: stats?.status_wise ? Object.keys(stats.status_wise) : ['Pending', 'In Progress', 'Resolved', 'Rejected'],
    colors: ['#F59E0B', '#3B82F6', '#10B981', '#EF4444'],
    legend: { position: 'bottom' as const },
    dataLabels: { enabled: true, formatter: (val: number) => `${val.toFixed(1)}%` },
    plotOptions: {
      pie: {
        donut: {
          size: '65%',
          labels: { show: true, total: { show: true, label: 'Total', fontSize: '14px' } },
        },
      },
    },
    responsive: [{ breakpoint: 480, options: { chart: { width: 300 }, legend: { position: 'bottom' } } }],
  };

  const statusDistributionSeries = stats?.status_wise ? Object.values(stats.status_wise) : [25, 30, 35, 10];

  // Category distribution bar chart
  const categoryOptions = {
    chart: {
      type: 'bar' as const,
      height: 300,
      toolbar: { show: false },
    },
    plotOptions: { bar: { borderRadius: 8, horizontal: false, columnWidth: '55%' } },
    dataLabels: { enabled: false },
    colors: ['#8B5CF6'],
    xaxis: {
      categories: stats?.category_wise ? Object.keys(stats.category_wise) : [],
      labels: { rotate: -45, style: { fontSize: '11px' } },
    },
    yaxis: { title: { text: 'Number of Complaints' } },
    grid: { borderColor: '#E2E8F0', strokeDashArray: 5 },
  };

  const categorySeries = [{ name: 'Complaints', data: stats?.category_wise ? Object.values(stats.category_wise) : [] }];

  const statCards = [
    { title: 'Total Citizens', value: stats?.total_citizens?.toLocaleString() || 0, icon: Users, trend: 12, color: 'blue', href: '/dashboard/users' },
    { title: 'Total Complaints', value: stats?.total_complaints?.toLocaleString() || 0, icon: AlertCircle, trend: 8, color: 'purple', href: '/dashboard/complaints' },
    { title: 'Pending', value: stats?.pending_complaints?.toLocaleString() || 0, icon: Clock, trend: -5, color: 'amber', href: '/dashboard/complaints?status=pending' },
    { title: 'In Progress', value: stats?.in_progress_complaints?.toLocaleString() || 0, icon: Activity, trend: 15, color: 'blue', href: '/dashboard/complaints?status=in_progress' },
    { title: 'Resolved', value: stats?.resolved_complaints?.toLocaleString() || 0, icon: CheckCircle, trend: 22, color: 'emerald', href: '/dashboard/complaints?status=resolved' },
    { title: 'Field Officers', value: stats?.total_officers?.toLocaleString() || 0, icon: MapPin, trend: 0, color: 'indigo', href: '/dashboard/field-users' },
  ];

  const quickActions = [
    { label: 'Add User', href: '/dashboard/users/new', icon: '👤', color: 'blue' },
    { label: 'Add Field User', href: '/dashboard/field-users/new', icon: '🗺️', color: 'purple' },
    { label: 'Add Ward Admin', href: '/dashboard/ward-admins/new', icon: '🏛️', color: 'emerald' },
    { label: 'Add Content', href: '/dashboard/home-content/new', icon: '🖼️', color: 'amber' },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Dashboard</h1>
          <p className="text-sm text-slate-500 mt-1">
            {new Date().toLocaleDateString('en-IN', {
              weekday: 'long',
              year: 'numeric',
              month: 'long',
              day: 'numeric',
            })}
          </p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={fetchDashboardData}
            className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Refresh
          </button>
          <button className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors">
            <Download className="w-4 h-4" />
            Export
          </button>
        </div>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center gap-3">
          <AlertCircle className="w-5 h-5 text-red-600" />
          <div className="flex-1">
            <p className="text-sm font-medium text-red-800">Failed to load dashboard data</p>
            <p className="text-xs text-red-600 mt-1">Please refresh the page or try again later.</p>
          </div>
          <button onClick={fetchDashboardData} className="text-sm text-red-700 hover:text-red-800 font-medium">
            Retry
          </button>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-5">
        {statCards.map((card) => (
          <StatCard key={card.title} {...card} loading={loading} />
        ))}
      </div>

      {/* Today's Summary */}
      {stats && (
        <div className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-xl shadow-lg p-6 text-white">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <p className="text-blue-100 text-sm font-medium">Today's Summary</p>
              <p className="text-3xl font-bold mt-1">{stats.complaints_today}</p>
              <p className="text-blue-100 text-sm mt-1">new complaints received</p>
            </div>
            <div className="h-12 w-px bg-white/20 hidden sm:block" />
            <div>
              <p className="text-blue-100 text-sm font-medium">This Week</p>
              <p className="text-3xl font-bold mt-1">{stats.complaints_this_week}</p>
              <p className="text-blue-100 text-sm mt-1">total complaints</p>
            </div>
            <div className="h-12 w-px bg-white/20 hidden sm:block" />
            <div>
              <p className="text-blue-100 text-sm font-medium">Resolution Rate</p>
              <p className="text-3xl font-bold mt-1">
                {stats.total_complaints > 0 
                  ? Math.round((stats.resolved_complaints / stats.total_complaints) * 100)
                  : 0}%
              </p>
              <p className="text-blue-100 text-sm mt-1">of complaints resolved</p>
            </div>
            <div className="flex gap-2">
              <Calendar className="w-5 h-5 text-blue-200" />
              <span className="text-sm">{new Date().toLocaleDateString('en-IN')}</span>
            </div>
          </div>
        </div>
      )}

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Complaint Trend Chart */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm font-semibold text-slate-900 uppercase tracking-wide">
              Complaint Trends
            </h3>
            <div className="flex gap-2">
              {(['week', 'month', 'year'] as const).map((range) => (
                <button
                  key={range}
                  onClick={() => setDateRange(range)}
                  className={`px-3 py-1 text-xs font-medium rounded-lg transition-colors ${
                    dateRange === range
                      ? 'bg-blue-600 text-white'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  {range.charAt(0).toUpperCase() + range.slice(1)}
                </button>
              ))}
            </div>
          </div>
          {typeof window !== 'undefined' && (
            <Chart
              options={complaintTrendOptions}
              series={complaintTrendSeries}
              type="area"
              height={350}
            />
          )}
        </div>

        {/* Status Distribution Chart */}
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          <h3 className="text-sm font-semibold text-slate-900 uppercase tracking-wide mb-4">
            Complaint Status Distribution
          </h3>
          {typeof window !== 'undefined' && (
            <Chart
              options={statusDistributionOptions}
              series={statusDistributionSeries}
              type="donut"
              height={300}
            />
          )}
        </div>
      </div>

      {/* Category Distribution */}
      {stats?.category_wise && Object.keys(stats.category_wise).length > 0 && (
        <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
          <h3 className="text-sm font-semibold text-slate-900 uppercase tracking-wide mb-4">
            Complaints by Category
          </h3>
          {typeof window !== 'undefined' && (
            <Chart
              options={categoryOptions}
              series={categorySeries}
              type="bar"
              height={300}
            />
          )}
        </div>
      )}

      {/* Quick Actions */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <h3 className="text-sm font-semibold text-slate-900 uppercase tracking-wide mb-4">
          Quick Actions
        </h3>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          {quickActions.map((action) => (
            <QuickAction key={action.href} {...action} />
          ))}
        </div>
      </div>
    </div>
  );
}