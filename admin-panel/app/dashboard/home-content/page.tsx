'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';

interface HomeContent {
  id: string;
  content_type: string;
  title: string;
  description: string;
  image_url: string;
  order: number;
  is_active: boolean;
  created_at: string;
}

const CONTENT_TYPES = [
  { value: 'BANNER', label: 'Banners', icon: '🖼️' },
  { value: 'ANNOUNCEMENT', label: 'Announcements', icon: '📢' },
  { value: 'COMPLAINT_CATEGORY', label: 'Complaint Categories', icon: '📋' },
  { value: 'EMERGENCY_SERVICE', label: 'Emergency Services', icon: '🚑' },
  { value: 'SCHEME', label: 'Schemes & Programs', icon: '🎯' },
  { value: 'QUICK_LINK', label: 'Quick Links', icon: '⚡' },
  { value: 'WIDGET', label: 'Widgets', icon: '🔧' },
];

export default function HomeContentPage() {
  const [contents, setContents] = useState<HomeContent[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedType, setSelectedType] = useState<string | null>(null);

  useEffect(() => {
    fetchContents();
  }, []);

  const fetchContents = async () => {
    try {
      setLoading(true);
      const response = await apiClient.get('/admin/home-content');
      setContents(response.data);
    } catch (error) {
      console.error('Failed to fetch contents:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (confirm('Are you sure?')) {
      try {
        await apiClient.delete(`/admin/home-content/${id}`);
        setContents(contents.filter((c) => c.id !== id));
      } catch (error) {
        console.error('Failed to delete:', error);
      }
    }
  };

  const handleToggle = async (id: string, currentStatus: boolean) => {
    try {
      await apiClient.put(`/admin/home-content/${id}`, {
        is_active: !currentStatus,
      });
      setContents(contents.map((c) =>
        c.id === id ? { ...c, is_active: !currentStatus } : c
      ));
    } catch (error) {
      console.error('Failed to update:', error);
    }
  };

  const filteredContents = selectedType
    ? contents.filter((c) => c.content_type === selectedType)
    : contents;

  const countByType = (type: string) => {
    return contents.filter((c) => c.content_type === type).length;
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Home Screen Content Manager</h1>
          <p className="text-gray-600">Manage banners, announcements, services, and more displayed on the app home screen</p>
        </div>
        <Link href="/dashboard/home-content/new" className="btn-primary">
          + Add Content
        </Link>
      </div>

      {/* Content Type Filter */}
      <div className="card">
        <h3 className="font-semibold text-gray-900 mb-4">Content By Type</h3>
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
          <button
            onClick={() => setSelectedType(null)}
            className={`p-3 rounded-lg text-center transition-all ${
              selectedType === null
                ? 'bg-blue-100 text-blue-900 border-2 border-blue-300'
                : 'bg-gray-50 text-gray-700 border border-gray-200 hover:bg-gray-100'
            }`}
          >
            <div className="text-lg">📊</div>
            <div className="text-xs font-semibold mt-1">All</div>
            <div className="text-xs text-gray-600">{contents.length}</div>
          </button>
          {CONTENT_TYPES.map((type) => (
            <button
              key={type.value}
              onClick={() => setSelectedType(type.value)}
              className={`p-3 rounded-lg text-center transition-all ${
                selectedType === type.value
                  ? 'bg-blue-100 text-blue-900 border-2 border-blue-300'
                  : 'bg-gray-50 text-gray-700 border border-gray-200 hover:bg-gray-100'
              }`}
            >
              <div className="text-lg">{type.icon}</div>
              <div className="text-xs font-semibold mt-1">{type.label}</div>
              <div className="text-xs text-gray-600">{countByType(type.value)}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Content List */}
      <div className="card space-y-4">
        {loading ? (
          <div className="text-center py-8 text-gray-500">Loading...</div>
        ) : (
          <div className="space-y-4">
            {filteredContents.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                {selectedType
                  ? `No ${selectedType.toLowerCase()} content yet`
                  : 'No content yet'}
              </div>
            ) : (
              filteredContents.map((content) => (
                <div
                  key={content.id}
                  className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow"
                >
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-2">
                        <span className="inline-block px-2 py-1 bg-blue-50 text-blue-700 text-xs font-semibold rounded">
                          {content.content_type}
                        </span>
                        <span
                          className={`inline-block px-2 py-1 rounded text-xs font-semibold ${
                            content.is_active
                              ? 'bg-green-50 text-green-700'
                              : 'bg-gray-100 text-gray-600'
                          }`}
                        >
                          {content.is_active ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                      <h3 className="font-semibold text-gray-900 text-lg">{content.title}</h3>
                      {content.description && (
                        <p className="text-sm text-gray-600 mt-1 line-clamp-2">{content.description}</p>
                      )}
                      <div className="flex gap-4 mt-3 text-xs text-gray-500">
                        <span>Order: {content.order}</span>
                        <span>Created: {new Date(content.created_at).toLocaleDateString()}</span>
                      </div>
                    </div>
                    {content.image_url && (
                      <img
                        src={content.image_url}
                        alt={content.title}
                        className="w-24 h-24 object-cover rounded flex-shrink-0"
                      />
                    )}
                  </div>
                  <div className="flex items-center justify-end gap-3 mt-4 pt-4 border-t border-gray-100">
                    <button
                      onClick={() => handleToggle(content.id, content.is_active)}
                      className="text-sm px-3 py-1 rounded bg-gray-50 text-gray-700 hover:bg-gray-100"
                    >
                      {content.is_active ? '🔒 Disable' : '🔓 Enable'}
                    </button>
                    <Link
                      href={`/dashboard/home-content/${content.id}`}
                      className="text-sm px-3 py-1 rounded bg-blue-50 text-blue-700 hover:bg-blue-100"
                    >
                      ✏️ Edit
                    </Link>
                    <button
                      onClick={() => handleDelete(content.id)}
                      className="text-sm px-3 py-1 rounded bg-red-50 text-red-700 hover:bg-red-100"
                    >
                      🗑️ Delete
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </div>

      {/* Info Box */}
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 text-sm text-blue-900">
        <p className="font-semibold mb-2">💡 About Home Content Management</p>
        <ul className="list-disc list-inside space-y-1 text-blue-800">
          <li><strong>Banners:</strong> Large promotional images displayed at top of home screen</li>
          <li><strong>Announcements:</strong> Important notices and updates for users</li>
          <li><strong>Complaint Categories:</strong> Civic complaint options (Roads, Water, Drainage, etc.)</li>
          <li><strong>Emergency Services:</strong> Hospitals, police, fire brigade, and other emergency contacts</li>
          <li><strong>Schemes:</strong> Government schemes and programs information</li>
          <li><strong>Quick Links:</strong> Shortcut buttons to important features and services</li>
        </ul>
      </div>
    </div>
  );
}
