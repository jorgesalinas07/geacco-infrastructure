up:
	docker compose build && docker-compose up && statics

migrations:
	docker compose exec backend python3 manage.py makemigrations

restart:
	docker compose restart backend

migrate:
	docker compose exec backend python3 manage.py migrate

collectstatic:
	docker compose exec backend python3 manage.py collectstatic

down:
	docker compose down

admin:
	docker compose exec backend python3 manage.py createsuperuser

statics:
	docker compose exec backend python3 manage.py collectstatic --noinput

cities:
	docker compose exec backend python3 manage.py cities_light

setup: migrate cities admin

mm: migrations migrate

sm:
	docker compose exec backend python3 manage.py showmigrations

app:
	docker compose exec backend python3 manage.py startapp $(name) && mv $(name) apps/$(name)

build_push:
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(registry)
	docker build -t abclick .
	docker tag abclick:latest $(registry)/abclick:latest
	docker push $(registry)/abclick:latest

build_and_deploy_image:
	docker build -t ${ECR_REGISTRY}/${ECR_NAME}${ENVIRONMENT_SUFFIX}:$(ECR_TAG) -f Dockerfile .
	@echo "Project image builded!"

	docker push ${ECR_REGISTRY}/${ECR_NAME}${ENVIRONMENT_SUFFIX}:$(ECR_TAG)
	@echo "Project image pushed!"
