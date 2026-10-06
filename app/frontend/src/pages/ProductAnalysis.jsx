import { useEffect, useState } from "react";
import SalesChart from "../components/SalesChart";
import StatCard from "../components/StatCard";
import {
    getTopSellingProducts,
    getLowSellingProducts,
    getProductProfitability,
} from "../services/api";

export default function ProductAnalysis() {
    const [top, setTop] = useState([]);
    const [low, setLow] = useState([]);
    const [profit, setProfit] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        Promise.all([
            getTopSellingProducts(),
            getLowSellingProducts(),
            getProductProfitability(),
        ])
            .then(([t, l, p]) => {
                setTop(t.data || []);
                setLow(l.data || []);
                setProfit(p.data || []);
            })
            .finally(() => setLoading(false));
    }, []);

    if (loading) return <div className="page-loading">Memuat data produk...</div>;

    const chartData = top.map((r) => ({
        label: r.productName?.slice(0, 18) || r.productCode,
        revenue: Number(r.revenue),
        units: Number(r.units_sold),
    }));

    return (
        <div className="page">
            <div className="stat-grid">
                <StatCard title="Top Product" value={top[0]?.productName?.slice(0, 20) || "-"} icon="🏆" color="#16a34a" subtitle={`${top[0]?.units_sold ?? 0} unit terjual`} />
                <StatCard title="Best Profit Product" value={profit[0]?.productName?.slice(0, 20) || "-"} icon="💎" color="#4f46e5" subtitle={`$${Number(profit[0]?.profit || 0).toLocaleString()}`} />
                <StatCard title="Avg Margin (Top)" value={`${(profit.slice(0, 5).reduce((a, b) => a + Number(b.gross_margin_percent || 0), 0) / 5).toFixed(1)}%`} icon="📈" color="#0891b2" />
                <StatCard title="Products Analyzed" value={profit.length} icon="📦" color="#ea580c" />
            </div>

            <SalesChart title="Top 10 Produk Terlaris (Revenue)" data={chartData} type="bar" xKey="label" dataKey="revenue" />

            <div className="table-grid">
                <div className="table-card">
                    <h3>🔥 Top Selling Products</h3>
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Product</th>
                                <th className="num">Units</th>
                                <th className="num">Revenue</th>
                            </tr>
                        </thead>
                        <tbody>
                            {top.map((r, i) => (
                                <tr key={r.productCode}>
                                    <td>{i + 1}</td>
                                    <td>{r.productName}</td>
                                    <td className="num">{Number(r.units_sold).toLocaleString()}</td>
                                    <td className="num">${Number(r.revenue).toLocaleString()}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>

                <div className="table-card">
                    <h3>🐌 Low Selling Products</h3>
                    <table className="data-table">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Product</th>
                                <th className="num">Units</th>
                                <th className="num">Revenue</th>
                            </tr>
                        </thead>
                        <tbody>
                            {low.map((r, i) => (
                                <tr key={r.productCode}>
                                    <td>{i + 1}</td>
                                    <td>{r.productName}</td>
                                    <td className="num">{Number(r.units_sold).toLocaleString()}</td>
                                    <td className="num">${Number(r.revenue).toLocaleString()}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>

            <div className="table-card">
                <h3>💎 Profitability</h3>
                <table className="data-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Product</th>
                            <th className="num">Revenue</th>
                            <th className="num">Profit</th>
                            <th className="num">Margin %</th>
                        </tr>
                    </thead>
                    <tbody>
                        {profit.slice(0, 20).map((r, i) => (
                            <tr key={r.productCode}>
                                <td>{i + 1}</td>
                                <td>{r.productName}</td>
                                <td className="num">${Number(r.revenue).toLocaleString()}</td>
                                <td className="num">${Number(r.profit).toLocaleString()}</td>
                                <td className="num">{Number(r.gross_margin_percent).toFixed(2)}%</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}