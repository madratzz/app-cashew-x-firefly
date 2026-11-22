<?php
// Creates a throwaway owner user and prints a personal access token (A7).
// Usage: php mint.php <email> <password>. Used by up.sh; Firefly 6.6.2 ships
// without tinker, and Passport 13 has no personal_access_client column, so a
// missing personal client is created with passport:client --personal.
require '/var/www/html/vendor/autoload.php';
$app = require '/var/www/html/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
[$_, $email, $pw] = $argv;
$u = FireflyIII\User::create(['email' => $email, 'password' => bcrypt($pw), 'blocked' => false]);
$u->roles()->attach(FireflyIII\Models\Role::where('name', 'owner')->first());
try { $t = $u->createToken('e2e')->accessToken; }
catch (Throwable $e) {
    Illuminate\Support\Facades\Artisan::call('passport:client', ['--personal' => true, '--name' => 'e2e', '--provider' => 'users', '--no-interaction' => true]);
    $t = $u->fresh()->createToken('e2e')->accessToken;
}
echo $t, PHP_EOL;
