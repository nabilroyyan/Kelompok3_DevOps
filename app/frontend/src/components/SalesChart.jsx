import {
    ResponsiveContainer,
    LineChart,
    Line,
    BarChart,
    Bar,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    Legend,
} from "recharts";

const fmt = (v) =>
    new Intl.NumberFormat("en-US", {
        notation: "compact",
        maximumFractionDigits: 1,
    }).format(v);

export default function SalesChart({ data = [], type = "line", xKey = "label", dataKey = "revenue", title }) {
    const Chart = type === "bar" ? BarChart : LineChart;
    return (
        <div className="chart-card">
            {title && <h3 className="chart-title">{title}</h3>}
            <ResponsiveContainer width="100%" height={320}>
                <Chart data={data} margin={{ top: 10, right: 20, left: 0, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                    <XAxis dataKey={xKey} tick={{ fontSize: 12 }} />
                    <YAxis tickFormatter={fmt} tick={{ fontSize: 12 }} />
                    <Tooltip
                        formatter={(v, n) => [v.toLocaleString("en-US"), n]}
                        contentStyle={{ borderRadius: 8, border: "1px solid #e5e7eb" }}
                    />
                    <Legend />
                    {type === "bar" ? (
                        <Bar dataKey={dataKey} fill="#4f46e5" radius={[6, 6, 0, 0]} name="Revenue" />
                    ) : (
                        <Line
                            type="monotone"
                            dataKey={dataKey}
                            stroke="#4f46e5"
                            strokeWidth={3}
                            dot={{ r: 4 }}
                            activeDot={{ r: 6 }}
                            name="Revenue"
                        />
                    )}
                </Chart>
            </ResponsiveContainer>
        </div>
    );
}