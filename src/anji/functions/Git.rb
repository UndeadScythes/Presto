# We need a JSON builder here.
external_require "json"

require "Os"

# =============================================================================
# Git - Description.
# =============================================================================
class Git < Anji

    # Create a logger for this class.
    @@LOGGER = LogManager.get_logger("Git")

    # -------------------------------------------------------------------------
    # Run this ANJI.
    # -------------------------------------------------------------------------
    def run(options)

        # Get the directory path of the Git repository.
        repo_path = options["repo_path"]

        if repo_path == nil
            repo_path = ConfigManager.get_presto_root()
        end

        @@LOGGER.info("Changing to repository root")
        
        cd = Dir.pwd()
        Dir.chdir(repo_path)

        @@LOGGER.debug("Running superclass Anji.run with options #{options}")
        response = super(options)

        Dir.chdir(cd)

        return response

    end
    
    # --------------------------------------------------------------------------
    # Produce a list of items that need to be added to the current branch.
    # --------------------------------------------------------------------------
    def get_staging_list(options)
        
        # Get the current branch status.
        branch_status = `git status --porcelain -u`
        
        # Parse the staging list.
        not_staged = []
        branch_status.split(/\r?\n/).each do |status_line|
            status    = status_line[/^(.{2})\s+.*$/, 1]
            file_name = status_line[/^.{2}\s+(.*)$/, 1]
            not_staged << [status, file_name]
        end

        return JSON.generate(not_staged)
        
    end
    
    def get_current_branch()
        branches = `git branch`
        branches = branches.split(/\r?\n/)
        current_branch = ""
        branches.each do |branch|
            if branch[/^\*/]
                current_branch = branch.sub(/^\* /, "")
                break
            end
        end
        return current_branch
    end
    
    # --------------------------------------------------------------------------
    # Add a file.
    # --------------------------------------------------------------------------
    def add_file(options)
        file_name = options["file_name"]
        @@LOGGER.info("Adding file #{file_name} to repositiory")
        @@LOGGER.debug("Current directory is #{Dir.pwd()}")
        return `git add #{file_name} 2>&1`
    end
    
    # --------------------------------------------------------------------------
    # Remove a file.
    # --------------------------------------------------------------------------
    def remove_file(options)
        file_name = options["file_name"]
        @@LOGGER.info("Removing file #{file_name} from repositiory")
        @@LOGGER.debug("Current directory is #{Dir.pwd()}")
        return `git reset -- #{file_name} 2>&1`
    end
    
    # --------------------------------------------------------------------------
    # Revert a file.
    # --------------------------------------------------------------------------
    def revert_file(options)
        file_name = options["file_name"]
        @@LOGGER.info("Reverting file #{file_name} from repositiory")
        @@LOGGER.debug("Current directory is #{Dir.pwd()}")
        return `git checkout -- #{file_name} 2>&1`
    end
    
    def commit_changes(options)
        commit_message = options["commit_message"]
        if commit_message == "" || commit_message == nil
            return "No commit message given"
        end
        @@LOGGER.debug("Committing with message xxx #{commit_message.inspect}")
        @@LOGGER.info("Committing with message #{commit_message}")
        @@LOGGER.debug("Current directory is #{Dir.pwd()}")
        return Os.run("git commit -m \"#{commit_message}\"")
    end
    
    def merge_to_master(options)
        @@LOGGER.info("Mergine to master")
        @@LOGGER.debug("Current directory is #{Dir.pwd()}")
        current_branch = get_current_branch()
        if current_branch == ""
            return "Cannot find current branch"
        end
        response = `git checkout master 2>&1`
        response += `git merge #{current_branch} 2>&1`
        response += `git checkout #{current_branch} 2>&1`
        return response
    end
    
    # -------------------------------------------------------------------------
    # Get the current Git status.
    # -------------------------------------------------------------------------
    def status(options)
        return `git status`
    end
    
    def view_branches()
        branches = `git branch`
        branches = branches.split(/\r?\n/)
        return JSON.generate(branches)
    end
    
    def change_branch(options)
        branch_name = options["branch_name"]
        return `git checkout #{branch_name} 2>&1`
    end
    
    def remove_cache(options)
        file_name = options["file_name"]
        @@LOGGER.info("Removing file #{file_name} from repositiory cache")
        @@LOGGER.debug("Current directory is #{Dir.pwd()}")
        return `git rm --cached #{file_name} 2>&1`
    end
    
    def push_upstream(options)
        current_branch = get_current_branch()
        if current_branch == ""
            return "Cannot find current branch"
        end
        return `git push --set-upstream #{ConfigManager.get("external_git_repository")} #{current_branch} 2>&1`
    end
    
    def view_config()
        return `git config --list`
    end
    
    def repo_init()
        return `git init`
    end
    
    def create_branch(options)
        branch_name = options["branch_name"]
        if branch_name == nil || branch_name == ""
            return "No branch name given."
        end
        return `git branch #{branch_name}`
    end

    def merge_branch(options)
        branch_name = options["branch_name"]
        if branch_name == nil || branch_name == ""
            return "No branch name given."
        end
        return `git merge #{branch_name}`
    end
    
    def get_diff(options)
        
        branch_name = options["branch_name"]
        if branch_name == nil || branch_name == ""
            return "No branch name given."
        end
        return Os.run("git diff --name-status #{get_current_branch()}..#{branch_name}")
    end
        
    # -------------------------------------------------------------------------
    # Return the function this ANJI provides.
    # -------------------------------------------------------------------------
    def self.get_names()
        return [
            "get_diff",
            "merge_branch",
            "create_branch",
            "repo_init",
            "view_config",
            "push_upstream",
            "status",
            "get_staging_list",
            "add_file",
            "get_commit_list",
            "remove_file",
            "revert_file",
            "commit_changes",
            "merge_to_master",
            "view_branches",
            "change_branch",
            "remove_cache"
        ]
    end

end