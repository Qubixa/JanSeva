'use client';

import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/lib/auth-store';

const navigation = [
  {
    group: 'Overview',
    items: [
      { label: 'Dashboard', href: '/dashboard', icon: '▦' },
    ],
  },
  {
    group: 'People',
    items: [
      { label: 'Users',       href: '/dashboard/users',       icon: '👤' },
      { label: 'Field Users', href: '/dashboard/field-users', icon: '🗺️' },
      { label: 'Ward Admins', href: '/dashboard/ward-admins', icon: '🏛️' },
      { label: 'Roles',       href: '/dashboard/roles',       icon: '🔑' },
    ],
  },
  {
    group: 'Matrimonial',
    items: [
      { label: 'Profiles',  href: '/dashboard/matrimonial/users',    icon: '💍' },
      { label: 'Agencies',  href: '/dashboard/matrimonial/agencies', icon: '🏢' },
    ],
  },
  {
    group: 'Content',
    items: [
      { label: 'Services', href: '/dashboard/services', icon: '🖼️' },
    ],
  },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const { admin, logout } = useAuthStore();

  const handleLogout = () => {
    logout();
    router.push('/login');
  };

  const isActive = (href: string) => {
    if (href === '/dashboard') return pathname === '/dashboard';
    return pathname.startsWith(href);
  };

  return (
    <aside
      className="flex flex-col h-screen bg-slate-900 text-white shrink-0"
      style={{ width: 'var(--sidebar-width)' }}
    >
      {/* Brand */}
      <div className="px-5 py-5 border-b border-white/10">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-blue-500 flex items-center justify-center text-lg font-black shadow-lg shadow-blue-500/30">
            J
          </div>
          <div>
            <p className="text-sm font-bold leading-none text-white">JanSeva</p>
            <p className="text-[10px] text-slate-400 mt-0.5 font-medium tracking-wide">ADMIN PORTAL</p>
          </div>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-6">
        {navigation.map((group) => (
          <div key={group.group}>
            <p className="nav-group-label">{group.group}</p>
            <ul className="space-y-0.5">
              {group.items.map((item) => (
                <li key={item.href}>
                  <Link
                    href={item.href}
                    className={`nav-item ${isActive(item.href) ? 'active' : ''}`}
                  >
                    <span className="text-base leading-none">{item.icon}</span>
                    <span>{item.label}</span>
                    {isActive(item.href) && (
                      <span className="ml-auto w-1.5 h-1.5 rounded-full bg-blue-400" />
                    )}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </nav>

      {/* User footer */}
      <div className="border-t border-white/10 px-3 py-4 space-y-1">
        {admin && (
          <div className="flex items-center gap-3 px-3 py-2 mb-2">
            <div className="w-8 h-8 rounded-full bg-blue-500/30 flex items-center justify-center text-sm font-bold text-blue-300 shrink-0">
              {admin.name?.[0]?.toUpperCase() ?? 'A'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-xs font-semibold text-white truncate">{admin.name ?? 'Admin'}</p>
              <p className="text-[10px] text-slate-400 truncate">{admin.email ?? ''}</p>
            </div>
          </div>
        )}
        <button
          onClick={handleLogout}
          className="w-full nav-item text-red-400 hover:text-red-300 hover:bg-red-500/10"
        >
          <span>⎋</span>
          <span>Sign out</span>
        </button>
      </div>
    </aside>
  );
}