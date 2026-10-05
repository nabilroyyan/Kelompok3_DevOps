<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\CustomerController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Controllers\Api\SalesController;

Route::get('/dashboard/summary', [DashboardController::class, 'summary']);

Route::get('/sales/monthly', [SalesController::class, 'monthly']);
Route::get('/sales/yearly', [SalesController::class, 'yearly']);
Route::get('/sales/by-country', [SalesController::class, 'byCountry']);

Route::get('/products/top-selling', [ProductController::class, 'topSelling']);
Route::get('/products/low-selling', [ProductController::class, 'lowSelling']);
Route::get('/products/profitability', [ProductController::class, 'profitability']);

Route::get('/customers/top', [CustomerController::class, 'top']);
Route::get('/customers/by-country', [CustomerController::class, 'byCountry']);
Route::get('/customers/value', [CustomerController::class, 'value']);

Route::get('/employees/performance', [EmployeeController::class, 'performance']);
Route::get('/employees/sales', [EmployeeController::class, 'sales']);
