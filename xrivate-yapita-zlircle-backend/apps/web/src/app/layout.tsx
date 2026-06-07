import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'XrivateYapitaZlircle | Private Capital Network',
  description: 'Dashboard do Membro',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR">
      <body className="bg-slate-900 text-slate-100 antialiased">
        <div className="min-h-screen flex flex-col">
          <header className="border-b border-slate-800 p-4 flex justify-between items-center">
            <h1 className="text-xl font-bold text-amber-500">Xrivate<span className="text-slate-400">YapitaZlircle</span></h1>
            <div className="flex items-center gap-2">
              <span className="text-sm text-slate-400">Circle Sovereign</span>
              <div className="w-8 h-8 rounded-full bg-amber-500"></div>
            </div>
          </header>
          <main className="flex-1 p-8 max-w-7xl mx-auto w-full">
            {children}
          </main>
        </div>
      </body>
    </html>
  );
}
