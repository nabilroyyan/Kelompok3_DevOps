import { NavLink } from "react-router-dom";

const menu = [
    {
        label: "Dashboard",
        end: true,
        icon: "",
        children: [
            { to: "/overview", label: "Overview", icon: "📊" },
            { to: "/sales", label: "Sales Analysis", icon: "💰" },
            { to: "/products", label: "Product Analysis", icon: "📦" },
            { to: "/customers", label: "Customer Analysis", icon: "👥" },
            { to: "/employees", label: "Employee Analysis", icon: "🧑‍💼" },
        ],
    },
];

export default function Sidebar() {
    return (
        <aside className="sidebar">
            <div className="sidebar-brand">
                <span className="brand-dot" />
                <div>
                    <h1>Axon DSS</h1>
                    <small>DevSecOps Analytics</small>
                </div>
            </div>

            <nav className="sidebar-nav">
                {menu.map((chapter) => (
                    <div key={chapter.to} className="sidebar-section">
                        <div className="sidebar-link sidebar-chapter">
                            <span className="icon">{chapter.icon}</span>
                            <span style={{ fontSize: "1.15rem", fontWeight: 700, textAlign: "left" }}>
                                {chapter.label}
                            </span>
                        </div>
                        {chapter.children && (
                            <div className="sidebar-submenu">
                                {chapter.children.map((item) => (
                                    <NavLink
                                        key={item.to}
                                        to={item.to}
                                        className={({ isActive }) =>
                                            "sidebar-link sidebar-subchapter" + (isActive ? " active" : "")
                                        }
                                    >
                                        <span className="icon">{item.icon}</span>
                                        <span>{item.label}</span>
                                    </NavLink>
                                ))}
                            </div>
                        )}
                    </div>
                ))}
            </nav>

            <div className="sidebar-footer">
                <small>© {new Date().getFullYear()} Axon</small>
            </div>
        </aside>
    );
}