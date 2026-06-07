export default function Dashboard() {
  // No MVP real, usa React Query ou SWR para buscar da API
  const mockData = {
    allocatedWealth: 12500000.00,
    accumulatedRevenue: 450000.00,
    annualizedYield: 11.5,
    revenueShare: 135000.00,
  };

  const formatCurrency = (value: number) => 
    new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(value);

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-semibold mb-1">Visão Geral do Patrimônio</h2>
        <p className="text-slate-400">Acompanhe suas alocações e retornos em tempo real.</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <KpiCard title="Patrimônio Alocado" value={formatCurrency(mockData.allocatedWealth)} />
        <KpiCard title="Receita Acumulada" value={formatCurrency(mockData.accumulatedRevenue)} highlight />
        <KpiCard title="Yield Anualizado" value={`${mockData.annualizedYield}%`} />
        <KpiCard title="Revenue Share (30%)" value={formatCurrency(mockData.revenueShare)} highlight />
      </div>

      {/* Alocação Modelo */}
      <div className="bg-slate-800/50 rounded-xl p-6 border border-slate-700">
        <h3 className="text-lg font-medium mb-4">Alocação do Pool Total</h3>
        <div className="space-y-3">
          <ProgressBar label="Reserva de Liquidez" percent={25} color="bg-blue-500" />
          <ProgressBar label="Tesouraria Institucional" percent={30} color="bg-emerald-500" />
          <ProgressBar label="Crédito Corporativo" percent={20} color="bg-amber-500" />
          <ProgressBar label="Infraestrutura" percent={15} color="bg-purple-500" />
          <ProgressBar label="Operações Estratégicas" percent={10} color="bg-rose-500" />
        </div>
      </div>
    </div>
  );
}

function KpiCard({ title, value, highlight = false }: { title: string, value: string, highlight?: boolean }) {
  return (
    <div className={`p-6 rounded-xl border ${highlight ? 'bg-amber-500/10 border-amber-500/30' : 'bg-slate-800/50 border-slate-700'}`}>
      <p className="text-sm text-slate-400 mb-2">{title}</p>
      <p className={`text-2xl font-bold ${highlight ? 'text-amber-400' : 'text-slate-100'}`}>{value}</p>
    </div>
  );
}

function ProgressBar({ label, percent, color }: { label: string, percent: number, color: string }) {
  return (
    <div>
      <div className="flex justify-between text-sm mb-1">
        <span className="text-slate-300">{label}</span>
        <span className="text-slate-400">{percent}%</span>
      </div>
      <div className="w-full bg-slate-700 rounded-full h-2.5">
        <div className={`${color} h-2.5 rounded-full`} style={{ width: `${percent}%` }}></div>
      </div>
    </div>
  );
}
