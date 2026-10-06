import { useEffect, useState } from "react";
import { useLocation } from "react-router-dom";

const titles = {
    "/": "Dashboard",
    "/overview": "Overview",
    "/sales": "Sales Analysis",
    "/products": "Product Analysis",
    "/customers": "Customer Analysis",
    "/employees": "Employee Analysis",
};

export default function Navbar() {
    const { pathname } = useLocation();
    const [now, setNow] = useState(new Date());

    useEffect(() => {
        const t = setInterval(() => setNow(new Date()), 1000);
        return () => clearInterval(t);
    }, []);

    return (
        <header className="navbar">
            <div>
                <h2 className="navbar-title">{titles[pathname] || "Dashboard"}</h2>
                <p className="navbar-subtitle">
                    Decision Support System — Classicmodels Analytics
                </p>
            </div>

            <div className="navbar-right">
                <span className="navbar-clock">
                    {now.toLocaleDateString("id-ID", {
                        weekday: "long",
                        day: "numeric",
                        month: "long",
                        year: "numeric",
                    })}
                </span>
                <div className="avatar">AD</div>
            </div>
        </header>
    );
}