// API Base URL - Update with your backend URL
const String API_BASE_URL = 'http://localhost:8000/api/v1';

// API Endpoints
const String LOGIN_ENDPOINT = '/auth/login';
const String REGISTER_ENDPOINT = '/auth/register';
const String PROFILE_ENDPOINT = '/auth/profile';
const String LOGOUT_ENDPOINT = '/auth/logout';

// Complaints
const String COMPLAINTS_ENDPOINT = '/complaints';
const String CREATE_COMPLAINT_ENDPOINT = '/complaints/create';
const String COMPLAINT_DETAILS_ENDPOINT = '/complaints';
const String CHANGE_PASSWORD_ENDPOINT = '/auth/change-password';

// Wards
const String WARDS_ENDPOINT = '/wards';

// Emergency Services
const String EMERGENCY_SERVICES_ENDPOINT = '/emergency';
const String CREATE_EMERGENCY_ENDPOINT = '/emergency/create';

// Other Services
const String SCHEMES_ENDPOINT = '/schemes';
const String TRANSPORT_ENDPOINT = '/transport';
const String CONTACTS_ENDPOINT = '/contacts';

// Timeouts
const int CONNECTION_TIMEOUT = 30000; // 30 seconds
const int RECEIVE_TIMEOUT = 30000;

// Storage Keys
const String TOKEN_STORAGE_KEY = 'auth_token';
const String USER_STORAGE_KEY = 'user_data';
const String REFRESH_TOKEN_KEY = 'refresh_token';

// Roles
const String CITIZEN_ROLE = 'CITIZEN';
const String WARD_ADMIN_ROLE = 'WARD_ADMIN';
const String SUPER_ADMIN_ROLE = 'SUPER_ADMIN';

// Complaint Status
const String COMPLAINT_OPEN = 'OPEN';
const String COMPLAINT_IN_PROGRESS = 'IN_PROGRESS';
const String COMPLAINT_RESOLVED = 'RESOLVED';
const String COMPLAINT_CLOSED = 'CLOSED';

// Page Sizes
const int PAGE_SIZE = 20;
