'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';
import {
  Plus,
  Search,
  Edit,
  Trash2,
  Eye,
  ChevronLeft,
  ChevronRight,
  Filter,
  Download,
  RefreshCw,
  UserCheck,
  UserX,
  Mail,
  Phone,
  MapPin,
  Calendar,
  AlertCircle,
  X,
  Save,
  UserPlus,
  Shield,
  CheckCircle,
  XCircle,
  Loader2,
  Upload,
} from 'lucide-react';

// Types matching backend
interface User {
  id: number;
  name: string;
  email: string | null;
  mobile: string;
  role: 'CITIZEN' | 'FIELD_OFFICER' | 'WARD_ADMIN' | 'SUPER_ADMIN';
  ward_id: number;
  ward_name: string | null;
  address: string;
  profile_image: string | null;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
  updated_at: string;
}

interface Ward {
  id: number;
  name: string;
  ward_number: string;
}

interface UserListResponse {
  users: User[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

// Role badge component
const RoleBadge = ({ role }: { role: User['role'] }) => {
  const styles = {
    SUPER_ADMIN: 'bg-purple-100 text-purple-800 border-purple-200',
    WARD_ADMIN: 'bg-blue-100 text-blue-800 border-blue-200',
    FIELD_OFFICER: 'bg-green-100 text-green-800 border-green-200',
    CITIZEN: 'bg-gray-100 text-gray-800 border-gray-200',
  };

  const labels = {
    SUPER_ADMIN: 'Super Admin',
    WARD_ADMIN: 'Ward Admin',
    FIELD_OFFICER: 'Field Officer',
    CITIZEN: 'Citizen',
  };

  return (
    <span className={`px-2 py-1 text-xs font-medium rounded-full ${styles[role]}`}>
      {labels[role]}
    </span>
  );
};

// Status badge component
const StatusBadge = ({ is_active, is_verified }: { is_active: boolean; is_verified: boolean }) => {
  if (!is_active) {
    return <span className="px-2 py-1 text-xs font-medium rounded-full bg-red-100 text-red-800">Inactive</span>;
  }
  if (!is_verified) {
    return <span className="px-2 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800">Pending</span>;
  }
  return <span className="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">Active</span>;
};

// Modal Component
const Modal = ({ title, children, onClose }: { title: string; children: React.ReactNode; onClose: () => void }) => {
  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white border-b border-slate-200 px-6 py-4 flex items-center justify-between">
          <h2 className="text-xl font-semibold text-slate-900">{title}</h2>
          <button onClick={onClose} className="p-1 hover:bg-slate-100 rounded-lg transition-colors">
            <X className="w-5 h-5 text-slate-500" />
          </button>
        </div>
        <div className="p-6">{children}</div>
      </div>
    </div>
  );
};

// Toast notification component
const Toast = ({ message, type, onClose }: { message: string; type: 'success' | 'error' | 'info'; onClose: () => void }) => {
  useEffect(() => {
    const timer = setTimeout(onClose, 5000);
    return () => clearTimeout(timer);
  }, [onClose]);

  const styles = {
    success: 'bg-green-600 text-white',
    error: 'bg-red-600 text-white',
    info: 'bg-blue-600 text-white',
  };

  const icons = {
    success: <CheckCircle className="w-4 h-4" />,
    error: <XCircle className="w-4 h-4" />,
    info: <AlertCircle className="w-4 h-4" />,
  };

  return (
    <div className={`fixed bottom-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg flex items-center gap-2 ${styles[type]}`}>
      {icons[type]}
      <span className="text-sm">{message}</span>
      <button onClick={onClose} className="ml-4 text-white/80 hover:text-white">×</button>
    </div>
  );
};

// Add/Edit User Modal
const UserFormModal = ({ user, wards, onSave, onClose }: { 
  user?: User | null; 
  wards: Ward[]; 
  onSave: (data: any) => Promise<void>; 
  onClose: () => void;
}) => {
  const [formData, setFormData] = useState({
    name: user?.name || '',
    mobile: user?.mobile || '',
    email: user?.email || '',
    role: user?.role || 'CITIZEN',
    ward_id: user?.ward_id || wards[0]?.id || '',
    address: user?.address || '',
    password: '',
    confirm_password: '',
    is_active: user?.is_active ?? true,
    is_verified: user?.is_verified ?? true,
  });
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  const validate = () => {
    const newErrors: Record<string, string> = {};
    if (!formData.name.trim()) newErrors.name = 'Name is required';
    if (!formData.mobile.trim()) newErrors.mobile = 'Mobile number is required';
    if (formData.mobile && !/^[0-9]{10}$/.test(formData.mobile)) newErrors.mobile = 'Invalid mobile number';
    if (formData.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) newErrors.email = 'Invalid email format';
    if (!user && !formData.password) newErrors.password = 'Password is required for new users';
    if (formData.password && formData.password.length < 6) newErrors.password = 'Password must be at least 6 characters';
    if (formData.password !== formData.confirm_password) newErrors.confirm_password = 'Passwords do not match';
    if (!formData.ward_id) newErrors.ward_id = 'Ward is required';
    if (!formData.address.trim()) newErrors.address = 'Address is required';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;
    
    setLoading(true);
    try {
      const submitData = { ...formData };
      delete submitData.confirm_password;
      if (!submitData.password) delete submitData.password;
      await onSave(submitData);
      onClose();
    } catch (error: any) {
      setErrors({ submit: error?.response?.data?.detail || 'Failed to save user' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {errors.submit && (
        <div className="p-3 bg-red-50 border border-red-200 rounded-lg text-red-600 text-sm">
          {errors.submit}
        </div>
      )}
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Full Name *</label>
          <input
            type="text"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 ${errors.name ? 'border-red-500' : 'border-slate-300'}`}
          />
          {errors.name && <p className="text-xs text-red-500 mt-1">{errors.name}</p>}
        </div>
        
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Mobile Number *</label>
          <input
            type="tel"
            value={formData.mobile}
            onChange={(e) => setFormData({ ...formData, mobile: e.target.value })}
            className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 ${errors.mobile ? 'border-red-500' : 'border-slate-300'}`}
          />
          {errors.mobile && <p className="text-xs text-red-500 mt-1">{errors.mobile}</p>}
        </div>
        
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Email</label>
          <input
            type="email"
            value={formData.email}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 ${errors.email ? 'border-red-500' : 'border-slate-300'}`}
          />
          {errors.email && <p className="text-xs text-red-500 mt-1">{errors.email}</p>}
        </div>
        
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Role *</label>
          <select
            value={formData.role}
            onChange={(e) => setFormData({ ...formData, role: e.target.value as any })}
            className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
          >
            <option value="CITIZEN">Citizen</option>
            <option value="FIELD_OFFICER">Field Officer</option>
            <option value="WARD_ADMIN">Ward Admin</option>
            <option value="SUPER_ADMIN">Super Admin</option>
          </select>
        </div>
        
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Ward *</label>
          <select
            value={formData.ward_id}
            onChange={(e) => setFormData({ ...formData, ward_id: parseInt(e.target.value) })}
            className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 ${errors.ward_id ? 'border-red-500' : 'border-slate-300'}`}
          >
            <option value="">Select Ward</option>
            {wards.map((ward) => (
              <option key={ward.id} value={ward.id}>
                {ward.name} ({ward.ward_number})
              </option>
            ))}
          </select>
          {errors.ward_id && <p className="text-xs text-red-500 mt-1">{errors.ward_id}</p>}
        </div>
        
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-1">Password {!user && '*'}</label>
          <input
            type="password"
            value={formData.password}
            onChange={(e) => setFormData({ ...formData, password: e.target.value })}
            className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 ${errors.password ? 'border-red-500' : 'border-slate-300'}`}
            placeholder={user ? 'Leave blank to keep unchanged' : 'Enter password'}
          />
          {errors.password && <p className="text-xs text-red-500 mt-1">{errors.password}</p>}
        </div>
        
        {formData.password && (
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Confirm Password</label>
            <input
              type="password"
              value={formData.confirm_password}
              onChange={(e) => setFormData({ ...formData, confirm_password: e.target.value })}
              className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 ${errors.confirm_password ? 'border-red-500' : 'border-slate-300'}`}
            />
            {errors.confirm_password && <p className="text-xs text-red-500 mt-1">{errors.confirm_password}</p>}
          </div>
        )}
      </div>
      
