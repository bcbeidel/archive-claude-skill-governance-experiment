SKILLS_DIR := skills
DIST_DIR := dist

# Find all skill directories containing SKILL.md
SKILL_DIRS := $(shell find $(SKILLS_DIR) -name "SKILL.md" -maxdepth 2 -exec dirname {} \;)
SKILL_NAMES := $(notdir $(SKILL_DIRS))
SKILL_ZIPS := $(addprefix $(DIST_DIR)/,$(addsuffix .zip,$(SKILL_NAMES)))

.PHONY: package clean list-skills help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

package: $(SKILL_ZIPS) ## Package all skills as ZIP files for claude.ai upload
	@echo ""
	@echo "=== Packaged Skills ==="
	@ls -lh $(DIST_DIR)/*.zip
	@echo ""
	@echo "Upload these ZIPs to claude.ai: Organization Settings > Skills > + Add"

$(DIST_DIR)/%.zip: $(SKILLS_DIR)/%/SKILL.md
	@mkdir -p $(DIST_DIR)
	@echo "Packaging $*..."
	@cd $(SKILLS_DIR) && zip -r ../$(DIST_DIR)/$*.zip $*/ -x '*/.gitkeep'

clean: ## Remove packaged artifacts
	rm -rf $(DIST_DIR)

list-skills: ## List all discovered skills
	@echo "Skills found:"
	@for dir in $(SKILL_DIRS); do \
		name=$$(basename $$dir); \
		desc=$$(sed -n '/^---$$/,/^---$$/p' $$dir/SKILL.md | grep '^name:' | sed 's/^name:[[:space:]]*//'); \
		echo "  - $$name ($$desc)"; \
	done
