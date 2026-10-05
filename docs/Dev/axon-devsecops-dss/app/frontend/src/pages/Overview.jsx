import { useEffect, useState } from "react";
import StatCard from "../components/StatCard";
import SalesChart from "../components/SalesChart";
import { getDashboardSummary, getSalesYearly } from "../services/api";

export default function Overview() {
    const [summary, setSummary] = useState(null);
    const [yearly, setYearly] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        Promise.all([getDashboardSummary(), getSalesYearly()])
            .then(([s, y]) => {
                setSummary(s.data);
                setYearly(
                    (y.data || []).map((r) => ({
                        label: String(r.year),
                        revenue: Number(r.revenue),
                        orders: Number(r.order_count),
                    }))
                );
            })
            .catch((e) => console.error(e))
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="page-loading">Memuat data...</div>;
    if (!summary) return <div className="page-error">Gagal memuat data.</div>;

    return (
        <div className="page">
            <div className="stat-grid">
                <StatCard
                    title="Total Customers"
                    value={summary.total_customers}
                    icon="👥"
                    color="#4f46e5"
                    subtitle="Pelanggan terdaftar"
                />
                <StatCard
                    title="Total Products"
                    value={summary.total_products}
                    icon="📦"
                    color="#0891b2"
                    subtitle="Produk di katalog"
                />
                <StatCard
                    title="Total Orders"
                    value={summary.total_orders}
                    icon="🧾"
                    color="#16a34a"
                    subtitle="Semua pesanan"
                />
                <StatCard
                    title="Years Tracked"
                    value={yearly.length}
                    icon="📅"
                    color="#ea580c"
                    subtitle="Periode data"
                />
            </div>

            <SalesChart
                title="Revenue per Tahun"
                data={yearly}
                type="line"
                xKey="label"
                dataKey="revenue"
            />
        </div>
    );
}