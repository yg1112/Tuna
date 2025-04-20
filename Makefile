.PHONY: bootstrap lint snapshot test clean all watch-ci branch-hygiene format

all: bootstrap test

bootstrap:
	@echo "📦 bootstrap" && ./Scripts/ci-setup.sh && ./Scripts/patch-tcc-db.sh

format:
	@echo "🎨 format" && swiftformat .

lint:
	@echo "🧹 lint" && swiftformat --config .swiftformat .

snapshot:
	@echo "📸 snapshot" && swift test --filter SnapshotTests

test:
	@echo "🧪 test" && set -o pipefail && swift test --parallel

clean:
	@echo "🧽 clean" && rm -rf .build

watch-ci:
	@Scripts/ci-watch.sh $(PR) 

branch-hygiene:
	@echo "Running branch hygiene checks..."
	@./scripts/branch-hygiene.sh 