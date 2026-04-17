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

export default function HomeContentPage() {
  const [contents, setContents] = useState<HomeContent[]>([]);
  const [loading, setLoading] = useState(true);

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

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Home Screen Content</h1>
          <p className="text-gray-600">Manage content displayed on the app home screen</p>
        </div>
        <Link href="/dashboard/home-content/new" className="btn-primary">
          Add Content
        </Link>
      </div>

      <div className="card space-y-4">
        {loading ? (
          <div className="text-center text-gray-500">Loading...</div>
        ) : (
          <div className="space-y-4">
            {contents.length === 0 ? (
              <div className="text-center py-8 text-gray-500">No content yet</div>
            ) : (
              contents.map((content) => (
                <div
                  key={content.id}
                  className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors"
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h3 className="font-semibold text-gray-900">{content.title}</h3>
                      <p className="text-sm text-gray-600 mt-1">{content.description}</p>
                      <div className="flex gap-4 mt-3 text-xs text-gray-500">
                        <span>Type: {content.content_type}</span>
                        <span>Order: {content.order}</span>
                      </div>
                    </div>
                    {content.image_url && (
                      <img
                        src={content.image_url}
                        alt={content.title}
                        className="w-20 h-20 object-cover rounded ml-4"
                      />
                    )}
                  </div>
                  <div className="flex items-center justify-between mt-4">
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        content.is_active
                          ? 'bg-green-50 text-green-600'
                          : 'bg-gray-50 text-gray-600'
                      }`}
                    >
                      {content.is_active ? 'Active' : 'Inactive'}
                    </span>
                    <div className="space-x-2">
                      <button
                        onClick={() => handleToggle(content.id, content.is_active)}
                        className="text-sm text-blue-600 hover:text-blue-800"
                      >
                        {content.is_active ? 'Disable' : 'Enable'}
                      </button>
                      <Link
                        href={`/dashboard/home-content/${content.id}`}
                        className="text-sm text-blue-600 hover:text-blue-800"
                      >
                        Edit
                      </Link>
                      <button
                        onClick={() => handleDelete(content.id)}
                        className="text-sm text-red-600 hover:text-red-800"
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
}
