export default function StatCard({ title, value, subtitle, icon, color = "#4f46e5" }) {
    return (
        <div className="stat-card" style={{ "--accent": color }}>
            <div className="stat-card-header">
                <span className="stat-card-title">{title}</span>
                <span className="stat-card-icon">{icon}</span>
            </div>
            <div className="stat-card-value">
                {typeof value === "number" ? value.toLocaleString("en-US") : value}
            </div>
            {subtitle && <div className="stat-card-subtitle">{subtitle}</div>}
        </div>
    );
}