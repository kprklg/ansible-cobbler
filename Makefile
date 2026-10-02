# Makefile — шорткаты для частых команд
# Использование: make <target>

SHELL := /bin/bash

# Дефолтный инвентарь для тестов
INVENTORY ?= inventories/staging/hosts.yml

# Список плейбуков
PLAYBOOKS := \
  playbooks/site.yml \
  playbooks/deploy.yml \
  playbooks/rebuild.yml \
  playbooks/uninstall.yml

.PHONY: help
help: ## Показать список доступных целей
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\n"} \
	    /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } \
	    /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) }' $(MAKEFILE_LIST)

.PHONY: install-deps
install-deps: ## Установить системные зависимости (apt)
	./scripts/install-deps.sh

.PHONY: collections
collections: ## Установить Ansible collections
	ansible-galaxy collection install -r requirements.yml

.PHONY: lint
lint: yamllint ansible-lint ## Запустить все линтеры

.PHONY: yamllint
yamllint: ## Запустить yamllint
	yamllint --strict .

.PHONY: ansible-lint
ansible-lint: ## Запустить ansible-lint
	ansible-galaxy collection install -r requirements.yml --force
	ansible-lint roles/cobbler/ playbooks/ inventories/

.PHONY: syntax-check
syntax-check: ## Ansible syntax-check всех плейбуков
	@for p in $(PLAYBOOKS); do \
		echo ">>> $$p"; \
		ansible-playbook $$p -i $(INVENTORY) --syntax-check || exit 1; \
	done

.PHONY: test
test: lint syntax-check molecule ## Полный прогон тестов

.PHONY: molecule
molecule: ## Molecule-тесты роли
	molecule test -s default

.PHONY: install
install: ## Запустить установку Cobbler (полный playbook)
	ansible-playbook -i $(INVENTORY) playbooks/site.yml $(EXTRA_ARGS)

.PHONY: install-fast
install-fast: ## Установка с пропуском docker build (использовать кэш)
	ansible-playbook -i $(INVENTORY) playbooks/site.yml -e cobbler_skip_builds=true $(EXTRA_ARGS)

.PHONY: rebuild
rebuild: ## Пересобрать Docker-образы
	ansible-playbook -i $(INVENTORY) playbooks/rebuild.yml $(EXTRA_ARGS)

.PHONY: uninstall
uninstall: ## Удалить стек Cobbler
	ansible-playbook -i $(INVENTORY) playbooks/uninstall.yml $(EXTRA_ARGS)

.PHONY: docker-build-test
docker-build-test: ## Собрать тестовый Docker-образ
	docker build -f Dockerfile.test -t ansible-cobbler:test .

.PHONY: docker-run-test
docker-run-test: ## Запустить тестовый контейнер
	docker run --rm -it ansible-cobbler:test bash

.PHONY: status
status: ## Проверить статус контейнеров Cobbler
	@docker ps --filter name=cobbler-stack --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

.PHONY: logs
logs: ## Показать логи всех контейнеров
	cd /opt/cobbler-stack && docker compose logs -f

.PHONY: webui
webui: ## Открыть Web UI в браузере
	@echo "Web UI: http://$$(grep '^hostname:' $(INVENTORY) | head -1 | awk '{print $$2}')"
	@echo "Логин по умолчанию: cobbler / cobbler"

.PHONY: clean
clean: ## Удалить сгенерированные артефакты
	rm -rf .cache/ .ansible/
	find . -name "*.retry" -delete

.PHONY: clean-all
clean-all: clean docker-clean ## Полная очистка (включая docker volumes)

.PHONY: docker-clean
docker-clean: ## Удалить контейнеры и volumes
	cd /opt/cobbler-stack && docker compose down -v

.PHONY: pre-commit
pre-commit: ## Установить и запустить pre-commit хуки
	pre-commit install
	pre-commit run --all-files

.PHONY: release-patch
release-patch: ## Создать patch-файл для передачи
	git format-patch -o /tmp/cobbler-patches $$(git describe --tags --abbrev=0)..HEAD

.PHONY: version
version: ## Показать текущую версию
	@git describe --tags --always

.PHONY: tree
tree: ## Показать структуру роли (исключая .git)
	@find . -type d -name '.git' -prune -o -type f -print | sort | head -50

##@ Documentation

.PHONY: docs
docs: ## Показать все .md файлы репозитория
	@ls -la *.md

##@ Internal

.PHONY: _echo_targets
_echo_targets: ## Отладка: список всех целей
	@$(MAKE) -p 2>/dev/null | grep -E '^[a-zA-Z_-]+:' | awk -F':' '{print $$1}' | sort -u