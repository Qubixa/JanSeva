'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';

// Matches HomeContentResponse from backend (admin_extended.py)
interface HomeContent {
  id: number;
  content_type: string;
  title: string;
  description: string | null;
  image_url: string | null;
  redirect_url: string | null;
  meta_data: Record<string, any> | null;
  display_order: number;
  is_active: boolean;
  created_at: string;
}

const CONTENT_TYPES = [
  { value: 'BANNER', label: 'Banners', icon: '🖼️', color: 'bg-purple-100 text-purple-700' },
  { value: 'ANNOUNCEMENT', label: 'Announcements', icon: '📢', color: 'bg-blue-100 text-blue-700' },
  { value: 'COMPLAINT_CATEGORY', label: 'Complaint Categories', icon: '📋', color: 'bg-red-100 text-red-700' },
  { value: 'EMERGENCY_SERVICE', label: 'Emergency Services', icon: '🚑', color: 'bg-green-100 text-green-700' },
  { value: 'SCHEME', label: 'Schemes', icon: '🎯', color: 'bg-yellow-100 text-yellow-700' },
  { value: 'QUICK_LINK', label: 'Quick Links', icon: '⚡', color: 'bg-indigo-100 text-indigo-700' },
  { value: 'WIDGET', label: 'Widgets', icon: '🔧', color: 'bg-gray-100 text-gray-700' },
];

