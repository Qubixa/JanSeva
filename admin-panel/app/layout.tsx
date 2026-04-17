import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'JanSeva Admin Panel',
  description: 'Admin panel for managing civic services and matrimonial platform',
  viewport: {
    width: 'device-width',
    initialScale: 1,
    userScalable: false,
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
