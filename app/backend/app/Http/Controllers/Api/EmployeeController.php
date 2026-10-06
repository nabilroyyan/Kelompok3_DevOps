<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class EmployeeController extends Controller
{
	public function performance()
	{
		$employees = $this->employeeSales()
			->selectRaw('COUNT(DISTINCT customers.customerNumber) AS customer_count')
			->selectRaw('COUNT(DISTINCT orders.orderNumber) AS order_count')
			->selectRaw('SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS revenue')
			->groupBy('employees.employeeNumber', 'employees.firstName', 'employees.lastName', 'employees.jobTitle')
			->orderByDesc('revenue')
			->get();

		return response()->json($employees);
	}

	public function sales()
	{
		$employees = $this->employeeSales()
			->selectRaw('COUNT(DISTINCT orders.orderNumber) AS order_count')
			->selectRaw('SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS revenue')
			->groupBy('employees.employeeNumber', 'employees.firstName', 'employees.lastName', 'employees.jobTitle')
			->orderByDesc('revenue')
			->get();

		return response()->json($employees);
	}

	private function employeeSales()
	{
		return DB::table('employees')
			->join('customers', 'customers.salesRepEmployeeNumber', '=', 'employees.employeeNumber')
			->join('orders', 'orders.customerNumber', '=', 'customers.customerNumber')
			->join('orderdetails', 'orderdetails.orderNumber', '=', 'orders.orderNumber')
			->whereNotIn('orders.status', ['Cancelled'])
			->select('employees.employeeNumber', 'employees.firstName', 'employees.lastName', 'employees.jobTitle');
	}
}
