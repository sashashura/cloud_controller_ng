#/bin/dash
set -eux
trap "pkill -P $$" EXIT

# Setup IDEs
cp -a -f .devcontainer/library/vscode/.vscode/ .
cp -a -f .devcontainer/library/idea/.idea/ .
cp -a -f .devcontainer/library/idea/cloud_controller_ng.iml .

# Install packages
bundle install &

# CC config
cp -a config/cloud_controller.yml tmp/cloud_controller.yml

yq -i e '.login.url="http://uaa:8080"' tmp/cloud_controller.yml
yq -i e '.login.enabled=true' tmp/cloud_controller.yml

yq -i e '.nginx.use_nginx=true' tmp/cloud_controller.yml
yq -i e '.nginx.instance_socket="/workspaces/cloud_controller_ng/tmp/cloud_controller.sock"' tmp/cloud_controller.yml

yq -i e '.logging.file="/workspaces/cloud_controller_ng/tmp/cloud_controller.log"' tmp/cloud_controller.yml
yq -i e '.telemetry_log_path="/workspaces/cloud_controller_ng/tmp/cloud_controller_telemetry.log"' tmp/cloud_controller.yml
yq -i e '.directories.tmpdir="/workspaces/cloud_controller_ng/tmp"' tmp/cloud_controller.yml
yq -i e '.directories.diagnostics="/workspaces/cloud_controller_ng/tmp"' tmp/cloud_controller.yml
yq -i e '.security_event_logging.enabled=true' tmp/cloud_controller.yml
yq -i e '.security_event_logging.file="/workspaces/cloud_controller_ng/tmp/cef.log"' tmp/cloud_controller.yml

yq -i e '.uaa.url="http://uaa:8080"' tmp/cloud_controller.yml
yq -i e '.uaa.internal_url="http://uaa:8080"' tmp/cloud_controller.yml
yq -i e '.uaa.resource_id="cloud_controller"' tmp/cloud_controller.yml
yq -i e 'del(.uaa.symmetric_secret)' tmp/cloud_controller.yml

yq -i e '.resource_pool.fog_connection.provider="AWS"' tmp/cloud_controller.yml
yq -i e '.resource_pool.fog_connection.endpoint="http://minio:9001"' tmp/cloud_controller.yml
yq -i e '.resource_pool.fog_connection.aws_access_key_id="minioadmin"' tmp/cloud_controller.yml
yq -i e '.resource_pool.fog_connection.aws_secret_access_key="minioadmin"' tmp/cloud_controller.yml
yq -i e '.resource_pool.fog_connection.aws_signature_version=2' tmp/cloud_controller.yml
yq -i e '.resource_pool.fog_connection.path_style=true' tmp/cloud_controller.yml

yq -i e '.packages.fog_connection.provider="AWS"' tmp/cloud_controller.yml
yq -i e '.packages.fog_connection.endpoint="http://minio:9001"' tmp/cloud_controller.yml
yq -i e '.packages.fog_connection.aws_access_key_id="minioadmin"' tmp/cloud_controller.yml
yq -i e '.packages.fog_connection.aws_secret_access_key="minioadmin"' tmp/cloud_controller.yml
yq -i e '.packages.fog_connection.aws_signature_version=2' tmp/cloud_controller.yml
yq -i e '.packages.fog_connection.path_style=true' tmp/cloud_controller.yml

yq -i e '.droplets.fog_connection.provider="AWS"' tmp/cloud_controller.yml
yq -i e '.droplets.fog_connection.endpoint="http://minio:9001"' tmp/cloud_controller.yml
yq -i e '.droplets.fog_connection.aws_access_key_id="minioadmin"' tmp/cloud_controller.yml
yq -i e '.droplets.fog_connection.aws_secret_access_key="minioadmin"' tmp/cloud_controller.yml
yq -i e '.droplets.fog_connection.aws_signature_version=2' tmp/cloud_controller.yml
yq -i e '.droplets.fog_connection.path_style=true' tmp/cloud_controller.yml

yq -i e '.buildpacks.fog_connection.provider="AWS"' tmp/cloud_controller.yml
yq -i e '.buildpacks.fog_connection.endpoint="http://minio:9001"' tmp/cloud_controller.yml
yq -i e '.buildpacks.fog_connection.aws_access_key_id="minioadmin"' tmp/cloud_controller.yml
yq -i e '.buildpacks.fog_connection.aws_secret_access_key="minioadmin"' tmp/cloud_controller.yml
yq -i e '.buildpacks.fog_connection.aws_signature_version=2' tmp/cloud_controller.yml
yq -i e '.buildpacks.fog_connection.path_style=true' tmp/cloud_controller.yml

yq -i e '.cloud_controller_username_lookup_client_name="login"' tmp/cloud_controller.yml
yq -i e '.cloud_controller_username_lookup_client_secret="loginsecret"' tmp/cloud_controller.yml

wait

# Database setup
POSTGRES_CONNECTION_STRING="postgres://postgres:supersecret@postgres:5432/ccdb"
MYSQL_CONNECTION_STRING="mysql2://root:supersecret@mariadb:3306/ccdb"

setupPostgres () {
    export DB="postgres"
    export DB_CONNECTION_STRING="${POSTGRES_CONNECTION_STRING}"
    bundle exec rake db:recreate
    bundle exec rake db:migrate
    bundle exec rake db:seed
}


setupMariadb () {
    export DB="mysql"
    export DB_CONNECTION_STRING="${MYSQL_CONNECTION_STRING}"
    bundle exec rake db:recreate
    bundle exec rake db:migrate
    bundle exec rake db:seed
}

setupPostgres &
setupMariadb &

setupUAA () {
    timeout 300 bash -c 'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://uaa:8080/info)" != "200" ]]; do sleep 5; done' || false
    CF_UAA_ADMIN_CLIENT_SECRET="adminsecret"
    NEW_ADMIN_USERNAME="ccadmin"
    NEW_ADMIN_PASSWORD="secret"
    uaac target http://uaa:8080 --skip-ssl-validation                                     
    uaac token client get admin -s ${CF_UAA_ADMIN_CLIENT_SECRET}                              
    uaac user add ${NEW_ADMIN_USERNAME} -p ${NEW_ADMIN_PASSWORD} --emails fake@example.com
    uaac member add cloud_controller.admin ${NEW_ADMIN_USERNAME}
    uaac member add uaa.admin ${NEW_ADMIN_USERNAME}
    uaac member add scim.read ${NEW_ADMIN_USERNAME}
    uaac member add scim.write ${NEW_ADMIN_USERNAME}

    # Dasboard User
    uaac user add cc-service-dashboards -p some-sekret --emails fake2@example.com
    uaac member add cloud_controller_service_permissions.read cc-service-dashboards
    uaac member add openid cc-service-dashboards
}

setupUAA &

wait
trap "" EXIT