export default function HomeContentPage() {
  const [contents, setContents] = useState<HomeContent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedType, setSelectedType] = useState<string | null>(null);
  const [debugInfo, setDebugInfo] = useState<any>(null);

  useEffect(() => { 
    fetchContents(); 
  }, []);

  const fetchContents = async () => {
    try {
      setLoading(true);
      setError(null);
      
      console.log('Fetching home content...');
      const response = await apiClient.get<HomeContent[]>('/admin/home-content');
      
      console.log('Raw response:', response);
      console.log('Response type:', typeof response);
      console.log('Is array:', Array.isArray(response));
      console.log('Data length:', response?.length || 0);
      
      // Store debug info
      setDebugInfo({
        responseType: typeof response,
        isArray: Array.isArray(response),
        length: response?.length || 0,
        sample: response?.[0] || null,
        fullResponse: response
      });
      
      // Ensure we're setting an array
      if (Array.isArray(response)) {
        setContents(response);
      } else if (response && typeof response === 'object') {
        // Handle case where response might be wrapped in an object
        console.warn('Response is not an array:', response);
        const possibleArray = (response as any).data || (response as any).items || (response as any).results;
        if (Array.isArray(possibleArray)) {
          setContents(possibleArray);
        } else {
          setContents([]);
          setError('Received invalid data format from server');
        }
      } else {
        setContents([]);
        setError('No data received from server');
      }
    } catch (error: any) {
      console.error('Failed to fetch contents:', error);
      setError(error?.message || 'Failed to load content. Please check your connection and try again.');
      setContents([]);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this content item? This action cannot be undone.')) return;
    
    try {
      await apiClient.delete(`/admin/home-content/${id}`);
      setContents((c) => c.filter((x) => x.id !== id));
    } catch (error) {
      console.error('Failed to delete:', error);
      alert('Failed to delete content. Please try again.');
    }
  };

  const handleToggle = async (id: number, current: boolean) => {
    try {
      // Note: You might need to implement a PATCH endpoint for this
      // For now, we'll use PUT with the full object
      const content = contents.find(c => c.id === id);
      if (!content) return;
      
      const updatedContent = { ...content, is_active: !current };
      await apiClient.put(`/admin/home-content/${id}`, updatedContent);
      setContents((c) =>
        c.map((x) => (x.id === id ? { ...x, is_active: !current } : x))
      );
    } catch (error) {
      console.error('Failed to update:', error);
      alert('Failed to update content status. Please try again.');
    }
  };

  const filtered = selectedType
    ? contents.filter((c) => c.content_type === selectedType)
    : contents;

  const countByType = (type: string) =>
    contents.filter((c) => c.content_type === type).length;

  const getTypeIcon = (type: string) => {
    return CONTENT_TYPES.find(t => t.value === type)?.icon || '📄';
  };

  const getTypeColor = (type: string) => {
    return CONTENT_TYPES.find(t => t.value === type)?.color || 'bg-gray-100 text-gray-700';
  };

  const formatDate = (dateString: string) => {
    try {
      return new Date(dateString).toLocaleDateString('en-IN', {
        day: 'numeric',
        month: 'short',
        year: 'numeric'
      });
    } catch {
      return 'Invalid date';
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="page-header">
          <div>
            <h1 className="page-title">Home Content</h1>
            <p className="page-subtitle">Manage what appears on the app home screen</p>
          </div>
          <div className="skeleton h-10 w-32 rounded-lg" />
        </div>
        
        <div className="card">
          <div className="skeleton h-24 rounded-xl mb-4" />
          <div className="space-y-3">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="skeleton h-28 rounded-xl" />
            ))}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="page-header">
        <div>
          <h1 className="page-title">Home Content</h1>
          <p className="page-subtitle">Manage what appears on the app home screen</p>
        </div>
        <Link href="/dashboard/home-content/new" className="btn-primary">
          + Add Content
        </Link>
      </div>

      {/* Error Message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <span className="text-red-600 text-xl">⚠️</span>
            <div className="flex-1">
              <h3 className="font-semibold text-red-800 mb-1">Error Loading Content</h3>
              <p className="text-red-700 text-sm">{error}</p>
              <button 
                onClick={fetchContents}
                className="mt-2 text-sm text-red-700 font-semibold hover:text-red-900"
              >
                Try Again →
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Debug Info (only in development) */}
      {process.env.NODE_ENV === 'development' && debugInfo && (
        <div className="bg-gray-900 text-green-400 rounded-lg p-4 font-mono text-xs overflow-auto">
          <details>
            <summary className="cursor-pointer font-bold mb-2">Debug Info (click to expand)</summary>
            <pre className="mt-2">{JSON.stringify(debugInfo, null, 2)}</pre>
          </details>
        </div>
      )}

      {/* Type filter tabs */}
      <div className="card">
        <p className="text-xs font-bold text-slate-500 uppercase tracking-wide mb-3">
          Filter by type ({contents.length} total items)
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-2">
          <button
            onClick={() => setSelectedType(null)}
            className={`flex flex-col items-center gap-1 p-3 rounded-xl border text-center transition-all text-xs font-semibold ${
              selectedType === null
                ? 'bg-blue-50 border-blue-200 text-blue-700'
                : 'bg-slate-50 border-slate-100 text-slate-500 hover:bg-slate-100'
            }`}
          >
            <span className="text-lg">📊</span>
            <span>All</span>
            <span className={`text-[10px] font-bold ${selectedType === null ? 'text-blue-500' : 'text-slate-400'}`}>
              {contents.length}
            </span>
          </button>

          {CONTENT_TYPES.map((type) => (
            <button
              key={type.value}
              onClick={() => setSelectedType(type.value)}
              className={`flex flex-col items-center gap-1 p-3 rounded-xl border text-center transition-all text-xs font-semibold ${
                selectedType === type.value
                  ? 'bg-blue-50 border-blue-200 text-blue-700'
                  : 'bg-slate-50 border-slate-100 text-slate-500 hover:bg-slate-100'
              }`}
            >
              <span className="text-lg">{type.icon}</span>
              <span className="leading-tight">{type.label}</span>
              <span className={`text-[10px] font-bold ${selectedType === type.value ? 'text-blue-500' : 'text-slate-400'}`}>
                {countByType(type.value)}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Content list */}
      <div className="card space-y-4">
        {filtered.length === 0 ? (
          <div className="empty-state py-12">
            <div className="text-center">
              <div className="text-6xl mb-4">
                {selectedType ? CONTENT_TYPES.find(t => t.value === selectedType)?.icon : '📄'}
              </div>
              <p className="empty-state-title text-gray-900 font-semibold text-lg mb-2">
                No content {selectedType ? `of type "${selectedType}"` : ''} yet
              </p>
              <p className="empty-state-desc text-gray-500 mb-6">
                Get started by adding your first content item
              </p>
              <Link href="/dashboard/home-content/new" className="btn-primary inline-block">
                + Add Your First Content
              </Link>
            </div>
          </div>
        ) : (
          filtered.map((content) => (
            <div
              key={content.id}
              className="flex gap-4 border border-slate-100 rounded-xl p-4 hover:border-slate-200 hover:shadow-sm transition-all group"
            >
              {content.image_url ? (
                <img
                  src={content.image_url}
                  alt={content.title}
                  className="w-20 h-20 object-cover rounded-lg shrink-0 bg-slate-100"
                  onError={(e) => {
                    (e.target as HTMLImageElement).style.display = 'none';
                    (e.target as HTMLImageElement).nextElementSibling?.classList.remove('hidden');
                  }}
                />
              ) : null}
              <div className={`w-20 h-20 ${content.image_url ? 'hidden' : ''} flex items-center justify-center bg-slate-100 rounded-lg shrink-0 text-3xl`}>
                {getTypeIcon(content.content_type)}
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1.5 flex-wrap">
                  <span className={`text-[10px] px-2 py-0.5 rounded-full font-semibold ${getTypeColor(content.content_type)}`}>
                    {content.content_type.replace('_', ' ')}
                  </span>
                  <span
                    className={`text-[10px] px-2 py-0.5 rounded-full font-semibold ${
                      content.is_active
                        ? 'bg-green-100 text-green-700'
                        : 'bg-gray-100 text-gray-500'
                    }`}
                  >
                    {content.is_active ? 'Active' : 'Inactive'}
                  </span>
                  <span className="text-[10px] text-slate-400 ml-auto">
                    Order: {content.display_order}
                  </span>
                </div>
                
                <h3 className="font-semibold text-slate-900 group-hover:text-blue-600 transition-colors">
                  {content.title}
                </h3>
                
                {content.description && (
                  <p className="text-sm text-slate-500 mt-0.5 line-clamp-2">
                    {content.description}
                  </p>
                )}
                
                <div className="flex items-center gap-3 mt-3 text-xs text-slate-400">
                  <span>ID: {content.id}</span>
                  <span>•</span>
                  <span>Created: {formatDate(content.created_at)}</span>
                  {content.redirect_url && (
                    <>
                      <span>•</span>
                      <span className="truncate max-w-[200px]">🔗 {content.redirect_url}</span>
                    </>
                  )}
                </div>
                
                <div className="flex items-center gap-2 mt-3">
                  <button
                    onClick={() => handleToggle(content.id, content.is_active)}
                    className="btn-ghost text-xs px-2.5 py-1.5 rounded-md hover:bg-gray-100 transition-colors"
                  >
                    {content.is_active ? '🔒 Disable' : '🔓 Enable'}
                  </button>
                  <Link
                    href={`/dashboard/home-content/${content.id}`}
                    className="btn-ghost text-xs px-2.5 py-1.5 rounded-md hover:bg-gray-100 transition-colors"
                  >
                    ✏️ Edit
                  </Link>
                  <button
                    onClick={() => handleDelete(content.id)}
                    className="text-red-600 hover:text-red-700 text-xs px-2.5 py-1.5 rounded-md hover:bg-red-50 transition-colors"
                  >
                    Delete
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>

      {/* Refresh button */}
      <div className="flex justify-center">
        <button
          onClick={fetchContents}
          className="text-sm text-blue-600 hover:text-blue-700 font-semibold flex items-center gap-2"
        >
          🔄 Refresh Content
        </button>
      </div>
    </div>
  );
}