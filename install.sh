#!/bin/bash

# SuperClaude Installer Script
# Installs SuperClaude configuration framework to enhance Claude Code
# Version: 2.0.0
# License: MIT
# Repository: https://github.com/NomenAK/SuperClaude

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# Script version
readonly SCRIPT_VERSION="2.0.0"

# Constants
readonly REQUIRED_SPACE_KB=51200  # 50MB in KB
readonly MIN_BASH_VERSION=3
readonly CHECKSUM_FILE=".checksums"
readonly CONFIG_FILE=".superclaude.conf"

# Colors for output - detect terminal support
if [[ -t 1 ]] && [[ "$(tput colors 2>/dev/null)" -ge 8 ]]; then
    # Terminal supports colors
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly RED='\033[0;31m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m' # No Color
else
    # No color support
    readonly GREEN=''
    readonly YELLOW=''
    readonly RED=''
    readonly BLUE=''
    readonly NC=''
fi

# Configuration patterns
readonly -a CUSTOMIZABLE_CONFIGS=("CLAUDE.md" "RULES.md" "PERSONAS.md" "MCP.md")

# Default settings
INSTALL_DIR="$HOME/.amazonq"
FORCE_INSTALL=false
UPDATE_MODE=false
UNINSTALL_MODE=false
VERIFY_MODE=false
VERBOSE=false
DRY_RUN=false
LOG_FILE=""
VERIFICATION_FAILURES=0
ROLLBACK_ON_FAILURE=true
BACKUP_DIR=""
INSTALLATION_PHASE=false

# Original working directory
ORIGINAL_DIR=$(pwd)

# Function: generate_error_report
# Description: Generate a comprehensive error and warning report
# Parameters: None
# Returns: None
generate_error_report() {
    if [[ $ERROR_COUNT -eq 0 ]] && [[ $WARNING_COUNT -eq 0 ]]; then
        return 0
    fi
    
    echo ""
    echo -e "${BLUE}=== Installation Report ===${NC}"
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Script Version: $SCRIPT_VERSION"
    echo "Installation Directory: $INSTALL_DIR"
    echo ""
    
    if [[ $ERROR_COUNT -gt 0 ]]; then
        echo -e "${RED}Errors ($ERROR_COUNT):${NC}"
        for error in "${ERROR_DETAILS[@]}"; do
            echo "  • $error"
        done
        echo ""
    fi
    
    if [[ $WARNING_COUNT -gt 0 ]]; then
        echo -e "${YELLOW}Warnings ($WARNING_COUNT):${NC}"
        for warning in "${WARNING_DETAILS[@]}"; do
            echo "  • $warning"
        done
        echo ""
    fi
    
    # Recommendations based on errors/warnings
    if [[ $ERROR_COUNT -gt 0 ]]; then
        echo -e "${BLUE}Recommendations:${NC}"
        echo "  • Check file permissions and ownership"
        echo "  • Verify disk space availability"
        echo "  • Ensure all required commands are installed"
        echo "  • Review log file for detailed information: ${LOG_FILE:-not specified}"
        echo ""
    fi
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    
    # Return to original directory
    cd "$ORIGINAL_DIR" 2>/dev/null || true
    
    # Generate error report if there were issues
    if [[ $exit_code -ne 0 ]] || [[ $ERROR_COUNT -gt 0 ]] || [[ $WARNING_COUNT -gt 0 ]]; then
        generate_error_report
    fi
    
    # Rollback on failure if enabled and we're in installation phase
    if [[ $exit_code -ne 0 ]] && [[ "${ROLLBACK_ON_FAILURE:-true}" = true ]] && [[ -n "$BACKUP_DIR" ]] && [[ "${INSTALLATION_PHASE:-false}" = true ]]; then
        echo -e "${YELLOW}Installation failed, attempting rollback...${NC}" >&2
        if rollback_installation; then
            echo -e "${GREEN}Rollback completed successfully${NC}" >&2
        else
            echo -e "${RED}Rollback failed - manual intervention required${NC}" >&2
            echo -e "${YELLOW}Backup available at: $BACKUP_DIR${NC}" >&2
        fi
    fi
    
    exit $exit_code
}
trap cleanup EXIT INT TERM HUP QUIT

