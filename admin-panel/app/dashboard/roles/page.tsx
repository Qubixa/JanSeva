'use client';

const SYSTEM_ROLES = [
  {
    id: 'SUPER_ADMIN',
    label: 'Super Admin',
    initials: 'SA',
    description: 'Full system access across all wards',
    color: 'amber',
    permissions: [
      'Manage all users',
      'Manage all wards',
      'Create/edit home content',
      'View all complaints',
      'Manage field users & ward admins',
      'System settings',
    ],
  },
  {
    id: 'WARD_ADMIN',
    label: 'Ward Admin',
    initials: 'WA',
    description: 'Manages a single ward\'s operations',
    color: 'blue',
    permissions: [
      'Manage ward users',
      'Assign complaints to officers',
      'Ward-level home content',
      'View ward statistics',
      'Manage emergency services',
    ],
  },
  {
    id: 'FIELD_OFFICER',
    label: 'Field Officer',
    initials: 'FO',
    description: 'Handles complaint resolution on ground',
    color: 'green',
    permissions: [
      'View assigned complaints',
      'Update complaint status',
      'Upload resolution proof',
    ],
  },
  {
    id: 'CITIZEN',
    label: 'Citizen',
    initials: 'CI',
    description: 'Registered app user from a ward',
    color: 'gray',
    permissions: [
      'File complaints',
      'Track complaint status',
      'View home content',
      'View schemes & services',
    ],
  },
];

const COLOR_MAP: Record<string, { bg: string; text: string; badge: string; badgeText: string }> = {
  amber: {
    bg: 'bg-amber-50',
    text: 'text-amber-700',
    badge: 'bg-amber-100',
    badgeText: 'text-amber-700',
  },
  blue: {
    bg: 'bg-blue-50',
    text: 'text-blue-700',
    badge: 'bg-blue-100',
    badgeText: 'text-blue-700',
  },
  green: {
    bg: 'bg-green-50',
    text: 'text-green-700',
    badge: 'bg-green-100',
    badgeText: 'text-green-700',
  },
  gray: {
    bg: 'bg-slate-100',
    text: 'text-slate-600',
    badge: 'bg-slate-100',
    badgeText: 'text-slate-600',
  },
};

export default function RolesPage() {
  return (
    <div className="space-y-6">
      <div className="page-header">
        <div>
          <h1 className="page-title">Roles & Permissions</h1>
          <p className="page-subtitle">
            Built-in system roles — assign roles when creating users
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {SYSTEM_ROLES.map((role) => {
          const c = COLOR_MAP[role.color];
          return (
            <div
              key={role.id}
              className="card hover:border-slate-200 hover:shadow-sm transition-all"
            >
              {/* Header */}
              <div className="flex items-center gap-3 mb-4">
                <div
                  className={`w-10 h-10 rounded-full ${c.bg} ${c.text} flex items-center justify-center text-sm font-semibold shrink-0`}
                >
                  {role.initials}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-semibold text-slate-900 text-sm">{role.label}</h3>
                    <span
                      className={`text-[10px] font-bold px-2 py-0.5 rounded ${c.badge} ${c.badgeText}`}
                    >
                      {role.id}
                    </span>
                  </div>
                  <p className="text-xs text-slate-500 mt-0.5">{role.description}</p>
                </div>
              </div>

              {/* Permissions */}
              <div>
                <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wide mb-2">
                  Permissions
                </p>
                <div className="flex flex-wrap gap-1.5">
                  {role.permissions.map((perm) => (
                    <span
                      key={perm}
                      className="text-[11px] bg-slate-50 border border-slate-100 text-slate-600 px-2 py-1 rounded-lg"
                    >
                      {perm}
                    </span>
                  ))}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="card bg-blue-50 border-blue-100">
        <p className="text-sm text-blue-800 font-medium">
          💡 To assign a role, go to{' '}
          <a href="/dashboard/users/new" className="underline font-semibold">
            Users → Add User
          </a>{' '}
          and select the appropriate role from the dropdown.
        </p>
      </div>
    </div>
  );
}