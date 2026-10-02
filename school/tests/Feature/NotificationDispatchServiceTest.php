<?php

namespace Tests\Feature;

use App\Models\Eleve;
use App\Models\Enseignement;
use App\Models\User;
use App\Models\UserDevice;
use App\Services\FcmNotificationService;
use App\Services\NotificationDispatchService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Mockery;
use Tests\TestCase;

class NotificationDispatchServiceTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        config([
            'database.default' => 'sqlite',
            'database.connections.sqlite' => [
                'driver' => 'sqlite',
                'database' => ':memory:',
                'prefix' => '',
            ],
        ]);
        DB::purge('sqlite');

        Schema::create('users', function (Blueprint $table) {
            $table->string('code')->primary();
            $table->string('account_type')->nullable();
            $table->boolean('admin')->default(false);
            $table->string('nom')->nullable();
            $table->string('prenom')->nullable();
            $table->string('CodeEtablissement')->nullable();
            $table->timestamps();
        });

        Schema::create('user_devices', function (Blueprint $table) {
            $table->id();
            $table->string('user_code');
            $table->text('fcm_token');
            $table->string('token_hash', 64)->unique();
            $table->string('platform');
            $table->boolean('is_active')->default(true);
            $table->timestamp('revoked_at')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamp('token_updated_at')->nullable();
            $table->timestamps();
        });

        Schema::create('classes', function (Blueprint $table) {
            $table->string('CodeClasse')->primary();
            $table->string('CodeEtablissement')->nullable();
            $table->string('LibelleClasse')->nullable();
            $table->timestamps();
        });

        Schema::create('eleves', function (Blueprint $table) {
            $table->string('CodeEleve')->primary();
            $table->string('CodeClasse')->nullable();
            $table->string('code')->nullable();
            $table->string('Nom')->nullable();
            $table->string('Prenom')->nullable();
            $table->timestamps();
        });

        Schema::create('enseignements', function (Blueprint $table) {
            $table->string('CodeEnseignement')->primary();
            $table->string('CodeClasse')->nullable();
            $table->string('code')->nullable();
            $table->string('CodeMatiere')->nullable();
            $table->string('CodeEtablissement')->nullable();
            $table->string('CodeEnseignant2')->nullable();
            $table->timestamps();
        });
    }

    public function test_present_status_sends_no_attendance_notification(): void
    {
        User::create(['code' => 'P-1', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'PR-1', 'account_type' => 'principal', 'nom' => 'Principal', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'T-1', 'account_type' => 'enseignant', 'nom' => 'Teacher', 'prenom' => 'One', 'CodeEtablissement' => '16801']);

        UserDevice::create(['user_code' => 'P-1', 'fcm_token' => 'parent-device-token', 'token_hash' => hash('sha256', 'parent-device-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'PR-1', 'fcm_token' => 'principal-device-token', 'token_hash' => hash('sha256', 'principal-device-token'), 'platform' => 'android', 'is_active' => true]);

        Eleve::create(['CodeEleve' => 'E-1', 'CodeClasse' => 'C-1', 'code' => 'P-1', 'Nom' => 'Alice', 'Prenom' => 'Durand']);

        $fcm = Mockery::mock(FcmNotificationService::class);
        $fcm->shouldReceive('sendToUser')->never();

        $service = new NotificationDispatchService($fcm);
        $result = $service->dispatchAttendanceNotification('E-1', '2026-09-29', 'P', 'T-1', ['school_code' => '16801', 'class_code' => 'C-1']);

        $this->assertSame(0, $result['sent']);
    }

    public function test_absent_status_notifies_parent_and_same_school_principal(): void
    {
        User::create(['code' => 'P-1', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        $this->createNonParentAttendanceRecipients();
        User::create(['code' => 'T-1', 'account_type' => 'enseignant', 'nom' => 'Teacher', 'prenom' => 'One', 'CodeEtablissement' => '16801']);

        UserDevice::create(['user_code' => 'P-1', 'fcm_token' => 'parent-device-token', 'token_hash' => hash('sha256', 'parent-device-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'PR-1', 'fcm_token' => 'principal-device-token', 'token_hash' => hash('sha256', 'principal-device-token'), 'platform' => 'android', 'is_active' => true]);

        Eleve::create(['CodeEleve' => 'E-1', 'CodeClasse' => 'C-1', 'code' => 'P-1', 'Nom' => 'Alice', 'Prenom' => 'Durand']);

        $fcm = Mockery::mock(FcmNotificationService::class);
        $fcm->shouldReceive('sendToUser')
            ->once()
            ->with('P-1', 'Absence de votre enfant', Mockery::on(fn ($body) => str_contains($body, 'Alice') && str_contains($body, '2026-09-29')), Mockery::on(function ($data) {
                return ($data['type'] ?? null) === 'attendance'
                    && ($data['student_code'] ?? null) === 'E-1'
                    && ($data['class_code'] ?? null) === 'C-1'
                    && ($data['recipient_role'] ?? null) === 'parent';
            }))
            ->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);
        $fcm->shouldReceive('sendToUser')
            ->once()
            ->with('PR-1', 'Élève absent', Mockery::on(fn ($body) => str_contains($body, 'Alice')), Mockery::on(function ($data) {
                return ($data['type'] ?? null) === 'attendance'
                    && ($data['student_code'] ?? null) === 'E-1'
                    && ($data['school_code'] ?? null) === '16801'
                    && ($data['recipient_role'] ?? null) === 'principal';
            }))
            ->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);

        $service = new NotificationDispatchService($fcm);
        $result = $service->dispatchAttendanceNotification('E-1', '2026-09-29', 'A', 'T-1', ['school_code' => '16801', 'class_code' => 'C-1']);

        $this->assertSame(2, $result['sent']);
    }

    public function test_late_status_notifies_parent_and_same_school_principal(): void
    {
        User::create(['code' => 'P-1', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        $this->createNonParentAttendanceRecipients();
        User::create(['code' => 'T-1', 'account_type' => 'enseignant', 'nom' => 'Teacher', 'prenom' => 'One', 'CodeEtablissement' => '16801']);

        UserDevice::create(['user_code' => 'P-1', 'fcm_token' => 'parent-device-token', 'token_hash' => hash('sha256', 'parent-device-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'PR-1', 'fcm_token' => 'principal-device-token', 'token_hash' => hash('sha256', 'principal-device-token'), 'platform' => 'android', 'is_active' => true]);

        Eleve::create(['CodeEleve' => 'E-1', 'CodeClasse' => 'C-1', 'code' => 'P-1', 'Nom' => 'Alice', 'Prenom' => 'Durand']);

        $fcm = Mockery::mock(FcmNotificationService::class);
        $fcm->shouldReceive('sendToUser')->once()->with('P-1', 'Absence de votre enfant', Mockery::on(fn ($body) => str_contains($body, 'Alice') && str_contains($body, 'en retard')), Mockery::on(function ($data) {
            return ($data['type'] ?? null) === 'attendance'
                && ($data['recipient_role'] ?? null) === 'parent';
        }))->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);
        $fcm->shouldReceive('sendToUser')->once()->with('PR-1', 'Élève en retard', Mockery::on(fn ($body) => str_contains($body, 'en retard')), Mockery::on(function ($data) {
            return ($data['type'] ?? null) === 'attendance'
                && ($data['status'] ?? null) === 'R'
                && ($data['recipient_role'] ?? null) === 'principal';
        }))->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);

        $service = new NotificationDispatchService($fcm);
        $result = $service->dispatchAttendanceNotification('E-1', '2026-09-29', 'R', 'T-1', ['school_code' => '16801', 'class_code' => 'C-1']);

        $this->assertSame(2, $result['sent']);
    }

    public function test_principal_from_another_school_does_not_receive_notification(): void
    {
        User::create(['code' => 'P-1', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'PR-1', 'account_type' => 'principal', 'nom' => 'Principal', 'prenom' => 'One', 'CodeEtablissement' => '99999']);
        User::create(['code' => 'PR-2', 'account_type' => 'principal', 'nom' => 'Principal', 'prenom' => 'Two', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'T-1', 'account_type' => 'enseignant', 'nom' => 'Teacher', 'prenom' => 'One', 'CodeEtablissement' => '16801']);

        UserDevice::create(['user_code' => 'P-1', 'fcm_token' => 'parent-device-token', 'token_hash' => hash('sha256', 'parent-device-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'PR-1', 'fcm_token' => 'principal-device-token', 'token_hash' => hash('sha256', 'principal-device-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'PR-2', 'fcm_token' => 'principal-school-device-token', 'token_hash' => hash('sha256', 'principal-school-device-token'), 'platform' => 'android', 'is_active' => true]);

        Eleve::create(['CodeEleve' => 'E-1', 'CodeClasse' => 'C-1', 'code' => 'P-1', 'Nom' => 'Alice', 'Prenom' => 'Durand']);

        $fcm = Mockery::mock(FcmNotificationService::class);
        $fcm->shouldReceive('sendToUser')->once()->with('P-1', 'Absence de votre enfant', Mockery::on(fn ($body) => str_contains($body, 'Alice')), Mockery::on(function ($data) {
            return ($data['type'] ?? null) === 'attendance' && ($data['recipient_role'] ?? null) === 'parent';
        }))->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);
        $fcm->shouldReceive('sendToUser')->once()->with('PR-2', 'Élève absent', Mockery::on(fn ($body) => str_contains($body, 'Alice')), Mockery::on(function ($data) {
            return ($data['type'] ?? null) === 'attendance' && ($data['recipient_role'] ?? null) === 'principal';
        }))->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);

        $service = new NotificationDispatchService($fcm);
        $result = $service->dispatchAttendanceNotification('E-1', '2026-09-29', 'A', 'T-1', ['school_code' => '16801', 'class_code' => 'C-1']);

        $this->assertSame(2, $result['sent']);
    }

    public function test_attendance_notification_does_not_include_encadreur_or_other_staff(): void
    {
        User::create(['code' => 'P-1', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        $this->createNonParentAttendanceRecipients();
        User::create(['code' => 'T-1', 'account_type' => 'enseignant', 'nom' => 'Teacher', 'prenom' => 'One', 'CodeEtablissement' => '16801']);

        UserDevice::create(['user_code' => 'P-1', 'fcm_token' => 'parent-device-token', 'token_hash' => hash('sha256', 'parent-device-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'PR-1', 'fcm_token' => 'principal-device-token', 'token_hash' => hash('sha256', 'principal-device-token'), 'platform' => 'android', 'is_active' => true]);

        Eleve::create(['CodeEleve' => 'E-1', 'CodeClasse' => 'C-1', 'code' => 'P-1', 'Nom' => 'Alice', 'Prenom' => 'Durand']);

        $fcm = Mockery::mock(FcmNotificationService::class);
        $fcm->shouldReceive('sendToUser')->once()->with('P-1', 'Absence de votre enfant', Mockery::on(fn ($body) => str_contains($body, 'Alice')), Mockery::on(function ($data) {
            return ($data['type'] ?? null) === 'attendance' && ($data['recipient_role'] ?? null) === 'parent';
        }))->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);
        $fcm->shouldReceive('sendToUser')->once()->with('PR-1', 'Élève absent', Mockery::on(fn ($body) => str_contains($body, 'Alice')), Mockery::on(function ($data) {
            return ($data['type'] ?? null) === 'attendance' && ($data['recipient_role'] ?? null) === 'principal';
        }))->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);

        $service = new NotificationDispatchService($fcm);
        $result = $service->dispatchAttendanceNotification('E-1', '2026-09-29', 'A', 'T-1', ['school_code' => '16801', 'class_code' => 'C-1']);

        $this->assertSame(2, $result['sent']);
    }

    public function test_missing_parent_device_does_not_fall_back_to_school_staff(): void
    {
        User::create(['code' => 'P-1', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        $this->createNonParentAttendanceRecipients();
        User::create(['code' => 'T-1', 'account_type' => 'enseignant', 'nom' => 'Teacher', 'prenom' => 'One', 'CodeEtablissement' => '16801']);

        UserDevice::create(['user_code' => 'PR-1', 'fcm_token' => 'principal-device-token', 'token_hash' => hash('sha256', 'principal-device-token'), 'platform' => 'android', 'is_active' => true]);

        Eleve::create(['CodeEleve' => 'E-1', 'CodeClasse' => 'C-1', 'code' => 'P-1', 'Nom' => 'Alice', 'Prenom' => 'Durand']);

        $fcm = Mockery::mock(FcmNotificationService::class);
        $fcm->shouldReceive('sendToUser')->once()->with('P-1', 'Absence de votre enfant', Mockery::on(fn ($body) => str_contains($body, 'Alice')), Mockery::on(function ($data) {
            return ($data['type'] ?? null) === 'attendance' && ($data['recipient_role'] ?? null) === 'parent';
        }))->andReturn(['attempted' => 0, 'succeeded' => 0, 'failed' => 0, 'invalidated' => 0]);
        $fcm->shouldReceive('sendToUser')->once()->with('PR-1', 'Élève absent', Mockery::on(fn ($body) => str_contains($body, 'Alice')), Mockery::on(function ($data) {
            return ($data['type'] ?? null) === 'attendance' && ($data['recipient_role'] ?? null) === 'principal';
        }))->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);

        $service = new NotificationDispatchService($fcm);
        $result = $service->dispatchAttendanceNotification('E-1', '2026-09-29', 'A', 'T-1', ['school_code' => '16801', 'class_code' => 'C-1']);

        $this->assertSame(1, $result['sent']);
    }

    private function createNonParentAttendanceRecipients(): void
    {
        User::create(['code' => 'PR-1', 'account_type' => 'principal', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'ENC-1', 'account_type' => 'encadreur', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'SG-1', 'account_type' => 'surveillant_general', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'ADM-1', 'account_type' => 'administrateur', 'admin' => true, 'CodeEtablissement' => '16801']);
    }

    public function test_homework_dispatches_only_to_parents_of_affected_class(): void
    {
        User::create(['code' => 'P-1', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'P-3', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'Three', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'P-2', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'Two', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'PR-1', 'account_type' => 'principal', 'admin' => true, 'CodeEtablissement' => '16801']);
        User::create(['code' => 'ENC-1', 'account_type' => 'encadreur', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'SG-1', 'account_type' => 'surveillant_general', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'ADM-1', 'account_type' => 'administrateur', 'admin' => true, 'CodeEtablissement' => '16801']);
        User::create(['code' => 'T-1', 'account_type' => 'enseignant', 'nom' => 'Teacher', 'prenom' => 'One', 'CodeEtablissement' => '16801']);

        UserDevice::create(['user_code' => 'P-1', 'fcm_token' => 'p1-token', 'token_hash' => hash('sha256', 'p1-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'P-3', 'fcm_token' => 'p3-token', 'token_hash' => hash('sha256', 'p3-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'P-2', 'fcm_token' => 'p2-token', 'token_hash' => hash('sha256', 'p2-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'PR-1', 'fcm_token' => 'principal-token', 'token_hash' => hash('sha256', 'principal-token'), 'platform' => 'android', 'is_active' => true]);

        Eleve::create(['CodeEleve' => 'E-1', 'CodeClasse' => 'C-1', 'code' => 'P-1', 'Nom' => 'Alice', 'Prenom' => 'Durand']);
        Eleve::create(['CodeEleve' => 'E-3', 'CodeClasse' => 'C-1', 'code' => 'P-3', 'Nom' => 'Charlie', 'Prenom' => 'Diallo']);
        Eleve::create(['CodeEleve' => 'E-2', 'CodeClasse' => 'C-2', 'code' => 'P-2', 'Nom' => 'Bob', 'Prenom' => 'Martin']);
        Eleve::create(['CodeEleve' => 'E-PR', 'CodeClasse' => 'C-1', 'code' => 'PR-1']);
        Eleve::create(['CodeEleve' => 'E-ENC', 'CodeClasse' => 'C-1', 'code' => 'ENC-1']);
        Eleve::create(['CodeEleve' => 'E-SG', 'CodeClasse' => 'C-1', 'code' => 'SG-1']);
        Eleve::create(['CodeEleve' => 'E-ADM', 'CodeClasse' => 'C-1', 'code' => 'ADM-1']);
        Eleve::create(['CodeEleve' => 'E-T', 'CodeClasse' => 'C-1', 'code' => 'T-1']);

        $fcm = Mockery::mock(FcmNotificationService::class);
        $fcm->shouldReceive('sendToUser')
            ->once()
            ->with('P-1', 'Nouveau devoir', Mockery::on(fn ($body) => str_contains($body, 'Math') && str_contains($body, 'Algebra exercises')), Mockery::on(fn ($data) => ($data['type'] ?? null) === 'homework' && ($data['class_code'] ?? null) === 'C-1' && ($data['assignment_title'] ?? null) === 'Algebra exercises'))
            ->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);
        $fcm->shouldReceive('sendToUser')
            ->once()
            ->with('P-3', 'Nouveau devoir', Mockery::on(fn ($body) => str_contains($body, 'Math') && str_contains($body, 'Algebra exercises')), Mockery::on(fn ($data) => ($data['type'] ?? null) === 'homework' && ($data['class_code'] ?? null) === 'C-1' && ($data['assignment_title'] ?? null) === 'Algebra exercises'))
            ->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);

        $service = new NotificationDispatchService($fcm);
        $result = $service->dispatchHomeworkNotification('C-1', 'Math', 'T-1', '16801', 'D-1', 'Algebra exercises');

        $this->assertSame(2, $result['sent']);
    }

    public function test_convocation_dispatches_only_to_selected_student_parent(): void
    {
        User::create(['code' => 'P-1', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'P-2', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'Two', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'T-1', 'account_type' => 'enseignant', 'nom' => 'Teacher', 'prenom' => 'One', 'CodeEtablissement' => '16801']);

        UserDevice::create(['user_code' => 'P-1', 'fcm_token' => 'p1-token', 'token_hash' => hash('sha256', 'p1-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'P-2', 'fcm_token' => 'p2-token', 'token_hash' => hash('sha256', 'p2-token'), 'platform' => 'android', 'is_active' => true]);

        Eleve::create(['CodeEleve' => 'E-1', 'CodeClasse' => 'C-1', 'code' => 'P-1', 'Nom' => 'Alice', 'Prenom' => 'Durand']);
        Eleve::create(['CodeEleve' => 'E-2', 'CodeClasse' => 'C-1', 'code' => 'P-2', 'Nom' => 'Bob', 'Prenom' => 'Martin']);

        $fcm = Mockery::mock(FcmNotificationService::class);
        $fcm->shouldReceive('sendToUser')
            ->once()
            ->with('P-1', 'Convocation', Mockery::on(fn ($body) => str_contains($body, 'Alice')), Mockery::on(fn ($data) => ($data['type'] ?? null) === 'convocation' && ($data['student_code'] ?? null) === 'E-1'))
            ->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);

        $service = new NotificationDispatchService($fcm);
        $result = $service->dispatchConvocationNotification(['E-1'], 'T-1', ['school_code' => '16801', 'class_code' => 'C-1']);

        $this->assertSame(1, $result['sent']);
    }

    public function test_absence_justification_dispatched_only_to_responsible_teacher(): void
    {
        User::create(['code' => 'P-1', 'account_type' => 'parent', 'nom' => 'Parent', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'T-1', 'account_type' => 'enseignant', 'nom' => 'Teacher', 'prenom' => 'One', 'CodeEtablissement' => '16801']);
        User::create(['code' => 'T-2', 'account_type' => 'enseignant', 'nom' => 'Teacher', 'prenom' => 'Two', 'CodeEtablissement' => '16801']);

        UserDevice::create(['user_code' => 'T-1', 'fcm_token' => 'teacher-token', 'token_hash' => hash('sha256', 'teacher-token'), 'platform' => 'android', 'is_active' => true]);
        UserDevice::create(['user_code' => 'T-2', 'fcm_token' => 'teacher2-token', 'token_hash' => hash('sha256', 'teacher2-token'), 'platform' => 'android', 'is_active' => true]);

        Eleve::create(['CodeEleve' => 'E-1', 'CodeClasse' => 'C-1', 'code' => 'P-1', 'Nom' => 'Alice', 'Prenom' => 'Durand']);
        Enseignement::create(['CodeEnseignement' => 'ENS-1', 'CodeClasse' => 'C-1', 'code' => 'T-1', 'CodeMatiere' => 'MAT-1', 'CodeEtablissement' => '16801']);
        Enseignement::create(['CodeEnseignement' => 'ENS-2', 'CodeClasse' => 'C-2', 'code' => 'T-2', 'CodeMatiere' => 'MAT-2', 'CodeEtablissement' => '16801']);

        $fcm = Mockery::mock(FcmNotificationService::class);
        $fcm->shouldReceive('sendToUser')
            ->once()
            ->with('T-1', 'Justification d\'absence', Mockery::on(fn ($body) => str_contains($body, 'Alice')), Mockery::on(fn ($data) => ($data['type'] ?? null) === 'absence_justification' && ($data['student_code'] ?? null) === 'E-1'))
            ->andReturn(['attempted' => 1, 'succeeded' => 1, 'failed' => 0, 'invalidated' => 0]);

        $service = new NotificationDispatchService($fcm);
        $result = $service->dispatchAbsenceJustificationNotification('E-1', 'P-1', ['school_code' => '16801']);

        $this->assertSame(1, $result['sent']);
    }
}
