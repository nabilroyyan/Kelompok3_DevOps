import axios from "axios";

const api = axios.create({
    baseURL: import.meta.env.VITE_API_URL || "http://localhost:8000/api",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
});

// ===== Dashboard =====
export const getDashboardSummary = () => api.get("/dashboard/summary");

// ===== Sales =====
export const getSalesMonthly = () => api.get("/sales/monthly");
export const getSalesYearly = () => api.get("/sales/yearly");
export const getSalesByCountry = () => api.get("/sales/by-country");

// ===== Products =====
export const getTopSellingProducts = () => api.get("/products/top-selling");
export const getLowSellingProducts = () => api.get("/products/low-selling");
export const getProductProfitability = () => api.get("/products/profitability");

// ===== Customers =====
export const getTopCustomers = () => api.get("/customers/top");
export const getCustomersByCountry = () => api.get("/customers/by-country");
export const getCustomerValue = () => api.get("/customers/value");

// ===== Employees =====
export const getEmployeePerformance = () => api.get("/employees/performance");
export const getEmployeeSales = () => api.get("/employees/sales");

export default api;