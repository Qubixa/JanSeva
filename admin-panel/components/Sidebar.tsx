'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuthStore } from '@/lib/auth-store';

interface NavItem {
  label: string;
  href: string;
  icon: string;
}

const Sidebar = () => {
  const pathname = usePathname();
  const router = useRouter();
  const { admin, logout } = useAuthStore();

  const navItems: NavItem[] = [
    { label: 'Dashboard', href: '/dashboard', icon: '📊' },
    { label: 'Users', href: '/dashboard/users', icon: '👥' },
    { label: 'Roles', href: '/dashboard/roles', icon: '🔐' },
    { label: 'Field Users', href: '/dashboard/field-users', icon: '🚶' },
    { label: 'Ward Admins', href: '/dashboard/ward-admins', icon: '🏛️' },
    { label: 'Home Content', href: '/dashboard/home-content', icon: '🏠' },
    { label: 'Civic Data', href: '/dashboard/civic-data', icon: '📋' },
    { label: 'Matrimonial Users', href: '/dashboard/matrimonial/users', icon: '💍' },
    { label: 'Matrimonial Agencies', href: '/dashboard/matrimonial/agencies', icon: '🏢' },
    { label: 'Matches', href: '/dashboard/matrimonial/matches', icon: '❤️' },
  ];

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  return (
    <aside className="w-64 bg-white shadow-lg flex flex-col h-screen">
      {/* Header */}
      <div className="p-6 border-b border-gray-200">
        <h1 className="text-2xl font-bold text-blue-600">JanSeva</h1>
        <p className="text-sm text-gray-600">Admin Panel</p>
      </div>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto p-4 space-y-2">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={`block px-4 py-3 rounded-lg transition-colors ${
              pathname === item.href
                ? 'bg-blue-50 text-blue-600 font-semibold border-l-4 border-blue-600'
                : 'text-gray-700 hover:bg-gray-50'
            }`}
          >
            <span className="inline-block mr-3">{item.icon}</span>
            {item.label}
          </Link>
        ))}
      </nav>

      {/* User Info & Logout */}
      <div className="border-t border-gray-200 p-4 space-y-4">
        <div className="px-4 py-3 bg-gray-50 rounded-lg">
          <p className="text-sm text-gray-600">Logged in as</p>
          <p className="font-semibold text-gray-900">{admin?.email}</p>
          <p className="text-xs text-gray-500 mt-1">Role: {admin?.role}</p>
        </div>
        <button
          onClick={handleLogout}
          className="w-full btn-secondary text-center"
        >
          Logout
        </button>
      </div>
    </aside>
  );
};

export default Sidebar;
