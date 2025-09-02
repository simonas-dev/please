require 'yaml'
require 'fileutils'
require 'open3'

class OllamaWrapper
  CONFIG_DIR = File.expand_path("~/.ollama_wrapper")
  PROMPTS_FILE = File.join(CONFIG_DIR, "prompts.yml")
  DEFAULT_PROMPTS_FILE = File.join(File.dirname(__FILE__), "..", "default_prompts.yml")
  
  def initialize
    ensure_config_dir
    @prompts = load_prompts
  end
  
  def run(alias_name, *args)
    prompt_config = @prompts[alias_name]
    unless prompt_config
      puts "Error: No prompt found for alias '#{alias_name}'"
      puts "Available aliases: #{@prompts.keys.join(', ')}"
      return false
    end
    
    model = prompt_config['model']
    prompt = prompt_config['prompt']
    
    # Replace any command substitutions in the prompt
    expanded_prompt = expand_command_substitutions(prompt)
    
    # Add any additional arguments to the prompt
    if args.any?
      expanded_prompt += "\n\n" + args.join(" ")
    end
    
    call_ollama(model, expanded_prompt)
  end
  
  def list_aliases
    puts "Available prompt aliases:"
    @prompts.each do |name, config|
      puts "  #{name}: #{config['model']} - #{config['description'] || 'No description'}"
    end
  end
  
  def add_alias(name, model, prompt, description = nil)
    @prompts[name] = {
      'model' => model,
      'prompt' => prompt,
      'description' => description
    }
    save_prompts
    puts "Added alias '#{name}' for model '#{model}'"
  end
  
  def remove_alias(name)
    if @prompts.delete(name)
      save_prompts
      puts "Removed alias '#{name}'"
    else
      puts "Alias '#{name}' not found"
    end
  end
  
  private
  
  def load_prompts
    # Start with default prompts
    prompts = load_default_prompts
    
    # Merge with user prompts if they exist
    if File.exist?(PROMPTS_FILE)
      user_prompts = YAML.load_file(PROMPTS_FILE) || {}
      prompts.merge!(user_prompts)
    end
    
    prompts
  end
  
  def load_default_prompts
    if File.exist?(DEFAULT_PROMPTS_FILE)
      YAML.load_file(DEFAULT_PROMPTS_FILE) || {}
    else
      puts "Warning: default_prompts.yml not found"
      {}
    end
  end
  
  def ensure_config_dir
    FileUtils.mkdir_p(CONFIG_DIR) unless File.directory?(CONFIG_DIR)
    # Don't create an empty prompts.yml file anymore - defaults come from default_prompts.yml
  end
  
  def save_prompts
    # Only save user-added prompts, not defaults
    default_prompts = load_default_prompts
    user_prompts = @prompts.reject { |key, _| default_prompts.key?(key) }
    File.write(PROMPTS_FILE, user_prompts.to_yaml)
  end
  
  def expand_command_substitutions(prompt)
    # Handle $(command) substitutions
    prompt.gsub(/\$\(([^)]+)\)/) do |match|
      command = $1
      result = `#{command}`.strip
      result
    end
  end
  
  def call_ollama(model, prompt)
    puts "\e[2mCalling ollama with model: #{model}\e[0m"
    puts
    
    start_time = Time.now
    spinner_active = true
    first_output = true
    
    # Start spinner in background thread
    spinner_thread = Thread.new do
      spinner_chars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
      spinner_index = 0
      
      while spinner_active
        elapsed = Time.now - start_time
        print "\r\e[2m#{spinner_chars[spinner_index]} Thinking... (#{format('%.1f', elapsed)}s)\e[0m"
        $stdout.flush
        sleep 0.1
        spinner_index = (spinner_index + 1) % spinner_chars.length
      end
    end
    
    # Use Open3 to call ollama and stream the output
    Open3.popen2e("ollama", "run", model, prompt) do |stdin, stdout_err, wait_thread|
      stdin.close
      
      stdout_err.each_line do |line|
        if first_output
          # Stop spinner on first output
          spinner_active = false
          spinner_thread.join
          
          thinking_time = Time.now - start_time
          print "\r" + " " * 50 + "\r"  # Clear spinner line
          puts "\e[2m Thought for #{format('%.1f', thinking_time)}s\e[0m"
          puts "\e[2m─" * 60 + "\e[0m"
          puts
          first_output = false
        end
        
        print line
      end
      
      exit_status = wait_thread.value
      unless exit_status.success?
        spinner_active = false
        spinner_thread.join if spinner_thread.alive?
        puts "\n\e[2mError: ollama command failed with exit code #{exit_status.exitstatus}\e[0m"
        return false
      end
    end
    
    # Ensure spinner is stopped
    spinner_active = false
    spinner_thread.join if spinner_thread.alive?
    
    total_time = Time.now - start_time
    puts
    puts "\e[2m─" * 60 + "\e[0m"
    puts "\e[2m  Total time: #{format('%.1f', total_time)}s\e[0m"
    puts 
    true
  rescue Errno::ENOENT
    spinner_active = false
    spinner_thread.join if spinner_thread.alive?
    puts "\e[2mError: ollama command not found. Please make sure ollama is installed and in your PATH.\e[0m"
    puts 
    false
  end
end