      <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">Address *</label>
        <textarea
          value={formData.address}
          onChange={(e) => setFormData({ ...formData, address: e.target.value })}
          rows={2}
          className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 ${errors.address ? 'border-red-500' : 'border-slate-300'}`}
        />
        {errors.address && <p className="text-xs text-red-500 mt-1">{errors.address}</p>}
      </div>
      
      <div className="flex gap-4">
        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            checked={formData.is_active}
            onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
            className="rounded border-slate-300"
          />
          <span className="text-sm text-slate-700">Active</span>
        </label>
        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            checked={formData.is_verified}
            onChange={(e) => setFormData({ ...formData, is_verified: e.target.checked })}
            className="rounded border-slate-300"
          />
          <span className="text-sm text-slate-700">Verified</span>
        </label>
      </div>
      
      <div className="flex gap-3 justify-end pt-4">
        <button type="button" onClick={onClose} className="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200">
          Cancel
        </button>
        <button type="submit" disabled={loading} className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center gap-2">
          {loading && <Loader2 className="w-4 h-4 animate-spin" />}
          {loading ? 'Saving...' : user ? 'Update User' : 'Create User'}
        </button>
      </div>
    </form>
  );
};

// View User Modal
const ViewUserModal = ({ user, onClose }: { user: User; onClose: () => void }) => {
  return (
    <div className="space-y-4">
      <div className="flex items-center gap-4 pb-4 border-b border-slate-200">
        <div className="w-20 h-20 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white text-2xl font-bold">
          {user.name?.[0]?.toUpperCase() ?? '?'}
        </div>
        <div>
          <h3 className="text-xl font-semibold text-slate-900">{user.name}</h3>
          <p className="text-slate-500">ID: {user.id}</p>
          <RoleBadge role={user.role} />
        </div>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label className="text-xs font-medium text-slate-500 uppercase">Mobile</label>
          <p className="text-slate-900 flex items-center gap-2 mt-1">
            <Phone className="w-4 h-4 text-slate-400" />
            {user.mobile}
          </p>
        </div>
        <div>
          <label className="text-xs font-medium text-slate-500 uppercase">Email</label>
          <p className="text-slate-900 flex items-center gap-2 mt-1">
            <Mail className="w-4 h-4 text-slate-400" />
            {user.email || 'Not provided'}
          </p>
        </div>
        <div>
          <label className="text-xs font-medium text-slate-500 uppercase">Ward</label>
          <p className="text-slate-900 flex items-center gap-2 mt-1">
            <MapPin className="w-4 h-4 text-slate-400" />
            {user.ward_name || `Ward ${user.ward_id}`}
          </p>
        </div>
        <div>
          <label className="text-xs font-medium text-slate-500 uppercase">Status</label>
          <div className="mt-1">
            <StatusBadge is_active={user.is_active} is_verified={user.is_verified} />
          </div>
        </div>
        <div className="md:col-span-2">
          <label className="text-xs font-medium text-slate-500 uppercase">Address</label>
          <p className="text-slate-900 mt-1">{user.address}</p>
        </div>
        <div>
          <label className="text-xs font-medium text-slate-500 uppercase">Joined</label>
          <p className="text-slate-900 flex items-center gap-2 mt-1">
            <Calendar className="w-4 h-4 text-slate-400" />
            {new Date(user.created_at).toLocaleDateString('en-IN', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
              hour: '2-digit',
              minute: '2-digit',
            })}
          </p>
        </div>
        <div>
          <label className="text-xs font-medium text-slate-500 uppercase">Last Updated</label>
          <p className="text-slate-900 mt-1">
            {new Date(user.updated_at).toLocaleDateString('en-IN', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
            })}
          </p>
        </div>
      </div>
      
      <div className="flex gap-3 justify-end pt-4 border-t border-slate-200">
        <button onClick={onClose} className="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200">
          Close
        </button>
      </div>
    </div>
  );
};

// Delete Confirmation Modal
const DeleteConfirmModal = ({ user, onConfirm, onClose }: { user: User | null; onConfirm: () => void; onClose: () => void }) => {
  const [loading, setLoading] = useState(false);
  
  if (!user) return null;

  const handleConfirm = async () => {
    setLoading(true);
    await onConfirm();
    setLoading(false);
  };

  return (
    <Modal title="Delete User" onClose={onClose}>
      <div className="text-center">
        <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-red-100 flex items-center justify-center">
          <AlertCircle className="w-8 h-8 text-red-600" />
        </div>
        <h3 className="text-lg font-semibold text-slate-900 mb-2">Delete User</h3>
        <p className="text-slate-600 mb-2">
          Are you sure you want to delete <span className="font-semibold">{user.name}</span>?
        </p>
        <p className="text-sm text-slate-500 mb-6">
          This action cannot be undone. All associated data will be permanently removed.
        </p>
        <div className="flex gap-3 justify-center">
          <button onClick={onClose} className="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200">
            Cancel
          </button>
          <button onClick={handleConfirm} disabled={loading} className="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 disabled:opacity-50 flex items-center gap-2">
            {loading && <Loader2 className="w-4 h-4 animate-spin" />}
            {loading ? 'Deleting...' : 'Delete User'}
          </button>
        </div>
      </div>
    </Modal>
  );
};


const ImportModal = ({ onClose, onImport, onDownloadTemplate, importing, file, setFile, result }: any) => {
  return (
    <Modal title="Bulk Import Users" onClose={onClose}>
      <div className="space-y-4">
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
          <h4 className="text-sm font-semibold text-blue-900 mb-2">Instructions:</h4>
          <ul className="text-xs text-blue-800 space-y-1 list-disc list-inside">
            <li>Download the template file first</li>
            <li>Fill in user data (required: name, mobile, role, ward_id, address)</li>
            <li>Supported formats: .xlsx, .xls, .csv</li>
            <li>Maximum file size: 10MB</li>
            <li>Password defaults to "Welcome@123" if not provided</li>
          </ul>
        </div>

        <button
          onClick={onDownloadTemplate}
          className="w-full flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-blue-600 bg-blue-50 rounded-lg hover:bg-blue-100 transition-colors"
        >
          <Download className="w-4 h-4" />
          Download Template
        </button>

        <div className="border-2 border-dashed border-slate-300 rounded-lg p-6 text-center">
          <input
            type="file"
            accept=".xlsx,.xls,.csv"
            onChange={(e) => setFile(e.target.files?.[0] || null)}
            className="hidden"
            id="file-upload"
          />
          <label
            htmlFor="file-upload"
            className="cursor-pointer flex flex-col items-center gap-2"
          >
            <Upload className="w-8 h-8 text-slate-400" />
            <span className="text-sm text-slate-600">
              {file ? file.name : 'Click to select or drag and drop'}
            </span>
            <span className="text-xs text-slate-400">Supported: .xlsx, .xls, .csv (Max 10MB)</span>
          </label>
        </div>

        {result && (
          <div className="space-y-2">
            <div className={`p-3 rounded-lg ${result.failed_count === 0 ? 'bg-green-50 text-green-800' : 'bg-yellow-50 text-yellow-800'}`}>
              <p className="text-sm font-medium">Import Results:</p>
              <p className="text-sm">✅ Created: {result.created_count}</p>
              <p className="text-sm">❌ Failed: {result.failed_count}</p>
            </div>
            {result.errors && result.errors.length > 0 && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-3 max-h-40 overflow-y-auto">
                <p className="text-xs font-semibold text-red-800 mb-2">Errors:</p>
                {result.errors.slice(0, 5).map((err: any, idx: number) => (
                  <p key={idx} className="text-xs text-red-600">
                    Row {err.row}: {err.error}
                  </p>
                ))}
                {result.errors.length > 5 && (
                  <p className="text-xs text-red-600">...and {result.errors.length - 5} more errors</p>
                )}
              </div>
            )}
          </div>
        )}

        <div className="flex gap-3 justify-end pt-4">
          <button onClick={onClose} className="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200">
            Cancel
          </button>
          <button
            onClick={onImport}
            disabled={!file || importing}
            className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 flex items-center gap-2"
          >
            {importing && <Loader2 className="w-4 h-4 animate-spin" />}
            {importing ? 'Importing...' : 'Import Users'}
          </button>
        </div>
      </div>
    </Modal>
  );
};




export default function UsersPage() {
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);
  const [wards, setWards] = useState<Ward[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [pagination, setPagination] = useState({
    page: 1,
    pageSize: 10,
    total: 0,
    totalPages: 0,
  });
  const [roleFilter, setRoleFilter] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('');
  const [showFilters, setShowFilters] = useState(false);
  
  // Modal states
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showViewModal, setShowViewModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'info' } | null>(null);
  const [showImportModal, setShowImportModal] = useState(false);
const [importFile, setImportFile] = useState<File | null>(null);
const [importing, setImporting] = useState(false);
const [importResult, setImportResult] = useState<any>(null);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: pagination.page.toString(),
        page_size: pagination.pageSize.toString(),
        ...(search && { search }),
        ...(roleFilter && { role: roleFilter }),
        ...(statusFilter && { status: statusFilter }),
      });
      
      const response = await apiClient.get<UserListResponse>(`/admin/users?${params}`);
      setUsers(response.users);
      setPagination(prev => ({
        ...prev,
        total: response.total,
        totalPages: response.total_pages,
      }));
    } catch (error) {
      console.error('Failed to fetch users:', error);
      showToast('Failed to load users', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadTemplate = async () => {
  try {
    const response = await apiClient.get('/admin/users/bulk-template', { responseType: 'blob' });
    const url = window.URL.createObjectURL(new Blob([response]));
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', 'bulk_user_template.csv');
    document.body.appendChild(link);
    link.click();
    link.remove();
    showToast('Template downloaded successfully', 'success');
  } catch (error) {
    console.error('Failed to download template:', error);
    showToast('Failed to download template', 'error');
  }
};

const handleBulkImport = async () => {
  if (!importFile) {
    showToast('Please select a file', 'error');
    return;
  }

  setImporting(true);
  const formData = new FormData();
  formData.append('file', importFile);

  try {
    const response = await apiClient.post('/admin/users/bulk-import', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    setImportResult(response);
    showToast(response.message || 'Import completed', 'success');
    fetchUsers(); // Refresh user list
    setTimeout(() => {
      setShowImportModal(false);
      setImportFile(null);
      setImportResult(null);
    }, 3000);
  } catch (error: any) {
    showToast(error?.response?.data?.detail || 'Import failed', 'error');
  } finally {
    setImporting(false);
  }
};
  const fetchWards = async () => {
    try {
      const response = await apiClient.get<Ward[]>('/wards');
      setWards(response);
    } catch (error) {
      console.error('Failed to fetch wards:', error);
    }
  };

  useEffect(() => {
    fetchUsers();
    fetchWards();
  }, [pagination.page, pagination.pageSize, search, roleFilter, statusFilter]);

  const showToast = (message: string, type: 'success' | 'error' | 'info') => {
    setToast({ message, type });
  };

  const handleCreateUser = async (data: any) => {
    await apiClient.post('/admin/users', data);
    showToast('User created successfully', 'success');
    fetchUsers();
  };

  const handleUpdateUser = async (data: any) => {
    if (!selectedUser) return;
    await apiClient.put(`/admin/users/${selectedUser.id}`, data);
    showToast('User updated successfully', 'success');
    fetchUsers();
  };

  const handleDeleteUser = async () => {
    if (!selectedUser) return;
    try {
      await apiClient.delete(`/admin/users/${selectedUser.id}`);
      showToast('User deleted successfully', 'success');
      fetchUsers();
      setShowDeleteModal(false);
      setSelectedUser(null);
    } catch (error: any) {
      showToast(error?.response?.data?.detail || 'Failed to delete user', 'error');
    }
  };

  const handleToggleStatus = async (user: User) => {
    try {
      await apiClient.patch(`/admin/users/${user.id}/toggle-status`);
      showToast(`User ${user.is_active ? 'deactivated' : 'activated'} successfully`, 'success');
      fetchUsers();
    } catch (error: any) {
      showToast(error?.response?.data?.detail || 'Failed to update user status', 'error');
    }
  };

  const handleResendVerification = async (userId: number) => {
    try {
      await apiClient.post(`/admin/users/${userId}/resend-verification`);
      showToast('Verification sent successfully', 'success');
    } catch (error: any) {
      showToast(error?.response?.data?.detail || 'Failed to send verification', 'error');
    }
  };

  const handleExport = async () => {
    try {
      const response = await apiClient.get('/admin/users/export', { responseType: 'blob' });
      const url = window.URL.createObjectURL(new Blob([response]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `users_export_${new Date().toISOString()}.csv`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      showToast('Users exported successfully', 'success');
    } catch (error) {
      console.error('Failed to export users:', error);
      showToast('Failed to export users', 'error');
    }
  };



  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">User Management</h1>
          <p className="text-sm text-slate-500 mt-1">
            Manage system users, roles, and permissions
          </p>
        </div>
        <div className="flex gap-3">
  <button
    onClick={() => setShowImportModal(true)}
    className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors"
  >
    <Upload className="w-4 h-4" />
    Import
  </button>
  <button
    onClick={handleExport}
    className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors"
  >
    <Download className="w-4 h-4" />
    Export
  </button>
  <button
    onClick={() => setShowAddModal(true)}
    className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
  >
    <UserPlus className="w-4 h-4" />
    Add User
  </button>
</div>
      </div>

      {/* Search and Filters */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-4">
        <div className="flex flex-col sm:flex-row gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              placeholder="Search by name, email, or phone..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
          <button
            onClick={() => setShowFilters(!showFilters)}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 transition-colors"
          >
            <Filter className="w-4 h-4" />
            Filters
            {(roleFilter || statusFilter) && (
              <span className="ml-1 w-2 h-2 rounded-full bg-blue-600" />
            )}
          </button>
          <button
            onClick={fetchUsers}
            className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 rounded-lg hover:bg-slate-200 transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Refresh
          </button>
        </div>

        {showFilters && (
          <div className="mt-4 pt-4 border-t border-slate-200 flex flex-wrap gap-4">
            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Roles</option>
              <option value="SUPER_ADMIN">Super Admin</option>
              <option value="WARD_ADMIN">Ward Admin</option>
              <option value="FIELD_OFFICER">Field Officer</option>
              <option value="CITIZEN">Citizen</option>
            </select>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="pending">Pending Verification</option>
            </select>
          </div>
        )}
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        {loading ? (
          <div className="p-8 space-y-4">
            {[...Array(5)].map((_, i) => (
              <div key={i} className="animate-pulse">
                <div className="h-16 bg-slate-100 rounded-lg"></div>
              </div>
            ))}
          </div>
        ) : (
          <>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-slate-50 border-b border-slate-200">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">User</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Contact</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Role</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Ward</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">Joined</th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200">
                  {users.map((user) => (
                    <tr key={user.id} className="hover:bg-slate-50 transition-colors">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold">
                            {user.name?.[0]?.toUpperCase() ?? '?'}
                          </div>
                          <div>
                            <p className="font-medium text-slate-900">{user.name}</p>
                            <p className="text-sm text-slate-500">ID: {user.id}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="space-y-1">
                          <div className="flex items-center gap-2 text-sm text-slate-600">
                            <Phone className="w-3 h-3" />
                            {user.mobile}
                          </div>
                          {user.email && (
                            <div className="flex items-center gap-2 text-sm text-slate-500">
                              <Mail className="w-3 h-3" />
                              {user.email}
                            </div>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <RoleBadge role={user.role} />
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2 text-sm text-slate-600">
                          <MapPin className="w-3 h-3" />
                          {user.ward_name || `Ward ${user.ward_id}`}
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="space-y-1">
                          <StatusBadge is_active={user.is_active} is_verified={user.is_verified} />
                          {!user.is_verified && user.is_active && (
                            <button
                              onClick={() => handleResendVerification(user.id)}
                              className="text-xs text-blue-600 hover:text-blue-700 block"
                            >
                              Resend verification
                            </button>
                          )}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-500">
                        {new Date(user.created_at).toLocaleDateString('en-IN', {
                          year: 'numeric',
                          month: 'short',
                          day: 'numeric',
                        })}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => {
                              setSelectedUser(user);
                              setShowViewModal(true);
                            }}
                            className="p-1.5 text-slate-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                            title="View Details"
                          >
                            <Eye className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => {
                              setSelectedUser(user);
                              setShowEditModal(true);
                            }}
                            className="p-1.5 text-slate-500 hover:text-green-600 hover:bg-green-50 rounded-lg transition-colors"
                            title="Edit User"
                          >
                            <Edit className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleToggleStatus(user)}
                            className="p-1.5 text-slate-500 hover:text-yellow-600 hover:bg-yellow-50 rounded-lg transition-colors"
                            title={user.is_active ? 'Deactivate' : 'Activate'}
                          >
                            {user.is_active ? <UserX className="w-4 h-4" /> : <UserCheck className="w-4 h-4" />}
                          </button>
                          <button
                            onClick={() => {
                              setSelectedUser(user);
                              setShowDeleteModal(true);
                            }}
                            className="p-1.5 text-slate-500 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                            title="Delete User"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {users.length === 0 && (
              <div className="text-center py-12">
                <div className="w-16 h-16 mx-auto mb-4 bg-slate-100 rounded-full flex items-center justify-center">
                  <Shield className="w-8 h-8 text-slate-400" />
                </div>
                <h3 className="text-lg font-medium text-slate-900 mb-1">No users found</h3>
                <p className="text-slate-500">
                  {search || roleFilter || statusFilter
                    ? 'Try adjusting your search or filters'
                    : 'Get started by adding your first user'}
                </p>
              </div>
            )}

            {/* Pagination */}
            {pagination.totalPages > 1 && (
              <div className="px-6 py-4 border-t border-slate-200 flex items-center justify-between flex-wrap gap-4">
                <p className="text-sm text-slate-500">
                  Showing {((pagination.page - 1) * pagination.pageSize) + 1} to{' '}
                  {Math.min(pagination.page * pagination.pageSize, pagination.total)} of {pagination.total} users
                </p>
                <div className="flex gap-2">
                  <button
                    onClick={() => setPagination(p => ({ ...p, page: p.page - 1 }))}
                    disabled={pagination.page === 1}
                    className="p-2 text-slate-500 hover:text-slate-700 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <ChevronLeft className="w-5 h-5" />
                  </button>
                  <span className="px-3 py-1 text-sm text-slate-700">
                    Page {pagination.page} of {pagination.totalPages}
                  </span>
                  <button
                    onClick={() => setPagination(p => ({ ...p, page: p.page + 1 }))}
                    disabled={pagination.page === pagination.totalPages}
                    className="p-2 text-slate-500 hover:text-slate-700 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <ChevronRight className="w-5 h-5" />
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>

      {/* Modals */}
      {showAddModal && (
        <Modal title="Add New User" onClose={() => setShowAddModal(false)}>
          <UserFormModal
            user={null}
            wards={wards}
            onSave={handleCreateUser}
            onClose={() => setShowAddModal(false)}
          />
        </Modal>
      )}

      {showEditModal && selectedUser && (
        <Modal title="Edit User" onClose={() => setShowEditModal(false)}>
          <UserFormModal
            user={selectedUser}
            wards={wards}
            onSave={handleUpdateUser}
            onClose={() => setShowEditModal(false)}
          />
        </Modal>
      )}

      {showViewModal && selectedUser && (
        <Modal title="User Details" onClose={() => setShowViewModal(false)}>
          <ViewUserModal user={selectedUser} onClose={() => setShowViewModal(false)} />
        </Modal>
      )}

      {showDeleteModal && selectedUser && (
        <DeleteConfirmModal
          user={selectedUser}
          onConfirm={handleDeleteUser}
          onClose={() => setShowDeleteModal(false)}
        />
      )}

      {showImportModal && (
        <ImportModal
          onClose={() => {
            setShowImportModal(false);
            setImportFile(null);
            setImportResult(null);
          }}
          onImport={handleBulkImport}
          onDownloadTemplate={handleDownloadTemplate}
          importing={importing}
          file={importFile}
          setFile={setImportFile}
          result={importResult}
        />
      )}


      {/* Toast Notifications */}
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  );
}