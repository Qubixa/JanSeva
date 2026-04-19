import { create } from 'zustand';
import Cookies from 'js-cookie';

export interface Admin {
  id: number;           // backend returns int, not string
  name: string;
  email: string | null;
  mobile: string;
  role: string;
  ward_id: number | null;
  ward_name: string | null;
  address: string;
  profile_image: string | null;
  is_active: boolean;
  is_verified: boolean;
}

interface AuthStore {
  admin: Admin | null;
  token: string | null;
  isLoading: boolean;
  setAdmin: (admin: Admin) => void;
  setToken: (token: string) => void;
  logout: () => void;
  initAuth: () => void;
}

export const useAuthStore = create<AuthStore>((set) => ({
  admin: null,
  token: null,
  isLoading: true,

  setAdmin: (admin) => {
    set({ admin });
    Cookies.set('admin', JSON.stringify(admin), { expires: 7 });
  },

  setToken: (token) => {
    set({ token });
    Cookies.set('token', token, { expires: 7 });
  },

  logout: () => {
    set({ admin: null, token: null });
    Cookies.remove('admin');
    Cookies.remove('token');
  },

  initAuth: () => {
    try {
      const storedAdmin = Cookies.get('admin');
      const storedToken = Cookies.get('token');
      if (storedAdmin && storedToken) {
        set({
          admin: JSON.parse(storedAdmin) as Admin,
          token: storedToken,
          isLoading: false,
        });
      } else {
        set({ isLoading: false });
      }
    } catch {
      // corrupt cookie - clear it
      Cookies.remove('admin');
      Cookies.remove('token');
      set({ isLoading: false });
    }
  },
}));