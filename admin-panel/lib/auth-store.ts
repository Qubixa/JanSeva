import { create } from 'zustand';
import Cookies from 'js-cookie';

interface Admin {
  id: string;
  email: string;
  name: string;
  role: string;
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
    if (admin) {
      Cookies.set('admin', JSON.stringify(admin), { expires: 7 });
    }
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
    const storedAdmin = Cookies.get('admin');
    const storedToken = Cookies.get('token');
    
    if (storedAdmin && storedToken) {
      set({
        admin: JSON.parse(storedAdmin),
        token: storedToken,
        isLoading: false,
      });
    } else {
      set({ isLoading: false });
    }
  },
}));
