require 'yaml'
require 'fileutils'
require 'open3'

class OllamaWrapper
  DEFAULT_PROMPTS_FILE = File.expand_path("default_prompts.yml", File.dirname(__FILE__))
  
  # Common model context limits (approximate tokens)
  MODEL_CONTEXT_LIMITS = {
    'llama2' => 4096,
    'llama2:7b' => 4096,
    'llama2:13b' => 4096,
    'llama2:70b' => 4096,
    'llama3' => 8192,
    'llama3:8b' => 8192,
    'llama3:70b' => 8192,
    'llama3.1' => 128000,
    'llama3.1:8b' => 128000,
    'llama3.1:70b' => 128000,
    'llama3.1:405b' => 128000,
    'llama3.2' => 128000,
    'llama3.2:1b' => 128000,
    'llama3.2:3b' => 128000,
    'codellama' => 16384,
    'codellama:7b' => 16384,
    'codellama:13b' => 16384,
    'codellama:34b' => 16384,
    'mistral' => 8192,
    'mistral:7b' => 8192,
    'mixtral' => 32768,
    'mixtral:8x7b' => 32768,
    'qwen' => 8192,
    'qwen:7b' => 8192,
    'qwen:14b' => 8192,
    'qwen:72b' => 8192,
    'gpt-oss:20b' => 8192,  # Conservative estimate
    'gemma' => 8192,
    'gemma:2b' => 8192,
    'gemma:7b' => 8192,
    'phi3' => 4096,
    'phi3:mini' => 4096,
    'yi' => 4096,
    'default' => 4096  # Fallback
  }.freeze
  
  def initialize
    @prompts = load_default_prompts
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
    
    # Check prompt size before calling ollama
    if prompt_too_large?(model, expanded_prompt)
      return false
    end
    
    call_ollama(model, expanded_prompt)
  end
  
  def list_aliases
    puts "Available prompt aliases:"
    @prompts.each do |name, config|
      puts "  #{name}: #{config['model']} - #{config['description'] || 'No description'}"
    end
  end
  
  
  private
  
  def load_default_prompts
    puts "DEBUG: Looking for prompts file at: #{DEFAULT_PROMPTS_FILE}"
    puts "DEBUG: File exists? #{File.exist?(DEFAULT_PROMPTS_FILE)}"
    puts "DEBUG: __FILE__ is: #{__FILE__}"
    puts "DEBUG: File.dirname(__FILE__) is: #{File.dirname(__FILE__)}"
    
    if File.exist?(DEFAULT_PROMPTS_FILE)
      YAML.load_file(DEFAULT_PROMPTS_FILE) || {}
    else
      puts "Warning: default_prompts.yml not found at #{DEFAULT_PROMPTS_FILE}"
      {}
    end
  end
  
  def expand_command_substitutions(prompt)
    # Handle $(command) substitutions
    prompt.gsub(/\$\(([^)]+)\)/) do |match|
      command = $1
      result = `#{command}`.strip
      result
    end
  end
  
  def prompt_too_large?(model, prompt)
    # Rough token estimation: ~4 characters per token (conservative)
    estimated_tokens = prompt.length / 4
    
    # Get context limit for this model
    context_limit = get_model_context_limit(model)
    
    # Use 80% of context limit as safe threshold
    safe_limit = (context_limit * 0.8).to_i
    
    if estimated_tokens > safe_limit
      puts "\e[2mWarning: Prompt is large (~#{estimated_tokens} tokens)\e[0m"
      puts "\e[2m  Model '#{model}' context limit: #{context_limit} tokens\e[0m"
      puts "\e[2m  Recommended max: #{safe_limit} tokens (80% of limit)\e[0m"
      puts
      
      if estimated_tokens > context_limit
        puts "\e[91mError: Prompt exceeds model context limit!\e[0m"
        puts "\e[91m  This will likely fail or be truncated.\e[0m"
        puts
        return true
      else
        puts "\e[2m  Proceeding anyway... (may work but watch for truncation)\e[0m"
        puts
      end
    end
    
    false
  end
  
  def get_model_context_limit(model)
    # Try exact match first
    return MODEL_CONTEXT_LIMITS[model] if MODEL_CONTEXT_LIMITS[model]
    
    # Try partial matches for models with tags
    MODEL_CONTEXT_LIMITS.each do |model_pattern, limit|
      return limit if model.start_with?(model_pattern.split(':')[0])
    end
    
    # Unknown model - show warning and use conservative fallback
    puts "\e[2mWarning: Unknown model '#{model}'\e[0m"
    puts "\e[2m  Using conservative context limit: #{MODEL_CONTEXT_LIMITS['default']} tokens\e[0m"
    puts "\e[2m  Model may actually support more or fewer tokens\e[0m"
    puts
    
    MODEL_CONTEXT_LIMITS['default']
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