MAKEFLAGS += --no-print-directory
SHELL := /bin/bash

.PHONY: all pre clean clean_get get build upgrade code code_watch

##

help: ## All available commands.
		@IFS=$$'\n' ; \
		help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//'`); \
		for help_line in $${help_lines[@]}; do \
						IFS=$$'#' ; \
						help_split=($$help_line) ; \
						help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
						help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
						printf "%-30s    %s\n" $$help_command $$help_info ; \
		done

##
## --- Basic ---

all: pre ## Run the default task.

pre: ## Run the pre-command.
		@make clean_get
		@make code

clean: ## Clean the environment.
		@printf "🧹 Cleaning the project...\n"
		@rm -rf pubspec.lock
		@fvm flutter clean
		@printf "✅ Project cleaned successfully!\n"

get: ## Get the dependencies.
		@printf "📦 Getting flutter pub...\n"
		@fvm flutter pub get || (printf "❌ Error in getting dependencies. Please check the dependencies and try again.\n"; exit 1)
		@printf "✅ Dependencies fetched successfully!\n"

build: ## Build the Android apk.
		@printf "📦 Building the Android apk...\n"
		@fvm flutter build apk --split-per-abi|| (printf "❌ Error in building the Android apk. Please check the dependencies and try again.\n"; exit 1)
		@printf "✅ Android apk built successfully!\n"

clean_get: ## Clean the environment and get the dependencies.
		@make clean
		@make get
		@printf "✅ Project cleaned and dependencies fetched successfully!\n"

upgrade: ## Update the dependencies.
		@printf "⬆️ Upgrading flutter pub...\n"
		@fvm flutter pub upgrade || (printf "❌ Error in upgrading dependencies. Please check the dependencies and try again.\n"; exit 1)
		@printf "✅ Dependencies upgraded successfully!\n"

##
## --- Run ---

test: ## Run unit tests.
		@printf "🧪 Starting unit tests.\n"
		@fvm flutter test || (printf "❌ Error in testing.\n"; exit 1)
		@printf "✅ All unit tests passed!\n"

code: ## Run the build_runner to generate the code.
		@printf "🔧 Running build_runner to generate code...\n"
		@fvm dart run build_runner build --delete-conflicting-outputs
		@printf "✅ Code generation completed!\n"

code_watch: ## Run the build_runner in watch mode to generate the code.
		@printf "🔧 Running build_runner in watch mode to generate code...\n"
		@fvm dart run build_runner watch --delete-conflicting-outputs
		@printf "✅ Code is being generated in watch mode!\n"