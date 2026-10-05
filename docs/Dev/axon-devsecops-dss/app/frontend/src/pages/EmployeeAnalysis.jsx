import { useEffect, useState } from "react";
import SalesChart from "../components/SalesChart";
import StatCard from "../components/StatCard";
import { getEmployeePerformance, getEmployeeSales } from "../services/api";

export default function EmployeeAnalysis() {
    const [perf, setPerf] = useState([]);
    const [sales, setSales] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        Promise.all([getEmployeePerformance(), getEmployeeSales()])
            .then(([p, s]) => {
                setPerf(p.data || []);
                setSales(s.data || []);
            })
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="page-loading">Memuat data karyawan...</div>;

    const chartData = sales.slice(0, 10).map((r) => ({
        label: `${r.firstName} ${r.lastName?.[0] ?? ""}.`,
        revenue: Number(r.revenue),
    }));

    const totalRevenue = sales.reduce((a, b) => a + Number(b.revenue || 0), 0);
    const topRep = sales[0];

    return (
        <div className="page">
            <div className="stat-grid">
                <StatCard title="Top Sales Rep" value={topRep ? `${topRep.firstName} ${topRep.lastName}` : "-"} icon="🏆" color="#16a34a" subtitle={`$${Number(topRep?.revenue || 0).toLocaleString()}`} />
                <StatCard title="Total Employees" value={sales.length} icon="🧑‍💼" color="#4f46e5" />
                <StatCard title="Total Revenue" value={`$${totalRevenue.toLocaleString()}`} icon="💰" color="#0891b2" />
                <StatCard title="Avg Revenue" value={`$${(totalRevenue / (sales.length || 1)).toLocaleString(undefined, { maximumFractionDigits: 0 })}`} icon="📊" color="#ea580c" />
            </div>

            <SalesChart title="Top 10 Sales Rep by Revenue" data={chartData} type="bar" xKey="label" dataKey="revenue" />

            <div className="table-card">
                <h3>🧑‍💼 Employee Performance</h3>
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Name</th>
                            <th>Job Title</th>
                            <th className="num">Customers</th>
                            <th className="num">Orders</th>
                            <th className="num">Revenue</th>
                        </tr>
                    </thead>
                    <tbody>
                        {perf.map((r, i) => (
                            <tr key={r.employeeNumber}>
                                <td>{i + 1}</td>
                                <td>{r.firstName} {r.lastName}</td>
                                <td>{r.jobTitle}</td>
                                <td className="num">{r.customer_count}</td>
                                <td className="num">{r.order_count}</td>
                                <td className="num">${Number(r.revenue).toLocaleString()}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}