<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class SalesController extends Controller
{
	public function monthly()
	{
		$sales = DB::table('orders')
			->join('orderdetails', 'orders.orderNumber', '=', 'orderdetails.orderNumber')
			->whereNotIn('orders.status', ['Cancelled'])
			->selectRaw('EXTRACT(YEAR FROM orders.orderDate) AS year, EXTRACT(MONTH FROM orders.orderDate) AS month')
			->selectRaw('SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS revenue')
			->selectRaw('COUNT(DISTINCT orders.orderNumber) AS order_count')
			->groupByRaw('EXTRACT(YEAR FROM orders.orderDate), EXTRACT(MONTH FROM orders.orderDate)')
			->orderBy('year')
			->orderBy('month')
			->get();

		return response()->json($sales);
	}

	public function yearly()
	{
		$sales = DB::table('orders')
			->join('orderdetails', 'orders.orderNumber', '=', 'orderdetails.orderNumber')
			->whereNotIn('orders.status', ['Cancelled'])
			->selectRaw('EXTRACT(YEAR FROM orders.orderDate) AS year')
			->selectRaw('SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS revenue')
			->selectRaw('COUNT(DISTINCT orders.orderNumber) AS order_count')
			->groupByRaw('EXTRACT(YEAR FROM orders.orderDate)')
			->orderBy('year')
			->get();

		return response()->json($sales);
	}

	public function byCountry()
	{
		$sales = DB::table('customers')
			->join('orders', 'customers.customerNumber', '=', 'orders.customerNumber')
			->join('orderdetails', 'orders.orderNumber', '=', 'orderdetails.orderNumber')
			->whereNotIn('orders.status', ['Cancelled'])
			->select('customers.country')
			->selectRaw('SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS revenue')
			->selectRaw('COUNT(DISTINCT orders.orderNumber) AS order_count')
			->selectRaw('COUNT(DISTINCT customers.customerNumber) AS customer_count')
			->groupBy('customers.country')
			->orderByDesc('revenue')
			->get();

		return response()->json($sales);
	}
}
