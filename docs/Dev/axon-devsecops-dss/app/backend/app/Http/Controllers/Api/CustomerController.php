<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Database\Query\JoinClause;
use Illuminate\Support\Facades\DB;

class CustomerController extends Controller
{
	public function top()
	{
		$customers = $this->customerValues()
			->havingRaw('COALESCE(SUM(orderdetails.quantityOrdered * orderdetails.priceEach), 0) > 0')
			->orderByDesc('lifetime_value')
			->limit(10)
			->get();

		return response()->json($customers);
	}

	public function byCountry()
	{
		$customers = DB::table('customers')
			->leftJoin('orders', function (JoinClause $join) {
				$join->on('orders.customerNumber', '=', 'customers.customerNumber')
					->whereNotIn('orders.status', ['Cancelled']);
			})
			->leftJoin('orderdetails', 'orders.orderNumber', '=', 'orderdetails.orderNumber')
			->select('customers.country')
			->selectRaw('COUNT(DISTINCT customers.customerNumber) AS customer_count')
			->selectRaw('COUNT(DISTINCT orders.orderNumber) AS order_count')
			->selectRaw('COALESCE(SUM(orderdetails.quantityOrdered * orderdetails.priceEach), 0) AS lifetime_value')
			->groupBy('customers.country')
			->orderByDesc('customer_count')
			->get();

		return response()->json($customers);
	}

	public function value()
	{
		return response()->json($this->customerValues()->orderByDesc('lifetime_value')->get());
	}

	private function customerValues()
	{
		return DB::table('customers')
			->leftJoin('orders', function (JoinClause $join) {
				$join->on('orders.customerNumber', '=', 'customers.customerNumber')
					->whereNotIn('orders.status', ['Cancelled']);
			})
			->leftJoin('orderdetails', 'orders.orderNumber', '=', 'orderdetails.orderNumber')
			->select('customers.customerNumber', 'customers.customerName', 'customers.country')
			->selectRaw('COUNT(DISTINCT orders.orderNumber) AS order_count')
			->selectRaw('COALESCE(SUM(orderdetails.quantityOrdered * orderdetails.priceEach), 0) AS lifetime_value')
			->groupBy('customers.customerNumber', 'customers.customerName', 'customers.country');
	}
}
