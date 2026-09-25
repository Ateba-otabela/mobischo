<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        $users = [
            [
                'code' => 'USR-ADMIN-001',
                'nom' => 'Admin',
                'prenom' => 'School',
                'sex' => 'M',
                'contacts' => '690000001',
                'login' => 'admin',
                'account_type' => 'administrateur',
                'admin' => true,
                'password' => 'Admin@2026!',
            ],
            [
                'code' => 'USR-USER-001',
                'nom' => 'User',
                'prenom' => 'General',
                'sex' => 'M',
                'contacts' => '690000002',
                'login' => 'user',
                'account_type' => 'parent',
                'admin' => false,
                'password' => 'User@2026!',
            ],
            [
                'code' => 'USR-STUDENT-001',
                'nom' => 'Student',
                'prenom' => 'Demo',
                'sex' => 'M',
                'contacts' => '690000003',
                'login' => 'student',
                'account_type' => 'eleve',
                'admin' => false,
                'password' => 'Student@2026!',
            ],
            [
                'code' => 'USR-TEACHER-001',
                'nom' => 'Teacher',
                'prenom' => 'Demo',
                'sex' => 'M',
                'contacts' => '690000004',
                'login' => 'teacher',
                'account_type' => 'enseignant',
                'admin' => false,
                'password' => 'Teacher@2026!',
            ],
        ];

        foreach ($users as $user) {
            User::updateOrCreate(
                ['code' => $user['code']],
                [
                    'nom' => $user['nom'],
                    'prenom' => $user['prenom'],
                    'sex' => $user['sex'],
                    'contacts' => $user['contacts'],
                    'login' => $user['login'],
                    'account_type' => $user['account_type'],
                    'admin' => $user['admin'],
                    'text_password' => $user['password'],
                    'password' => Hash::make($user['password']),
                ]
            );
        }
    }
}
