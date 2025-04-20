.PHONY: bootstrap lint snapshot test clean all watch-ci apply-branch-protection

all: bootstrap test

bootstrap:
	@echo "📦 bootstrap" && ./Scripts/ci-setup.sh && ./Scripts/patch-tcc-db.sh

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

apply-branch-protection:
	@echo "🔒 Applying branch protection rules..."
	@bash Scripts/apply-branch-protection.sh 