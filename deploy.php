<?php
namespace Deployer;

require 'recipe/symfony.php';

// Config

set('repository', 'git@github.com:BitScout/symfony_docker_template.git');

add('shared_files', ['.env']);
add('shared_dirs', ['var/cache/httpclient']);
add('writable_dirs', []);

set('keep_releases', 1);

set('composer_options', '--verbose --prefer-dist --no-progress --no-interaction --no-dev --optimize-autoloader --no-scripts');

// Hosts

host('my_web_host.net')
    ->setLabels(['stage' => 'prod'])
    ->setDeployPath('/var/www/my_symfony_project')
    ->setRemoteUser('deployer')
    ->setPort(18503);

// Tasks

task('deploy:vendors', function () {
    if (!commandExist('unzip')) {
        warning('To speed up composer installation setup "unzip" command with PHP zip extension.');
    }
    run('cd {{release_or_current_path}} && {{bin/composer}} {{composer_action}} {{composer_options}} 2>&1');
});

task('database:migrate', function () {
    run('cd {{release_or_current_path}} && symfony console doctrine:migrations:migrate --no-interaction 2>&1');
});

task('deploy:cache:clear', function () {
    run('cd {{release_or_current_path}} && symfony console cache:clear --env=prod 2>&1');
});

after('deploy:vendors', 'deploy:cache:clear');
after('deploy:vendors', 'database:migrate');
after('deploy:failed', 'deploy:unlock');
