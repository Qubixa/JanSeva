'use client';

import { usePathname, useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/lib/auth-store';
import {
  LayoutDashboard,
  Users,
  MapPin,
  Building2,
  Heart,
  Briefcase,
  FileText,
  LogOut,
  Menu,
  X,
  Shield,
  TrendingUp,
  PlusCircle,
  ChevronRight,
} from 'lucide-react';
import { useState, useEffect } from 'react';

// Navigation configuration with proper typing
interface NavItem {
  label: string;
  href: string;
  icon: React.ElementType;
  badge?: number;
  requiredPermissions?: string[];
}

interface NavGroup {
  group: string;
  items: NavItem[];
}

const navigation: NavGroup[] = [
  {
    group: 'Overview',
    items: [
      { 
        label: 'Dashboard', 
        href: '/dashboard', 
        icon: LayoutDashboard,
      },
    ],
  },
  {
    group: 'People Management',
    items: [
      { 
        label: 'Users', 
        href: '/dashboard/users', 
        icon: Users,
        // requiredPermissions: ['users:read']
      },
      { 
        label: 'Field Users', 
        href: '/dashboard/field-users', 
        icon: MapPin,
        // requiredPermissions: ['field_users:read']
      },
      { 
        label: 'Ward Admins', 
        href: '/dashboard/ward-admins', 
        icon: Building2,
        // requiredPermissions: ['ward_admins:read']
      },
      { 
        label: 'Roles & Permissions', 
        href: '/dashboard/roles', 
        icon: Shield,
        // requiredPermissions: ['roles:read']
      },
    ],
  },
  {
    group: 'Complaint Management',
    items: [
      { 
        label: 'Complaints', 
        href: '/dashboard/complaints', 
        icon: FileText,
        badge: 12,
      },
    ],
  },
  {
    group: 'Matrimonial Services',
    items: [
      { 
        label: 'Member Profiles', 
        href: '/dashboard/matrimonial/users', 
        icon: Heart,
      },
      { 
        label: 'Agencies', 
        href: '/dashboard/matrimonial/agencies', 
        icon: Building2,
      },
    ],
  },
  {
    group: 'Content Management',
    items: [
      { 
        label: 'Services', 
        href: '/dashboard/services', 
        icon: Briefcase,
      },
    ],
  },
];

// Collapsed state management
const SIDEBAR_STORAGE_KEY = 'sidebar-collapsed';

interface SidebarProps {
  onToggle?: (collapsed: boolean) => void;
}

export default function Sidebar({ onToggle }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { admin, logout, permissions } = useAuthStore();
  const [isCollapsed, setIsCollapsed] = useState(false);
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const [hoveredItem, setHoveredItem] = useState<string | null>(null);

  // Load collapsed state from localStorage
  useEffect(() => {
    const saved = localStorage.getItem(SIDEBAR_STORAGE_KEY);
    if (saved !== null) {
      setIsCollapsed(saved === 'true');
    }
  }, []);

  // Save collapsed state
  const toggleCollapse = () => {
    const newState = !isCollapsed;
    setIsCollapsed(newState);
    localStorage.setItem(SIDEBAR_STORAGE_KEY, String(newState));
    onToggle?.(newState);
  };

  // Mobile menu handlers
  const toggleMobile = () => setIsMobileOpen(!isMobileOpen);
  const closeMobile = () => setIsMobileOpen(false);

  // Handle logout
   const handleLogout = () => {
    try {
      logout(); // This clears cookies and state
      router.push('/login');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  // Handle new user
  const handleNewUser = () => {
    router.push('/dashboard/users/new');
    closeMobile();
  };

  // Check if user has required permissions
  const hasPermission = (requiredPermissions?: string[]): boolean => {
    if (!requiredPermissions || requiredPermissions.length === 0) return true;
    if (!permissions) return false;
    return requiredPermissions.every(perm => permissions.includes(perm));
  };

  // Filter navigation based on permissions
  const filteredNavigation = navigation.map(group => ({
    ...group,
    items: group.items.filter(item => hasPermission(item.requiredPermissions))
  })).filter(group => group.items.length > 0);

  const isActive = (href: string) => {
    if (href === '/dashboard') return pathname === '/dashboard';
    return pathname.startsWith(href);
  };

  return (
    <>
      {/* Mobile Overlay */}
      {isMobileOpen && (
        <div 
          className="fixed inset-0 bg-black/50 backdrop-blur-sm z-40 lg:hidden"
          onClick={closeMobile}
        />
      )}

      {/* Mobile Toggle Button */}
      <button
        onClick={toggleMobile}
        className="fixed top-4 left-4 z-50 p-2 rounded-lg bg-white shadow-lg lg:hidden"
        aria-label="Toggle menu"
      >
        {isMobileOpen ? <X size={20} /> : <Menu size={20} />}
      </button>

      {/* Sidebar */}
      <aside
        className={`
          fixed lg:sticky top-0 left-0 z-40
          flex flex-col h-screen bg-gradient-to-b from-slate-900 to-slate-800 text-white
          transition-all duration-300 ease-in-out shadow-2xl
          ${isCollapsed ? 'w-20' : 'w-72'}
          ${isMobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
        `}
      >
        {/* Header Section */}
        <div className={`
          relative px-4 py-5 border-b border-white/10
          ${isCollapsed ? 'px-2' : 'px-5'}
        `}>
          <div className="flex items-center gap-3">
            <div className="relative group">
              <div className="absolute inset-0 bg-blue-500 rounded-xl blur-lg opacity-75 group-hover:opacity-100 transition-opacity" />
              <div className="relative w-10 h-10 rounded-xl bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center text-white font-bold text-xl shadow-lg">
                JS
              </div>
            </div>
            
            {!isCollapsed && (
              <div className="flex-1">
                <p className="text-sm font-bold leading-none text-white tracking-wide">
                  JanSeva
                </p>
                <p className="text-[10px] text-blue-300 mt-0.5 font-medium tracking-wider">
                  ENTERPRISE PORTAL
                </p>
              </div>
            )}
          </div>

          {/* Collapse Toggle (Desktop only) */}
          <button
            onClick={toggleCollapse}
            className={`
              absolute -right-3 top-1/2 -translate-y-1/2
              hidden lg:flex items-center justify-center
              w-6 h-6 rounded-full bg-slate-700 border border-white/20
              text-white hover:bg-slate-600 transition-all
              ${isCollapsed ? 'rotate-180' : ''}
            `}
            aria-label={isCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            <ChevronRight size={14} />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto overflow-x-hidden py-6 scrollbar-thin scrollbar-track-white/5 scrollbar-thumb-white/20">
          <div className="space-y-6">
            {filteredNavigation.map((group) => (
              <div key={group.group}>
                {!isCollapsed && (
                  <div className="px-5 mb-2">
                    <p className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                      {group.group}
                    </p>
                  </div>
                )}
                <ul className="space-y-1">
                  {group.items.map((item) => {
                    const Icon = item.icon;
                    const active = isActive(item.href);
                    
                    return (
                      <li key={item.href}>
                        <Link
                          href={item.href}
                          onClick={closeMobile}
                          onMouseEnter={() => setHoveredItem(item.href)}
                          onMouseLeave={() => setHoveredItem(null)}
                          className={`
                            relative flex items-center gap-3 mx-2 px-3 py-2.5
                            rounded-xl transition-all duration-200 group
                            ${active 
                              ? 'bg-blue-500/20 text-blue-300 shadow-lg shadow-blue-500/10' 
                              : 'text-slate-300 hover:bg-white/5 hover:text-white'
                            }
                            ${isCollapsed ? 'justify-center' : ''}
                          `}
                        >
                          <Icon 
                            size={20} 
                            className={`
                              transition-transform duration-200
                              ${active ? 'scale-110' : 'group-hover:scale-105'}
                            `}
                          />
                          
                          {!isCollapsed && (
                            <>
                              <span className="flex-1 text-sm font-medium">
                                {item.label}
                              </span>
                              {item.badge && (
                                <span className="px-1.5 py-0.5 text-[10px] font-bold rounded-full bg-red-500 text-white">
                                  {item.badge}
                                </span>
                              )}
                              {active && (
                                <div className="absolute left-0 w-1 h-6 bg-blue-400 rounded-r-full" />
                              )}
                            </>
                          )}

                          {/* Tooltip for collapsed mode */}
                          {isCollapsed && (
                            <div className={`
                              absolute left-full ml-2 px-2 py-1
                              bg-slate-800 text-white text-xs rounded
                              whitespace-nowrap z-50 pointer-events-none
                              transition-opacity duration-200
                              ${hoveredItem === item.href ? 'opacity-100' : 'opacity-0'}
                            `}>
                              {item.label}
                              {item.badge && (
                                <span className="ml-1 px-1 bg-red-500 rounded text-[9px]">
                                  {item.badge}
                                </span>
                              )}
                            </div>
                          )}
                        </Link>
                      </li>
                    );
                  })}
                  
                  {/* Add New User Button - Only show in People Management group */}
                  {group.group === 'People Management' && hasPermission(['users:create']) && (
                    <li>
                      <button
                        onClick={handleNewUser}
                        onMouseEnter={() => setHoveredItem('new-user')}
                        onMouseLeave={() => setHoveredItem(null)}
                        className={`
                          relative flex items-center gap-3 mx-2 px-3 py-2.5
                          rounded-xl transition-all duration-200 group
                          text-emerald-400 hover:text-emerald-300 hover:bg-emerald-500/10
                          ${isCollapsed ? 'justify-center' : ''}
                        `}
                      >
                        <PlusCircle size={20} />
                        {!isCollapsed && (
                          <span className="flex-1 text-sm font-medium">Add New User</span>
                        )}
                        
                        {/* Tooltip for collapsed mode */}
                        {isCollapsed && (
                          <div className={`
                            absolute left-full ml-2 px-2 py-1
                            bg-slate-800 text-white text-xs rounded
                            whitespace-nowrap z-50 pointer-events-none
                            transition-opacity duration-200
                            ${hoveredItem === 'new-user' ? 'opacity-100' : 'opacity-0'}
                          `}>
                            Add New User
                          </div>
                        )}
                      </button>
                    </li>
                  )}
                </ul>
              </div>
            ))}
          </div>
        </nav>

        {/* Bottom Section */}
        <div className="border-t border-white/10 p-3 space-y-2">
          {/* Quick Stats (Collapsed only) */}
          {isCollapsed && (
            <div className="flex justify-center py-2">
              <div className="w-8 h-8 rounded-full bg-emerald-500/20 flex items-center justify-center">
                <TrendingUp size={14} className="text-emerald-400" />
              </div>
            </div>
          )}

          {/* User Profile */}
          {admin && (
            <div className={`
              flex items-center gap-3 p-2 rounded-xl transition-colors
              ${!isCollapsed && 'hover:bg-white/5'}
            `}>
              <div className="relative shrink-0">
                <div className="w-9 h-9 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-bold text-sm shadow-lg">
                  {admin.name?.[0]?.toUpperCase() ?? 'A'}
                </div>
                <div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-green-500 rounded-full border-2 border-slate-900" />
              </div>
              
              {!isCollapsed && (
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold text-white truncate">
                    {admin.name ?? 'Administrator'}
                  </p>
                  <p className="text-[10px] text-slate-400 truncate">
                    {admin.email ?? 'admin@janseva.gov'}
                  </p>
                </div>
              )}
            </div>
          )}

          {/* Actions */}
          <div className="space-y-1">
            <button
              onClick={handleLogout}
              className={`
                w-full flex items-center gap-3 px-3 py-2
                text-red-400 hover:text-red-300 hover:bg-red-500/10
                rounded-xl transition-all duration-200 group
                ${isCollapsed ? 'justify-center' : ''}
              `}
            >
              <LogOut size={18} className="group-hover:translate-x-0.5 transition-transform" />
              {!isCollapsed && <span className="text-sm font-medium">Sign Out</span>}
            </button>
          </div>

          {/* Version Info */}
          {!isCollapsed && (
            <div className="pt-2 px-3">
              <p className="text-[9px] text-slate-500 text-center">
                Version 2.0.0 | © 2024 JanSeva
              </p>
            </div>
          )}
        </div>
      </aside>
    </>
  );
}