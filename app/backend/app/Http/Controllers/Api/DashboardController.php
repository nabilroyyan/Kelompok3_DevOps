<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function summary()
    {
        $totalCustomers = DB::table('customers')->count();
        $totalProducts = DB::table('products')->count();
        $totalOrders = DB::table('orders')->count();

        return response()->json([
            'total_customers' => $totalCustomers,
            'total_products' => $totalProducts,
            'total_orders' => $totalOrders,
        ]);
    }
}
