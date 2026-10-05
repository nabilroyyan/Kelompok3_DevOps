import { useEffect, useState } from "react";
import SalesChart from "../components/SalesChart";
import StatCard from "../components/StatCard";
import { getTopCustomers, getCustomersByCountry, getCustomerValue } from "../services/api";

export default function CustomerAnalysis() {
    const [top, setTop] = useState([]);
    const [byCountry, setByCountry] = useState([]);
    const [value, setValue] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        Promise.all([getTopCustomers(), getCustomersByCountry(), getCustomerValue()])
            .then(([t, c, v]) => {
                setTop(t.data || []);
                setByCountry(c.data || []);
                setValue(v.data || []);
            })
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="page-loading">Memuat data pelanggan...</div>;

    const chartData = byCountry.slice(0, 10).map((r) => ({
        label: r.country,
        revenue: Number(r.lifetime_value),
    }));

    const totalLTV = value.reduce((a, b) => a + Number(b.lifetime_value || 0), 0);
    const avgLTV = value.length ? totalLTV / value.length : 0;

    return (
        <div className="page">
            <div className="stat-grid">
                <StatCard title="Top Customer" value={top[0]?.customerName?.slice(0, 20) || "-"} icon="🏆" color="#4f46e5" subtitle={`$${Number(top[0]?.lifetime_value || 0).toLocaleString()}`} />
                <StatCard title="Total LTV" value={`$${totalLTV.toLocaleString()}`} icon="💰" color="#16a34a" />
                <StatCard title="Avg LTV" value={`$${avgLTV.toLocaleString(undefined, { maximumFractionDigits: 0 })}`} icon="📊" color="#0891b2" />
                <StatCard title="Countries" value={byCountry.length} icon="🌍" color="#ea580c" />
            </div>

            <SalesChart title="Top 10 Countries by Lifetime Value" data={chartData} type="bar" xKey="label" dataKey="revenue" />

            <div className="table-card">
                <h3>🏆 Top 10 Customers</h3>
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Customer</th>
                            <th>Country</th>
                            <th className="num">Orders</th>
                            <th className="num">Lifetime Value</th>
                        </tr>
                    </thead>
                    <tbody>
                        {top.map((r, i) => (
                            <tr key={r.customerNumber}>
                                <td>{i + 1}</td>
                                <td>{r.customerName}</td>
                                <td>{r.country}</td>
                                <td className="num">{r.order_count}</td>
                                <td className="num">${Number(r.lifetime_value).toLocaleString()}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            <div className="table-card">
                <h3>🌍 Customers by Country</h3>
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Country</th>
                            <th className="num">Customers</th>
                            <th className="num">Orders</th>
                            <th className="num">Lifetime Value</th>
                        </tr>
                    </thead>
                    <tbody>
                        {byCountry.map((r, i) => (
                            <tr key={r.country}>
                                <td>{i + 1}</td>
                                <td>{r.country}</td>
                                <td className="num">{r.customer_count}</td>
                                <td className="num">{r.order_count}</td>
                                <td className="num">${Number(r.lifetime_value).toLocaleString()}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}