'use client';

import { useState, ChangeEvent, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { apiClient } from '@/lib/api-client';

interface ContentFormData {
  title: string;
  content_type: string;
  description: string;
  image_url: string;
  redirect_url: string;
  display_order: number;
  is_active: boolean;
  metadata: Record<string, any>;
}

const CONTENT_TYPES = [
  { value: 'BANNER', label: 'Banner', help: 'Large promotional image at top of home screen' },
  { value: 'ANNOUNCEMENT', label: 'Announcement', help: 'Important notice or update' },
  { value: 'COMPLAINT_CATEGORY', label: 'Complaint Category', help: 'Civic complaint type (Road, Water, etc.)' },
  { value: 'EMERGENCY_SERVICE', label: 'Emergency Service', help: 'Hospital, Police, Fire Brigade, etc.' },
  { value: 'SCHEME', label: 'Scheme/Program', help: 'Government scheme or program information' },
  { value: 'QUICK_LINK', label: 'Quick Link', help: 'Shortcut button to important feature' },
  { value: 'WIDGET', label: 'Widget', help: 'Custom widget or feature' },
];

export default function AddContentPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState<ContentFormData>({
    title: '',
    content_type: '',
    description: '',
    image_url: '',
    redirect_url: '',
    display_order: 0,
    is_active: true,
    metadata: {},
  });

  const handleInputChange = (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target as any;
    setFormData((prev) => ({
      ...prev,
      [name]: type === 'checkbox' ? (e.target as HTMLInputElement).checked : value,
    }));
  };

  const handleMetadataChange = (key: string, value: any) => {
    setFormData((prev) => ({
      ...prev,
      metadata: { ...prev.metadata, [key]: value },
    }));
  };

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    try {
      setLoading(true);
      await apiClient.post('/admin/home-content', formData);
      router.push('/dashboard/home-content');
    } catch (error) {
      console.error('Failed to create content:', error);
      alert('Failed to create content. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const renderTypeSpecificFields = () => {
    const type = formData.content_type;

    switch (type) {
      case 'COMPLAINT_CATEGORY':
        return (
          <div className="space-y-4 p-4 bg-blue-50 rounded-lg border border-blue-200">
            <h4 className="font-semibold text-blue-900">Complaint Category Details</h4>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Icon/Category Code
              </label>
              <input
                type="text"
                placeholder="e.g., road_potholes, water_supply"
                className="w-full border border-gray-300 rounded px-3 py-2"
                value={formData.metadata.category_code || ''}
                onChange={(e) => handleMetadataChange('category_code', e.target.value)}
              />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Department
              </label>
              <input
                type="text"
                placeholder="e.g., Engineering (PWD), Water Supply Department"
                className="w-full border border-gray-300 rounded px-3 py-2"
                value={formData.metadata.department || ''}
                onChange={(e) => handleMetadataChange('department', e.target.value)}
              />
            </div>
          </div>
        );

      case 'EMERGENCY_SERVICE':
        return (
          <div className="space-y-4 p-4 bg-red-50 rounded-lg border border-red-200">
            <h4 className="font-semibold text-red-900">Emergency Service Details</h4>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Service Type
              </label>
              <select
                className="w-full border border-gray-300 rounded px-3 py-2"
                value={formData.metadata.service_type || ''}
                onChange={(e) => handleMetadataChange('service_type', e.target.value)}
              >
                <option value="">Select Type</option>
                <option value="Hospital">Hospital</option>
                <option value="Police">Police</option>
                <option value="Fire Brigade">Fire Brigade</option>
                <option value="Ambulance">Ambulance</option>
                <option value="Health Center">Health Center</option>
              </select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Phone Number
                </label>
                <input
                  type="tel"
                  placeholder="10 digit number"
                  className="w-full border border-gray-300 rounded px-3 py-2"
                  value={formData.metadata.phone || ''}
                  onChange={(e) => handleMetadataChange('phone', e.target.value)}
                />
              </div>
              <div>
                <label className="block text-sm font-semibold text-gray-700 mb-2">
                  Alternate Phone
                </label>
                <input
                  type="tel"
                  placeholder="Optional"
                  className="w-full border border-gray-300 rounded px-3 py-2"
                  value={formData.metadata.alternate_phone || ''}
                  onChange={(e) => handleMetadataChange('alternate_phone', e.target.value)}
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Address
              </label>
              <textarea
                placeholder="Full address"
                className="w-full border border-gray-300 rounded px-3 py-2 h-20 resize-none"
                value={formData.metadata.address || ''}
                onChange={(e) => handleMetadataChange('address', e.target.value)}
              />
            </div>
          </div>
        );

      case 'SCHEME':
        return (
          <div className="space-y-4 p-4 bg-green-50 rounded-lg border border-green-200">
            <h4 className="font-semibold text-green-900">Scheme Details</h4>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Eligibility
              </label>
              <textarea
                placeholder="Who is eligible for this scheme?"
                className="w-full border border-gray-300 rounded px-3 py-2 h-16 resize-none"
                value={formData.metadata.eligibility || ''}
                onChange={(e) => handleMetadataChange('eligibility', e.target.value)}
              />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Benefits
              </label>
              <textarea
                placeholder="What are the benefits?"
                className="w-full border border-gray-300 rounded px-3 py-2 h-16 resize-none"
                value={formData.metadata.benefits || ''}
                onChange={(e) => handleMetadataChange('benefits', e.target.value)}
              />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Application Link
              </label>
              <input
                type="url"
                placeholder="https://example.com/apply"
                className="w-full border border-gray-300 rounded px-3 py-2"
                value={formData.metadata.application_link || ''}
                onChange={(e) => handleMetadataChange('application_link', e.target.value)}
              />
            </div>
          </div>
        );

      case 'QUICK_LINK':
        return (
          <div className="space-y-4 p-4 bg-yellow-50 rounded-lg border border-yellow-200">
            <h4 className="font-semibold text-yellow-900">Quick Link Details</h4>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Button Text
              </label>
              <input
                type="text"
                placeholder="e.g., File Complaint, Track Status"
                className="w-full border border-gray-300 rounded px-3 py-2"
                value={formData.metadata.button_text || formData.title}
                onChange={(e) => handleMetadataChange('button_text', e.target.value)}
              />
            </div>
            <div>
              <label className="block text-sm font-semibold text-gray-700 mb-2">
                Icon (Emoji or Icon Code)
              </label>
              <input
                type="text"
                placeholder="e.g., 📋 or complaint_icon"
                className="w-full border border-gray-300 rounded px-3 py-2"
                value={formData.metadata.icon || ''}
                onChange={(e) => handleMetadataChange('icon', e.target.value)}
              />
            </div>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Add Home Content</h1>
        <p className="text-gray-600">Create new content for the app home screen</p>
      </div>

      <form onSubmit={handleSubmit} className="card space-y-6">
        {/* Content Type Selection */}
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-3">
            Content Type *
          </label>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
            {CONTENT_TYPES.map((type) => (
              <button
                key={type.value}
                type="button"
                onClick={() => setFormData((prev) => ({ ...prev, content_type: type.value }))}
                className={`p-3 rounded-lg text-left transition-all border-2 ${
                  formData.content_type === type.value
                    ? 'border-blue-500 bg-blue-50'
                    : 'border-gray-200 bg-white hover:border-gray-300'
                }`}
              >
                <div className="font-semibold text-sm text-gray-900">{type.label}</div>
                <div className="text-xs text-gray-600 mt-1">{type.help}</div>
              </button>
            ))}
          </div>
        </div>

        {/* Basic Fields */}
        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">
            Title *
          </label>
          <input
            type="text"
            name="title"
            value={formData.title}
            onChange={handleInputChange}
            placeholder="Enter content title"
            className="w-full border border-gray-300 rounded px-3 py-2"
            required
          />
        </div>

        <div>
          <label className="block text-sm font-semibold text-gray-700 mb-2">
            Description
          </label>
          <textarea
            name="description"
            value={formData.description}
            onChange={handleInputChange}
            placeholder="Detailed description of the content"
            className="w-full border border-gray-300 rounded px-3 py-2 h-24 resize-none"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Image URL
            </label>
            <input
              type="url"
              name="image_url"
              value={formData.image_url}
              onChange={handleInputChange}
              placeholder="https://example.com/image.jpg"
              className="w-full border border-gray-300 rounded px-3 py-2"
            />
          </div>
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Redirect URL
            </label>
            <input
              type="url"
              name="redirect_url"
              value={formData.redirect_url}
              onChange={handleInputChange}
              placeholder="Where to redirect on click"
              className="w-full border border-gray-300 rounded px-3 py-2"
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-2">
              Display Order
            </label>
            <input
              type="number"
              name="display_order"
              value={formData.display_order}
              onChange={handleInputChange}
              className="w-full border border-gray-300 rounded px-3 py-2"
            />
          </div>
          <div className="flex items-end">
            <label className="flex items-center">
              <input
                type="checkbox"
                name="is_active"
                checked={formData.is_active}
                onChange={handleInputChange}
                className="w-4 h-4 rounded border-gray-300"
              />
              <span className="ml-2 text-sm font-semibold text-gray-700">Active</span>
            </label>
          </div>
        </div>

        {/* Type-Specific Fields */}
        {renderTypeSpecificFields()}

        {/* Submit Buttons */}
        <div className="flex gap-4 pt-6 border-t border-gray-200">
          <button
            type="submit"
            disabled={loading || !formData.content_type}
            className="flex-1 bg-blue-600 text-white font-semibold py-2 rounded hover:bg-blue-700 disabled:opacity-50"
          >
            {loading ? 'Creating...' : 'Create Content'}
          </button>
          <button
            type="button"
            onClick={() => router.back()}
            className="flex-1 bg-gray-200 text-gray-800 font-semibold py-2 rounded hover:bg-gray-300"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}
