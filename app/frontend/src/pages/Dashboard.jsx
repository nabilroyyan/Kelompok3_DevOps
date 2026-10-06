import { Routes, Route, Navigate } from "react-router-dom";
import Sidebar from "../components/Sidebar";
import Navbar from "../components/Navbar";
import Overview from "./Overview";
import SalesAnalysis from "./SalesAnalysis";
import ProductAnalysis from "./ProductAnalysis";
import CustomerAnalysis from "./CustomerAnalysis";
import EmployeeAnalysis from "./EmployeeAnalysis";

export default function Dashboard() {
    return (
        <div className="app-shell">
            <Sidebar />
            <main className="app-main">
                <Navbar />
                <div className="app-content">
                    <Routes>
                        <Route path="/" element={<Navigate to="/overview" replace />} />
                        <Route path="/overview" element={<Overview />} />
                        <Route path="/sales" element={<SalesAnalysis />} />
                        <Route path="/products" element={<ProductAnalysis />} />
                        <Route path="/customers" element={<CustomerAnalysis />} />
                        <Route path="/employees" element={<EmployeeAnalysis />} />
                        <Route path="*" element={<Navigate to="/overview" replace />} />
                    </Routes>
                </div>
            </main>
        </div>
    );
}