# Exception patterns - files/patterns to never delete during cleanup
EXCEPTION_PATTERNS=(
    "*.custom"
    "*.local"
    "*.new"
    "backup.*"
    ".git*"
    "CLAUDE.md"  # User might customize main config
    "RULES.md"   # User might customize rules
    "PERSONAS.md" # User might customize personas
    "MCP.md"     # User might customize MCP config
)

# User data files that should NEVER be deleted or overwritten
PRESERVE_FILES=(
    ".credentials.json"
    "settings.json"
    "settings.local.json"
    ".claude/todos"
    ".claude/statsig"
    ".claude/projects"
)

# Function: check_command
# Description: Check if a command exists
# Parameters: $1 - command name
# Returns: 0 if command exists, 1 otherwise
check_command() {
    local cmd="$1"
    
    # Validate input
    if [[ -z "$cmd" ]]; then
        log_error "check_command: Command name cannot be empty"
        return 1
    fi
    
    # Check for dangerous command patterns (enhanced security)
    if [[ "$cmd" =~ [\;\&\|\`\$\(\)\{\}\"\'\\] ]] || [[ "$cmd" =~ \.\.|^/ ]] || [[ "$cmd" =~ [[:space:]] ]]; then
        log_error "check_command: Invalid command name contains dangerous characters: $cmd"
        return 1
    fi
    
    command -v "$cmd" &> /dev/null
}

# Function: compare_versions
# Description: Compare two semantic versions
# Parameters: $1 - version1, $2 - version2
# Returns: 0 if version1 < version2, 1 if version1 >= version2
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    # Validate input parameters
    if [[ -z "$version1" ]] || [[ -z "$version2" ]]; then
        log_error "compare_versions: Both version parameters are required"
        return 1
    fi
    
    # Validate version format (basic semantic version pattern)
    if [[ ! "$version1" =~ ^[0-9]+(\.[0-9]+)*([.-][a-zA-Z0-9]+)*$ ]]; then
        log_error "compare_versions: Invalid version format: $version1"
        return 1
    fi
    
    if [[ ! "$version2" =~ ^[0-9]+(\.[0-9]+)*([.-][a-zA-Z0-9]+)*$ ]]; then
        log_error "compare_versions: Invalid version format: $version2"
        return 1
    fi
    
    # Handle identical versions
    if [[ "$version1" == "$version2" ]]; then
        return 1
    fi
    
    # Split versions into arrays
    local v1_parts=() v2_parts=()
    IFS='.' read -ra v1_parts <<< "$version1"
    IFS='.' read -ra v2_parts <<< "$version2"
    
    # Compare each part
    for i in {0..2}; do
        local v1_part="${v1_parts[$i]:-0}"
        local v2_part="${v2_parts[$i]:-0}"
        
        # Remove any non-numeric suffixes for comparison
        v1_part="${v1_part%%[!0-9]*}"
        v2_part="${v2_part%%[!0-9]*}"
        
        # Validate that we have numeric values
        if [[ ! "$v1_part" =~ ^[0-9]+$ ]]; then v1_part=0; fi
        if [[ ! "$v2_part" =~ ^[0-9]+$ ]]; then v2_part=0; fi
        
        if ((v1_part < v2_part)); then
            return 0
        elif ((v1_part > v2_part)); then
            return 1
        fi
    done
    
    return 1
}

# Function: rollback_installation
# Description: Rollback a failed installation using backup
# Parameters: None (uses global BACKUP_DIR)
# Returns: 0 on success, 1 on failure
rollback_installation() {
    if [[ -z "$BACKUP_DIR" ]] || [[ ! -d "$BACKUP_DIR" ]]; then
        log_error "No backup available for rollback"
        return 1
    fi
    
    echo -e "${YELLOW}Rolling back installation...${NC}" >&2
    log_verbose "Backup directory: $BACKUP_DIR"
    log_verbose "Install directory: $INSTALL_DIR"
    
    # Validate backup directory contents before proceeding
    if [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        log_error "Backup directory is empty, cannot rollback"
        return 1
    fi
    
    # Create a temporary directory for safe operations
    local temp_dir
    temp_dir=$(mktemp -d 2>/dev/null) || {
        log_error "Failed to create temporary directory for rollback"
        return 1
    }
    
    # Remove failed installation safely
    if [[ -d "$INSTALL_DIR" ]]; then
        log_verbose "Moving failed installation to temporary location"
        if ! mv "$INSTALL_DIR" "$temp_dir/failed_install" 2>/dev/null; then
            log_error "Failed to move failed installation"
            rm -rf "$temp_dir" 2>/dev/null
            return 1
        fi
    fi
    
    # Restore backup
    log_verbose "Restoring backup to installation directory"
    if ! mv "$BACKUP_DIR" "$INSTALL_DIR" 2>/dev/null; then
        log_error "Failed to restore backup"
        # Try to restore the failed installation
        if [[ -d "$temp_dir/failed_install" ]]; then
            mv "$temp_dir/failed_install" "$INSTALL_DIR" 2>/dev/null || true
        fi
        rm -rf "$temp_dir" 2>/dev/null
        return 1
    fi
    
    # Clean up temporary directory
    rm -rf "$temp_dir" 2>/dev/null
    
    # Clear the backup directory variable to prevent accidental use
    BACKUP_DIR=""
    
    echo -e "${GREEN}Installation rolled back successfully${NC}" >&2
    return 0
}

# Function: validate_directory_path
# Description: Validate directory path for security and sanity
# Parameters: $1 - directory path
# Returns: 0 if valid, 1 if invalid
validate_directory_path() {
    local dir_path="$1"
    
    # Check if path is empty
    if [[ -z "$dir_path" ]]; then
        log_error "Directory path cannot be empty"
        return 1
    fi
    
    # Check for dangerous paths
    local dangerous_paths=("/" "/bin" "/sbin" "/usr" "/usr/bin" "/usr/sbin" "/etc" "/sys" "/proc" "/dev" "/boot" "/lib" "/lib64")
    for dangerous in "${dangerous_paths[@]}"; do
        if [[ "$dir_path" == "$dangerous" ]] || [[ "$dir_path" == "$dangerous"/* ]]; then
            log_error "Installation to system directory not allowed: $dir_path"
            return 1
        fi
    done
    
    # Check for path traversal attempts
    if [[ "$dir_path" =~ \.\./|/\.\. ]]; then
        log_error "Path traversal not allowed in directory path: $dir_path"
        return 1
    fi
    
    # Basic character validation - only reject obviously dangerous patterns
    # (Null byte check removed as it was causing false positives)
    
    return 0
}

# Function: load_config
# Description: Load configuration from file if exists
# Parameters: $1 - config file path
# Returns: 0 on success
load_config() {
    local config_file="$1"
    
    # Validate input parameter
    if [[ -z "$config_file" ]]; then
        log_error "load_config: Configuration file path cannot be empty"
        return 1
    fi
    
    # Security checks
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    if [[ ! -r "$config_file" ]]; then
        log_error "Cannot read configuration file: $config_file"
        return 1
    fi
    
    # Check file size (prevent loading extremely large files)
    local file_size
    if command -v stat >/dev/null 2>&1; then
        file_size=$(stat -c%s "$config_file" 2>/dev/null || stat -f%z "$config_file" 2>/dev/null || echo "0")
        if [[ "$file_size" -gt 10240 ]]; then  # 10KB limit
            log_error "Configuration file too large (>10KB): $config_file"
            return 1
        fi
    fi
    
    # Check file ownership (warn if not owned by current user)
    local file_owner=""
    if command -v stat >/dev/null 2>&1; then
        # Try GNU stat first, then BSD stat
        file_owner=$(stat -c "%U" "$config_file" 2>/dev/null || stat -f "%Su" "$config_file" 2>/dev/null || echo "")
        if [[ -n "$file_owner" ]] && [[ "$file_owner" != "$(whoami)" ]]; then
            log_warning "Configuration file is owned by $file_owner, not current user"
        fi
    else
        log_verbose "stat utility not available, skipping ownership check"
    fi
    
    # Check for suspicious patterns (enhanced security)
    if grep -qE '(\$\(|\$\{|`|;[[:space:]]*rm|;[[:space:]]*exec|;[[:space:]]*eval|\|\||&&|>[^>]|<[^<]|nc[[:space:]]|wget[[:space:]]|curl[[:space:]].*\||bash[[:space:]]*<|sh[[:space:]]*<)' "$config_file"; then
        log_error "Configuration file contains potentially dangerous commands"
        return 1
    fi
    
    # Source config file in a subshell to validate
    if (source "$config_file" 2>/dev/null); then
        # Only source if validation passed
        source "$config_file"
        log_verbose "Loaded configuration from $config_file"
    else
        log_error "Invalid configuration file: $config_file"
        return 1
    fi
    
    return 0
}

# Function: show_usage
# Description: Display usage information
# Parameters: None
# Returns: None
show_usage() {
    echo "SuperClaude Installer v$SCRIPT_VERSION"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dir <directory>    Install to custom directory (default: $HOME/.claude)"
    echo "  --force              Skip confirmation prompts (for automation)"
    echo "  --update             Update existing installation (preserves customizations)"
    echo "  --uninstall          Remove SuperClaude from specified directory"
    echo "  --verify-checksums   Verify integrity of an existing installation"
    echo "  --verbose            Show detailed output during installation"
    echo "  --dry-run            Preview changes without making them"
    echo "  --log <file>         Save installation log to file"
    echo "  --config <file>      Load configuration from file"
    echo "  --no-rollback        Disable automatic rollback on failure"
    echo "  --check-update       Check for SuperClaude updates"
    echo "  --version            Show installer version"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Install to default location"
    echo "  $0 --dir /opt/claude        # Install to /opt/claude"
    echo "  $0 --dir ./local-claude     # Install to ./local-claude"
    echo "  $0 --force                  # Install without prompts"
    echo "  $0 --update                 # Update existing installation"
    echo "  $0 --uninstall              # Remove SuperClaude"
    echo "  $0 --verify-checksums       # Verify existing installation"
    echo "  $0 --dry-run --verbose      # Preview with detailed output"
}

# Function: log
# Description: Log a message to stdout and optionally to file
# Parameters: $1 - message
# Returns: None
log() {
    local message="$1"
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
    fi
    echo "$message"
}

# Function: log_verbose
# Description: Log a verbose message (only shown with --verbose)
# Parameters: $1 - message
# Returns: None
log_verbose() {
    local message="$1"
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [VERBOSE] $message" >> "$LOG_FILE"
    fi
    if [[ "$VERBOSE" = true ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $message" >&2
    fi
}

# Global error tracking
ERROR_COUNT=0
WARNING_COUNT=0
declare -a ERROR_DETAILS=()
declare -a WARNING_DETAILS=()

# Function: log_error
# Description: Log an error message to stderr and track for reporting
# Parameters: $1 - message, $2 - optional context
# Returns: None
log_error() {
    local message="$1"
    local context="${2:-unknown}"
    
    ((ERROR_COUNT++))
    ERROR_DETAILS+=("[$context] $message")
    
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] [$context] $message" >> "$LOG_FILE"
    fi
    echo -e "${RED}[ERROR]${NC} $message" >&2
}

# Function: log_warning
# Description: Log a warning message to stderr and track for reporting
# Parameters: $1 - message, $2 - optional context
# Returns: None
log_warning() {
    local message="$1"
    local context="${2:-unknown}"
    
    ((WARNING_COUNT++))
    WARNING_DETAILS+=("[$context] $message")
    
    if [[ -n "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] [$context] $message" >> "$LOG_FILE"
    fi
    echo -e "${YELLOW}[WARNING]${NC} $message" >&2
}

# Function: is_exception
# Description: Check if a file matches any exception pattern
# Parameters: $1 - file path
# Returns: 0 if matches exception pattern, 1 otherwise
is_exception() {
    local file="$1"
    local basename_file=$(basename "$file")
    
    for pattern in "${EXCEPTION_PATTERNS[@]}"; do
        if [[ "$basename_file" == $pattern ]]; then
            return 0
        fi
    done
    return 1
}

# Function: is_preserve_file
# Description: Check if a file should be preserved (user data)
# Parameters: $1 - file path
# Returns: 0 if file should be preserved, 1 otherwise
is_preserve_file() {
    local file="$1"
    
    for preserve in "${PRESERVE_FILES[@]}"; do
        # Check if the file path ends with the preserve pattern
        if [[ "$file" == *"$preserve" ]]; then
            return 0
        fi
    done
    return 1
}

# Function: verify_file_integrity
# Description: Verify file integrity using SHA256 checksums
# Parameters: $1 - source file, $2 - destination file
# Returns: 0 if checksums match, 1 otherwise
verify_file_integrity() {
    local src_file="$1"
    local dest_file="$2"
    
    # Validate input parameters
    if [[ -z "$src_file" ]] || [[ -z "$dest_file" ]]; then
        log_error "verify_file_integrity: Both source and destination files required"
        return 1
    fi
    
    # Check if files exist and are readable
    if [[ ! -f "$src_file" ]]; then
        log_error "verify_file_integrity: Source file does not exist: $src_file"
        return 1
    fi
    
    if [[ ! -r "$src_file" ]]; then
        log_error "verify_file_integrity: Cannot read source file: $src_file"
        return 1
    fi
    
    if [[ ! -f "$dest_file" ]]; then
        log_error "verify_file_integrity: Destination file does not exist: $dest_file"
        return 1
    fi
    
    if [[ ! -r "$dest_file" ]]; then
        log_error "verify_file_integrity: Cannot read destination file: $dest_file"
        return 1
    fi
    
    # If sha256sum is not available, skip verification
    if ! check_command sha256sum; then
        log_verbose "sha256sum not available, skipping integrity check"
        return 0
    fi
    
    # Calculate checksums with error handling
    local src_checksum dest_checksum
    
    if ! src_checksum=$(sha256sum "$src_file" 2>/dev/null | awk '{print $1}'); then
        log_error "verify_file_integrity: Failed to calculate checksum for source: $src_file"
        return 1
    fi
    
    if ! dest_checksum=$(sha256sum "$dest_file" 2>/dev/null | awk '{print $1}'); then
        log_error "verify_file_integrity: Failed to calculate checksum for destination: $dest_file"
        return 1
    fi
    
    # Verify checksums match
    if [[ -z "$src_checksum" ]] || [[ -z "$dest_checksum" ]]; then
        log_error "verify_file_integrity: Empty checksums calculated"
        return 1
    fi
    
    # Validate checksum format (64 hex characters)
    if [[ ! "$src_checksum" =~ ^[a-f0-9]{64}$ ]] || [[ ! "$dest_checksum" =~ ^[a-f0-9]{64}$ ]]; then
        log_error "verify_file_integrity: Invalid checksum format"
        return 1
    fi
    
    if [[ "$src_checksum" != "$dest_checksum" ]]; then
        log_error "verify_file_integrity: Checksum mismatch"
        log_error "  Source: $src_file ($src_checksum)"
        log_error "  Dest:   $dest_file ($dest_checksum)"
        return 1
    fi
    
    log_verbose "File integrity verified: $dest_file"
    return 0
}

# Function: get_source_files
# Description: Get all source files relative to source root
# Parameters: $1 - source root directory
# Returns: List of files (one per line)
get_source_files() {
    (  # Run in subshell to isolate directory changes
        local source_root="$1"
        
        # Validate input parameter
        if [[ -z "$source_root" ]]; then
            log_error "get_source_files: Source root directory required"
            return 1
        fi
        
        # Validate that source root exists and is a directory
        if [[ ! -d "$source_root" ]]; then
            log_error "get_source_files: Source root is not a directory: $source_root"
            return 1
        fi
        
        # Change to source directory with error handling
        if ! cd "$source_root"; then
            log_error "get_source_files: Cannot access source directory: $source_root"
            return 1
        fi
        
        # Validate that .claude directory exists
        if [[ ! -d ".claude" ]]; then
            log_error "get_source_files: .claude directory not found in source root"
            return 1
        fi
        
        # Find all files in .claude directory and map them to root with error handling
        file_list=""
        if ! file_list=$(find .claude -type f \
            -not -path "*/.git*" \
            -not -path "*/backup.*" \
            -not -path "*/log/*" \
            -not -path "*/logs/*" \
            -not -path "*/.log/*" \
            -not -path "*/.logs/*" \
            -not -name "*.log" \
            -not -name "*.logs" \
            -not -name "settings.local.json" \
            -not -name "CLAUDE.md" \
            2>/dev/null | sed 's|^\.claude/||' | sort); then
            log_error "get_source_files: Failed to enumerate files in .claude directory"
            return 1
        fi
        
        # Output the file list
        echo "$file_list"
        
        # Also include CLAUDE.md from root if it exists
        if [[ -f "CLAUDE.md" ]]; then
            echo "CLAUDE.md"
        fi
        
        return 0
    )
}

# Function: get_installed_files
# Description: Get all installed files relative to install directory
# Parameters: $1 - install directory
# Returns: List of files (one per line)
get_installed_files() {
    local install_dir="$1"
    local current_dir=$(pwd)
    cd "$install_dir" || return 1
    
    # Find all files, excluding backups (match actual backup pattern)
    find . -type f \
        -not -path "./superclaude-backup.*" \
        | sed 's|^\./||' | sort
    
    cd "$current_dir" || return 1
}

# Function: check_for_updates
# Description: Check for SuperClaude updates from GitHub
# Parameters: None
# Returns: 0 if update available, 1 if up to date, 2 on error
check_for_updates() {
    local repo_url="https://api.github.com/repos/nshkrdotcom/SuperClaude/releases/latest"
    
    if ! check_command curl; then
        log_error "curl is required for update checking"
        return 2
    fi
    
    log "Checking for SuperClaude updates..."
    
    # Get latest release info with timeout
    local release_info
    if ! release_info=$(timeout 30 curl -s --max-time 30 --connect-timeout 10 "$repo_url" 2>/dev/null); then
        log_error "Failed to check for updates (network timeout or error)"
        return 2
    fi
    
    if [[ -z "$release_info" ]] || [[ "$release_info" == *"Not Found"* ]] || [[ "$release_info" == *"API rate limit"* ]]; then
        log_error "Failed to check for updates (empty response or API limit)"
        return 2
    fi
    
    # Extract version from release
    local latest_version=$(echo "$release_info" | grep -o '"tag_name":\s*"v\?[^"]*"' | sed 's/.*"v\?\([^"]*\)".*/\1/')
    if [[ -z "$latest_version" ]]; then
        log_error "Could not determine latest version"
        return 2
    fi
    
    log "Current version: $SCRIPT_VERSION"
    log "Latest version: $latest_version"
    
    # Compare versions using semantic version comparison
    if compare_versions "$SCRIPT_VERSION" "$latest_version"; then
        echo -e "${YELLOW}Update available!${NC}"
        echo "Download: https://github.com/nshkrdotcom/SuperClaude/releases/latest"
        return 0
    else
        echo -e "${GREEN}You have the latest version${NC}"
        return 1
    fi
}

# Function: find_obsolete_files
# Description: Find files in destination but not in source
# Parameters: $1 - source root, $2 - install directory
# Returns: List of obsolete files
find_obsolete_files() {
    local source_root="$1"
    local install_dir="$2"
    
    # Get file lists
    local source_files=$(get_source_files "$source_root" | sort | uniq)
    local installed_files=$(get_installed_files "$install_dir" | sort | uniq)
    
    # Find files that exist in installed but not in source
    comm -13 <(echo "$source_files") <(echo "$installed_files")
}

# Function: cleanup_obsolete_files
# Description: Remove obsolete files from installation
# Parameters: $1 - install directory, $2 - list of obsolete files
# Returns: 0 on success
cleanup_obsolete_files() {
    local install_dir="$1"
    local obsolete_files="$2"
    local cleaned_count=0
    
    if [[ -z "$obsolete_files" ]]; then
        echo "No obsolete files to clean up."
        return 0
    fi
    
    echo -e "${YELLOW}Found obsolete files to clean up:${NC}"
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            local full_path="$install_dir/$file"
            
            # Check if file should be preserved
            if is_exception "$file" || is_preserve_file "$file"; then
                echo "  Preserving: $file (protected file)"
            else
                if [[ "$DRY_RUN" = true ]]; then
                    echo "  Would remove: $file"
                else
                    echo "  Removing: $file"
                    rm -f "$full_path"
                fi
                ((cleaned_count++))
                
                # Remove empty parent directories
                if [[ "$DRY_RUN" != true ]]; then
                    local parent_dir=$(dirname "$full_path")
                    while [[ "$parent_dir" != "$install_dir" ]] && [[ -d "$parent_dir" ]] && [[ -z "$(ls -A "$parent_dir" 2>/dev/null)" ]]; do
                        rmdir "$parent_dir" 2>/dev/null
                        parent_dir=$(dirname "$parent_dir")
                    done
                fi
            fi
        fi
    done <<< "$obsolete_files"
    
    if [[ $cleaned_count -gt 0 ]]; then
        echo -e "${GREEN}Cleaned up $cleaned_count obsolete file(s)${NC}"
    fi
}

# Function: detect_platform
# Description: Detect the operating system platform
# Parameters: None
# Returns: Sets global OS variable
detect_platform() {
    OS="Unknown"
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="Linux"
        if grep -q Microsoft /proc/version 2>/dev/null; then
            OS="WSL"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        OS="Windows"
    fi
    log_verbose "Detected platform: $OS"
}

# Function: run_preflight_checks
# Description: Run pre-installation validation checks
# Parameters: None
# Returns: 0 on success, exits on failure
run_preflight_checks() {
    log_verbose "Running pre-flight checks..."
    
    # Detect platform
    detect_platform
    
    # Check required commands
    local required_commands=("find" "comm" "cmp" "sort" "uniq" "basename" "dirname" "grep" "awk" "sed")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    # Check for timeout command (used for network operations)
    if ! command -v timeout &> /dev/null; then
        log_verbose "timeout command not available, network operations may hang"
    fi
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}" "preflight-check"
        echo "Please install the missing commands and try again."
        exit 1
    fi
    
    # Check bash version
    local bash_major_version="${BASH_VERSION%%.*}"
    if [[ -z "$bash_major_version" ]] || [[ "$bash_major_version" -lt "$MIN_BASH_VERSION" ]]; then
        log_error "Bash version $MIN_BASH_VERSION.0 or higher required (current: ${BASH_VERSION:-unknown})" "preflight-check"
        exit 1
    fi
    
    # Check disk space
    if [[ ! "$DRY_RUN" = true ]]; then
        local install_parent=$(dirname "$INSTALL_DIR")
        if [[ -d "$install_parent" ]]; then
            # Get available space - handle different df output formats
            local available_space=""
            if command -v df &>/dev/null; then
                # Try POSIX-compliant df first
                available_space=$(df -P -k "$install_parent" 2>/dev/null | awk 'NR==2 && NF>=4 {print $4}')
                # If that fails, try without -P flag
                if [[ -z "$available_space" ]] || [[ ! "$available_space" =~ ^[0-9]+$ ]]; then
                    available_space=$(df -k "$install_parent" 2>/dev/null | awk 'NR==2 && NF>=4 {print $4}')
                fi
                # Final fallback - try to parse any numeric value from df output
                if [[ -z "$available_space" ]] || [[ ! "$available_space" =~ ^[0-9]+$ ]]; then
                    available_space=$(df "$install_parent" 2>/dev/null | awk '/[0-9]/ {for(i=1;i<=NF;i++) if($i ~ /^[0-9]+$/ && $i > 1000) print $i; exit}')
                fi
            else
                log_verbose "df utility not available, skipping disk space check"
            fi
            if [[ -n "$available_space" ]] && [[ "$available_space" -lt "$REQUIRED_SPACE_KB" ]]; then
                log_error "Insufficient disk space. Need at least $((REQUIRED_SPACE_KB / 1024))MB free." "disk-space-check"
                exit 1
            fi
        fi
    fi
    
    # Platform-specific checks
    if [[ "$OS" == "macOS" ]]; then
        # macOS specific checks
        if ! command -v sw_vers &> /dev/null; then
            log_verbose "Running on macOS but sw_vers not found"
        else
            log_verbose "macOS version: $(sw_vers -productVersion)"
        fi
    fi
    
    log_verbose "Pre-flight checks passed"
}

# Load configuration from default locations
load_default_config() {
    # System-wide config
    if [[ -f "/etc/superclaude.conf" ]]; then
        load_config "/etc/superclaude.conf"
    fi
    
    # User config
    if [[ -f "$HOME/.superclaude.conf" ]]; then
        load_config "$HOME/.superclaude.conf"
    fi
    
    # Local config
    if [[ -f ".superclaude.conf" ]]; then
        load_config ".superclaude.conf"
    fi
}

# Load default configuration
load_default_config

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dir)
            if [[ -z "$2" ]] || [[ "$2" == --* ]]; then
                log_error "--dir requires a directory argument"
                exit 1
            fi
            
            # Validate the directory path
            if ! validate_directory_path "$2"; then
                log_error "Invalid installation directory: $2"
                exit 1
            fi
            
            INSTALL_DIR="$2"
            shift 2
            ;;
        --force)
            FORCE_INSTALL=true
            shift
            ;;
        --update)
     s${NC}"
echo -e "  Claude shared files: ${GREEN}$claude_shared${NC}"

# Verify critical files exist
critical_files_ok=true
for critical_file in "CLAUDE.md" "commands" "shared"; do
    if [[ ! -e "$INSTALL_DIR/$critical_file" ]]; then
        echo -e "${YELLOW}Warning: Critical file/directory missing: $critical_file${NC}"
        critical_files_ok=false
    fi
done

# Check if installation was successful
if [ "$actual_files" -ge "$expected_files" ] && [ "$critical_files_ok" = true ] && [ $VERIFICATION_FAILURES -eq 0 ]; then
    # Mark installation phase as complete
    INSTALLATION_PHASE=false
    
    echo ""
    if [[ "$UPDATE_MODE" = true ]]; then
        echo -e "${GREEN}✓ SuperClaude updated successfully!${NC}"
        echo ""
        # Check for .new files
        new_files=$(find "$INSTALL_DIR" -name "*.new" 2>/dev/null)
        if [[ -n "$new_files" ]]; then
            echo -e "${YELLOW}Note: The following files have updates available:${NC}"
            echo "$new_files" | while read -r file; do
                echo "  - $file"
            done
            echo ""
            echo "To review changes: diff <file> <file>.new"
            echo "To apply update: mv <file>.new <file>"
            echo ""
        fi
    else
        echo -e "${GREEN}✓ SuperClaude installed successfully!${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Open any project with Claude Code"
        echo "2. Try a command: /analyze --code"
        echo "3. Activate a persona: /analyze --persona-architect"
        echo ""
    fi
    if [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}Note: Your previous configuration was backed up to:${NC}"
        echo "$BACKUP_DIR"
        echo ""
    fi
    echo "For more information, see README.md"
    
    # Preserve BACKUP_DIR for user reference but mark installation as complete
    INSTALLATION_PHASE=false
    log_verbose "Installation completed successfully, rollback disabled"
else
    echo ""
    echo -e "${RED}✗ Installation may be incomplete${NC}"
    echo ""
    echo "Expected vs Actual file counts:"
    echo "  Total files: $actual_files/$expected_files$([ "$actual_files" -lt "$expected_files" ] && echo " ❌" || echo " ✓")"
    if [ $VERIFICATION_FAILURES -gt 0 ]; then
        echo "  Integrity failures: $VERIFICATION_FAILURES ❌"
    fi
    echo ""
    
    # List missing files if any
    if [ "$actual_files" -lt "$expected_files" ]; then
        echo "Missing files:"
        comm -23 <(get_source_files "." | sort) <(get_installed_files "$INSTALL_DIR" | sort) | head -10 | while read -r file; do
            echo "  - $file"
        done
        echo ""
    fi
    
    echo "Troubleshooting steps:"
    echo "1. Check for error messages above"
    echo "2. Ensure you have write permissions to $INSTALL_DIR"
    echo "3. Verify all source files exist in the current directory"
    echo "4. Try running with sudo if permission errors occur"
    echo ""
    echo "For manual installation, see README.md"
    exit 1
fi
