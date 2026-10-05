import { useEffect, useState } from "react";
import SalesChart from "../components/SalesChart";
import StatCard from "../components/StatCard";
import { getSalesMonthly, getSalesYearly, getSalesByCountry } from "../services/api";

export default function SalesAnalysis() {
    const [monthly, setMonthly] = useState([]);
    const [yearly, setYearly] = useState([]);
    const [byCountry, setByCountry] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        Promise.all([getSalesMonthly(), getSalesYearly(), getSalesByCountry()])
            .then(([m, y, c]) => {
                setMonthly(
                    (m.data || []).map((r) => ({
                        label: `${r.year}-${String(r.month).padStart(2, "0")}`,
                        revenue: Number(r.revenue),
                        orders: Number(r.order_count),
                    }))
                );
                setYearly(
                    (y.data || []).map((r) => ({
                        label: String(r.year),
                        revenue: Number(r.revenue),
                    }))
                );
                setByCountry(c.data || []);
            })
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="page-loading">Memuat data penjualan...</div>;

    const totalRevenue = monthly.reduce((a, b) => a + b.revenue, 0);
    const totalOrders = monthly.reduce((a, b) => a + b.orders, 0);
    const bestMonth = monthly.reduce(
        (a, b) => (b.revenue > (a?.revenue ?? 0) ? b : a),
        null
    );

    return (
        <div className="page">
            <div className="stat-grid">
                <StatCard title="Total Revenue" value={`$${totalRevenue.toLocaleString()}`} icon="💰" color="#16a34a" />
                <StatCard title="Total Orders" value={totalOrders} icon="🧾" color="#4f46e5" />
                <StatCard title="Best Month" value={bestMonth?.label || "-"} icon="🏆" color="#ea580c" subtitle={bestMonth ? `$${bestMonth.revenue.toLocaleString()}` : ""} />
                <StatCard title="Countries" value={byCountry.length} icon="🌍" color="#0891b2" />
            </div>

            <SalesChart title="Revenue Bulanan" data={monthly} type="line" xKey="label" dataKey="revenue" />
            <SalesChart title="Revenue Tahunan" data={yearly} type="bar" xKey="label" dataKey="revenue" />

            <div className="table-card">
                <h3>Sales by Country</h3>
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Country</th>
                            <th className="num">Revenue</th>
                            <th className="num">Orders</th>
                            <th className="num">Customers</th>
                        </tr>
                    </thead>
                    <tbody>
                        {byCountry.map((r, i) => (
                            <tr key={r.country}>
                                <td>{i + 1}</td>
                                <td>{r.country}</td>
                                <td className="num">${Number(r.revenue).toLocaleString()}</td>
                                <td className="num">{r.order_count}</td>
                                <td className="num">{r.customer_count}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}