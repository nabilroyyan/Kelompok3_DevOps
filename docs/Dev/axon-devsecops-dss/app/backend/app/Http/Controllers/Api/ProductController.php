<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Database\Query\JoinClause;
use Illuminate\Support\Facades\DB;

class ProductController extends Controller
{
	public function topSelling()
	{
		$products = DB::table('products')
			->join('orderdetails', 'products.productCode', '=', 'orderdetails.productCode')
			->join('orders', 'orderdetails.orderNumber', '=', 'orders.orderNumber')
			->whereNotIn('orders.status', ['Cancelled'])
			->select('products.productCode', 'products.productName')
			->selectRaw('SUM(orderdetails.quantityOrdered) AS units_sold')
			->selectRaw('SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS revenue')
			->groupBy('products.productCode', 'products.productName')
			->orderByDesc('units_sold')
			->limit(10)
			->get();

		return response()->json($products);
	}

	public function lowSelling()
	{
		$products = DB::table('products')
			->leftJoin('orderdetails', 'products.productCode', '=', 'orderdetails.productCode')
			->leftJoin('orders', function (JoinClause $join) {
				$join->on('orders.orderNumber', '=', 'orderdetails.orderNumber')
					->whereNotIn('orders.status', ['Cancelled']);
			})
			->select('products.productCode', 'products.productName')
			->selectRaw('COALESCE(SUM(CASE WHEN orders.orderNumber IS NULL THEN 0 ELSE orderdetails.quantityOrdered END), 0) AS units_sold')
			->selectRaw('COALESCE(SUM(CASE WHEN orders.orderNumber IS NULL THEN 0 ELSE orderdetails.quantityOrdered * orderdetails.priceEach END), 0) AS revenue')
			->groupBy('products.productCode', 'products.productName')
			->orderBy('units_sold')
			->limit(10)
			->get();

		return response()->json($products);
	}

	public function profitability()
	{
		$products = DB::table('products')
			->leftJoin('orderdetails', 'products.productCode', '=', 'orderdetails.productCode')
			->leftJoin('orders', function (JoinClause $join) {
				$join->on('orders.orderNumber', '=', 'orderdetails.orderNumber')
					->whereNotIn('orders.status', ['Cancelled']);
			})
			->select('products.productCode', 'products.productName')
			->selectRaw('COALESCE(SUM(CASE WHEN orders.orderNumber IS NULL THEN 0 ELSE orderdetails.quantityOrdered * orderdetails.priceEach END), 0) AS revenue')
			->selectRaw('COALESCE(SUM(CASE WHEN orders.orderNumber IS NULL THEN 0 ELSE orderdetails.quantityOrdered * (orderdetails.priceEach - products.buyPrice) END), 0) AS profit')
			->selectRaw('CASE WHEN SUM(CASE WHEN orders.orderNumber IS NULL THEN 0 ELSE orderdetails.quantityOrdered * orderdetails.priceEach END) = 0 THEN 0 ELSE SUM(CASE WHEN orders.orderNumber IS NULL THEN 0 ELSE orderdetails.quantityOrdered * (orderdetails.priceEach - products.buyPrice) END) / SUM(CASE WHEN orders.orderNumber IS NULL THEN 0 ELSE orderdetails.quantityOrdered * orderdetails.priceEach END) * 100 END AS gross_margin_percent')
			->groupBy('products.productCode', 'products.productName')
			->orderByDesc('profit')
			->get();

		return response()->json($products);
	}
}
