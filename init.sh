mkdir ticketing
cd ./ticketing || exit

git clone https://github.com/dzhuryn97/ticketing-auth auth
git clone https://github.com/dzhuryn97/ticketing-attendance attendance
git clone https://github.com/dzhuryn97/ticketing-events events
git clone https://github.com/dzhuryn97/ticketing-tickets tickets
git clone https://github.com/dzhuryn97/ticketing-infra infra
cd ./infra || exit
cp .env.dist .env
cp docker-compose.local.yaml docker-compose.yaml
cp docker-compose.override.yaml.dist docker-compose.override.yaml
make init-local
open https://localhost