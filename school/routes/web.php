<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;
use App\Http\Controllers\EleveController;
use App\Http\Controllers\AcademicController;
use App\Http\Controllers\EtablissementController;
use App\Http\Controllers\AdministrationController;
use App\Http\Controllers\API;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', function () {
    return view('welcome');
});

Route::get('/privacy', function () {
    return view('privacy');
});

Auth::routes();

Route::post('/login.php', [API::class, 'mobileLogin'])
    ->withoutMiddleware([\App\Http\Middleware\VerifyCsrfToken::class]);

Route::get('/home', [App\Http\Controllers\HomeController::class, 'index'])->name('home');
Route::get('/myaccount', [App\Http\Controllers\HomeController::class, 'myaccount'])->name('myaccount');
Route::post('/update_password', [App\Http\Controllers\HomeController::class, 'update_password'])->name('update_password');

// student controller

#user routes
Route::get('/add_user', [UserController::class, 'add_user'])->name('add_user');
Route::post('/add_user_complete', [UserController::class, 'add_user_complete'])->name('add_user_complete');
Route::post('/save_user/{user_id}', [UserController::class, 'save_user'])->name('save_user');
Route::get('/assign_student_choose_class/{parent_id}', [UserController::class, 'assign_student_choose_class'])->name('assign_student_choose_class');
Route::get('/choose_student/{parent_id}', [UserController::class, 'choose_student'])->name('choose_student');
Route::get('/assign_student_complete/{parent_id}/{student_id}/{code_annee}', [UserController::class, 'assign_student_complete'])->name('assign_student_complete');
Route::get('/assign_student_complete/{parent_id}/{student_id}/{code_annee}', [UserController::class, 'assign_student_complete'])->name('assign_student_complete');
Route::get('/remove_student/{parent_id}/{student_id}/', [UserController::class, 'remove_student'])->name('remove_student');
Route::post('/import_users', [UserController::class, 'import_users'])->name('import_users');


#school routes
Route::get('/add_school', [EtablissementController::class, 'add_school'])->name('add_school');
Route::post('/add_school_complete', [EtablissementController::class, 'add_school_complete'])->name('add_school_complete');
Route::post('/save_school/{school_id}', [EtablissementController::class, 'save_school'])->name('save_school');
Route::get('/delete_school/{school_id}', [EtablissementController::class, 'delete_school'])->name('delete_school');
Route::post('/import_schools', [EtablissementController::class, 'import_schools'])->name('import_schools');


#academic_controller
Route::get('/add_year',[AcademicController::class,'add_year'])->name('add_year');
Route::post('/save_year/{year_id}',[AcademicController::class,'save_year'])->name('save_year');
Route::get('/delete_year/{year_id}',[AcademicController::class,'delete_year'])->name('delete_year');
Route::post('/add_year_complete',[AcademicController::class,'add_year_complete'])->name('add_year_complete');
Route::get('/sequence_evaluation',[AcademicController::class,'sequence_evaluation'])->name('sequence_evaluation');
Route::get('/course_home',[AcademicController::class,'course_home'])->name('course_home');
Route::get('/courses',[AcademicController::class,'courses'])->name('courses');
Route::get('/enseignement_home',[AcademicController::class,'enseignement_home'])->name('enseignement_home');
Route::get('/enseignements',[AcademicController::class,'enseignements'])->name('enseignements');
Route::get('/sorted_enseignements',[AcademicController::class,'sorted_enseignements'])->name('sorted_enseignements');
Route::get('/notes_home',[AcademicController::class,'notes_home'])->name('notes_home');
Route::get('/notes/{CodeClasse}/{CodeEtablissement}',[AcademicController::class,'notes'])->name('notes');
Route::get('/notes_choose_class',[AcademicController::class,'notes_choose_class'])->name('notes_choose_class');
Route::get('/sorted_notes',[AcademicController::class,'sorted_notes'])->name('sorted_notes');
Route::post('/import_classes', [AcademicController::class, 'import_classes'])->name('import_classes');
Route::post('/import_courses', [AcademicController::class, 'import_courses'])->name('import_courses');
Route::post('/import_notes', [AcademicController::class, 'import_notes'])->name('import_notes');
Route::post('/import_enseignements', [AcademicController::class, 'import_enseignements'])->name('import_enseignements');
Route::post('/import_years', [AcademicController::class, 'import_years'])->name('import_years');
Route::post('/import_sequences', [AcademicController::class, 'import_sequences'])->name('import_sequences');

#class controller
Route::get('add_class',[AcademicController::class, 'add_class'])->name('add_class');
Route::post('add_class_complete',[AcademicController::class, 'add_class_complete'])->name('add_class_complete');
Route::post('save_class/{class_id}',[AcademicController::class, 'save_class'])->name('save_class');
Route::get('delete_class/{class_id}',[AcademicController::class, 'delete_class'])->name('delete_class');

#student controller
Route::get('add_student_home',[EleveController::class, 'add_student_home'])->name('add_student_home');
Route::get('add_student',[EleveController::class, 'add_student'])->name('add_student');
Route::get('sorted_students/',[EleveController::class, 'sorted_students'])->name('sorted_students');
Route::post('/import_students', [EleveController::class, 'import_students'])->name('import_students');


#administration routes

Route::get('tranches_scholarites_home/',[AdministrationController::class,'tranches_scholarites_home'])->name('tranches_scholarites_home');
Route::get('tranches/',[AdministrationController::class,'tranches'])->name('tranches');
Route::get('inscriptions_home/',[AdministrationController::class,'inscriptions_home'])->name('inscriptions_home');
Route::get('inscriptions/',[AdministrationController::class,'inscriptions'])->name('inscriptions');
Route::post('sorted_inscriptions/',[AdministrationController::class,'sorted_inscriptions'])->name('sorted_inscriptions');
Route::get('historique_inscriptions_home/',[AdministrationController::class,'historique_inscriptions_home'])->name('historique_inscriptions_home');
Route::get('historique_inscriptions/',[AdministrationController::class,'historique_inscriptions'])->name('historique_inscriptions');
Route::post('sorted_historique_inscriptions/',[AdministrationController::class,'sorted_historique_inscriptions'])->name('sorted_historique_inscriptions');
Route::post('/import_tranches', [AdministrationController::class, 'import_tranches'])->name('import_tranches');
Route::post('/import_inscriptions', [AdministrationController::class, 'import_inscriptions'])->name('import_inscriptions');
Route::post('/import_historique_inscriptions', [AdministrationController::class, 'import_historique_inscriptions'])->name('import_historique_inscriptions');
